return {
  adapters = {
    require "configs.neotest_maven",
  },
  consumers = {
    maven = function(client)
      local M = {}

      local function current_path(path)
        return path and path ~= "" and path or vim.api.nvim_buf_get_name(0)
      end

      function M.discover_file(path, callback)
        path = current_path(path)
        require("nio").run(function()
          client:get_adapter(path)
          client:_update_positions(path)

          if callback then
            vim.schedule(callback)
          end
        end)
      end

      function M.run_file(path)
        path = current_path(path)
        M.discover_file(path, function()
          require("neotest").run.run(path)
        end)
      end

      function M.discover_all(path, callback)
        path = path or require("configs.neotest_utils").maven_reactor_root()
        require("nio").run(function()
          local adapter_id, adapter = client:get_adapter(path)
          local tree = adapter and adapter.discover_positions(path)
          if tree then
            client._state:update_positions(adapter_id, tree)
          end

          if callback then
            vim.schedule(function()
              callback(adapter_id, tree)
            end)
          end
        end)
      end

      function M.run_all(path)
        path = path or require("configs.neotest_utils").maven_reactor_root()
        M.discover_all(path, function(adapter_id, tree)
          if not adapter_id then
            require("neotest.lib").notify("No Maven test adapter found")
            return
          end

          if not tree then
            require("neotest.lib").notify("No Maven tests found")
            return
          end

          vim.notify("Running Maven tests in " .. path, vim.log.levels.INFO)
          require("neotest").summary.open()
          require("neotest").run.run({ path, adapter = adapter_id, maven_run_all = true })
        end)
      end

      function M.run_nearest()
        M.discover_file(nil, function()
          require("neotest").run.run()
        end)
      end

      return M
    end,
  },
  watch = {
    enabled = false,
  },
}
