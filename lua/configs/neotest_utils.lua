local M = {}

local function parent_dir(path)
  return vim.fs.dirname(path)
end

local function path_depth(path)
  local _, count = path:gsub("/", "")
  return count
end

local function start_dir_for(path)
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type ~= "directory" then
    return parent_dir(path)
  end

  return path
end

local function is_ignored_pom(path)
  return path:find("/target/", 1, true) ~= nil
    or path:find("/build/", 1, true) ~= nil
    or path:find("/.git/", 1, true) ~= nil
end

local function pom_dirs_upwards(start_dir)
  local dirs = {}
  local current = start_dir

  while current and current ~= "" do
    if vim.uv.fs_stat(current .. "/pom.xml") then
      dirs[#dirs + 1] = current
    end

    local parent = parent_dir(current)
    if not parent or parent == current then
      break
    end

    current = parent
  end

  return dirs
end

local function shallowest_pom_dir_under(root)
  local pattern = root .. "/**/pom.xml"
  local poms = vim.fn.glob(pattern, false, true)
  local dirs = {}

  for _, pom in ipairs(poms) do
    if not is_ignored_pom(pom) then
      dirs[#dirs + 1] = parent_dir(pom)
    end
  end

  table.sort(dirs, function(a, b)
    local depth_a = path_depth(a)
    local depth_b = path_depth(b)
    if depth_a == depth_b then
      return a < b
    end
    return depth_a < depth_b
  end)

  return dirs[1]
end

function M.maven_reactor_root_for(path)
  if path and path ~= "" then
    local start_dir = start_dir_for(path)
    local dirs = pom_dirs_upwards(start_dir)

    if #dirs > 0 then
      return dirs[#dirs]
    end

    local nested_root = shallowest_pom_dir_under(start_dir)
    if nested_root then
      return nested_root
    end
  end

  local cwd = vim.fn.getcwd()
  if vim.uv.fs_stat(cwd .. "/pom.xml") then
    return cwd
  end

  return shallowest_pom_dir_under(cwd) or cwd
end

function M.maven_reactor_root()
  return M.maven_reactor_root_for(vim.api.nvim_buf_get_name(0))
end

return M
