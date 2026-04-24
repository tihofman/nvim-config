local neotest_utils = require "configs.neotest_utils"

local M = { name = "neotest-maven" }

local test_annotations = {
  ParameterizedTest = true,
  RepeatedTest = true,
  Test = true,
  TestFactory = true,
  TestTemplate = true,
}

local function parent_dir(path)
  return vim.fs.dirname(path)
end

local function is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function start_dir_for(path)
  return is_dir(path) and path or parent_dir(path)
end

local function shell_join(args)
  return table.concat(vim.tbl_map(vim.fn.shellescape, args), " ")
end

local function read_file(path)
  local file = assert(io.open(path, "r"))
  local content = file:read "*a"
  file:close()
  return content
end

local function test_files_under(root)
  local files = vim.fn.globpath(root, "**/*.kt", false, true)
  return vim.tbl_filter(M.is_test_file, files)
end

local function relpath(path, root)
  if path == root then
    return "."
  end

  return path:sub(#root + 2)
end

local function nearest_pom_dir(path)
  local current = start_dir_for(path)

  while current and current ~= "" do
    if vim.uv.fs_stat(current .. "/pom.xml") then
      return current
    end

    local parent = parent_dir(current)
    if not parent or parent == current then
      break
    end

    current = parent
  end
end

local function report_files_for_context(context)
  if context.run_all then
    local files = vim.fn.globpath(context.reactor_root, "target/surefire-reports/TEST-*.xml", false, true)
    vim.list_extend(files, vim.fn.globpath(context.reactor_root, "*/target/surefire-reports/TEST-*.xml", false, true))
    return files
  end

  return vim.fn.globpath(context.module_dir .. "/target/surefire-reports", "TEST-*.xml", false, true)
end

local function package_name(lines)
  for _, line in ipairs(lines) do
    local package = line:match("^%s*package%s+([%w_.]+)")
    if package then
      return package
    end
  end
end

local function class_name_from_line(line)
  return line:match("^%s*[%w%s]*class%s+([%w_]+)")
    or line:match("^%s*[%w%s]*object%s+([%w_]+)")
end

local function test_annotation(line)
  local annotation = line:match("@([%w_.]+)")
  if not annotation then
    return false
  end

  local short_name = annotation:match("([%w_]+)$")
  return test_annotations[short_name] or false
end

local function test_name_from_line(line)
  return line:match("fun%s+`([^`]+)`%s*%(") or line:match("fun%s+([%w_]+)%s*%(")
end

local function discover_kotlin_positions(file_path)
  local content = read_file(file_path)
  local lines = vim.split(content, "\n", { plain = true })
  local package = package_name(lines)
  local file_name = vim.fn.fnamemodify(file_path, ":t")
  local file_pos = {
    id = file_path,
    name = file_name,
    path = file_path,
    range = { 0, 0, #lines, 0 },
    type = "file",
  }
  local tree = { file_pos }
  local classes = {}
  local current_class
  local pending_test_line

  for line_number, line in ipairs(lines) do
    local class_name = class_name_from_line(line)
    if class_name then
      local fqcn = package and (package .. "." .. class_name) or class_name
      current_class = {
        id = fqcn,
        name = class_name,
        path = file_path,
        range = { line_number - 1, 0, line_number - 1, #line },
        type = "namespace",
        class_name = class_name,
        fqcn = fqcn,
      }
      classes[#classes + 1] = { current_class }
      file_pos.class_name = file_pos.class_name or class_name
      file_pos.fqcn = file_pos.fqcn or fqcn
    end

    if test_annotation(line) then
      pending_test_line = line_number
    end

    local test_name = test_name_from_line(line)
    if test_name and pending_test_line and current_class and line_number - pending_test_line <= 5 then
      classes[#classes][#classes[#classes] + 1] = {
        id = current_class.fqcn .. "#" .. test_name,
        name = test_name,
        path = file_path,
        range = { line_number - 1, 0, line_number - 1, #line },
        type = "test",
        class_name = current_class.class_name,
        fqcn = current_class.fqcn,
      }
      pending_test_line = nil
    end
  end

  for _, class_tree in ipairs(classes) do
    tree[#tree + 1] = class_tree
  end

  return require("neotest.types").Tree.from_list(tree, function(pos)
    return pos.id
  end)
end

function M.root(dir)
  return neotest_utils.maven_reactor_root_for(dir)
end

function M.filter_dir(name)
  return not vim.tbl_contains({ ".git", "target", "build", ".idea", ".mvn" }, name)
end

function M.is_test_file(file_path)
  return file_path:match("%.kt$") ~= nil
    and file_path:find("/src/test/kotlin/", 1, true) ~= nil
    and file_path:match("Test[s]?%.kt$") ~= nil
end

function M.discover_positions(file_path)
  local lib = require "neotest.lib"
  if is_dir(file_path) then
    local files = test_files_under(file_path)
    local tree = lib.files.parse_dir_from_files(file_path, files)

    for _, file in ipairs(files) do
      tree = lib.positions.merge(tree, discover_kotlin_positions(file))
    end

    return tree
  end

  if not M.is_test_file(file_path) then
    return nil
  end

  local root = M.root(file_path)
  local root_tree = lib.files.parse_dir_from_files(root, { file_path })

  return lib.positions.merge(root_tree, discover_kotlin_positions(file_path))
end

local function selector(position)
  if position.type == "test" then
    return position.class_name .. "#" .. position.name
  end

  if position.type == "namespace" or position.type == "file" then
    return position.class_name
  end
end

function M.build_spec(args)
  assert(args.strategy ~= "dap", "neotest-maven does not support DAP debugging")

  local position = args.tree:data()
  local root = args.tree:root():data().path
  local reactor_root = neotest_utils.maven_reactor_root_for(root)
  local module_dir = args.maven_run_all and reactor_root or nearest_pom_dir(position.path) or reactor_root

  local command = {
    "mvn",
    "test",
    "-DfailIfNoTests=false",
    "-Dsurefire.failIfNoSpecifiedTests=false",
  }

  if module_dir ~= reactor_root then
    vim.list_extend(command, { "-pl", relpath(module_dir, reactor_root), "-am" })
  end

  local test_selector = not args.maven_run_all and selector(position) or nil
  if test_selector then
    command[#command + 1] = "-Dtest=" .. test_selector
  end

  return {
    command = shell_join(command),
    cwd = reactor_root,
    context = {
      module_dir = module_dir,
      reactor_root = reactor_root,
      run_all = not test_selector and module_dir == reactor_root,
    },
  }
end

local function as_list(value)
  if not value then
    return {}
  end

  if vim.isarray(value) then
    return value
  end

  return { value }
end

local function write_temp_output(lines)
  local path = vim.fn.tempname()
  local file = assert(io.open(path, "w"))
  file:write(table.concat(lines, "\n"))
  file:close()
  return path
end

local function failure_data(testcase)
  local failures = as_list(testcase.failure or testcase.error)
  local failure = failures[1]
  if not failure then
    return nil
  end

  local attrs = type(failure) == "table" and failure._attr or {}
  local body = type(failure) == "table" and failure[1] or tostring(failure)
  return {
    message = attrs.message or attrs.type or "Test failed",
    body = body,
  }
end

local function result_from_testcase(testcase, output)
  if testcase.skipped then
    return { status = "skipped", output = output }
  end

  local failure = failure_data(testcase)
  if failure then
    return {
      status = "failed",
      short = failure.message,
      errors = { { message = failure.message } },
      output = write_temp_output({ failure.message, "", failure.body or "" }),
    }
  end

  return { status = "passed", output = output }
end

function M.results(spec, result, tree)
  local xml = require "neotest.lib.xml"
  local results = {}
  local known_ids = {}
  local report_files = report_files_for_context(spec.context)

  for _, position in tree:iter() do
    known_ids[position.id] = true
  end

  for _, report_file in ipairs(report_files) do
    local ok, parsed = pcall(xml.parse, read_file(report_file))
    local suite = ok and parsed and parsed.testsuite or nil
    local testcases = suite and as_list(suite.testcase) or {}

    for _, testcase in ipairs(testcases) do
      local attrs = testcase._attr or {}
      local id = attrs.classname and attrs.name and (attrs.classname .. "#" .. attrs.name)
      if id and known_ids[id] then
        results[id] = result_from_testcase(testcase, result.output)
      end
    end
  end

  if vim.tbl_isempty(results) then
    local root = tree:data()
    results[root.id] = {
      status = result.code == 0 and "passed" or "failed",
      output = result.output,
    }
  end

  return results
end

return M
