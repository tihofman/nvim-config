vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- PATCH: Override nvim-java's mason integration BEFORE any plugins load
-- This fixes API compatibility issues between nvim-java and mason.nvim

-- Patch 1: java.utils.mason (from nvim-java)
package.preload['java.utils.mason'] = function()
  return {
    is_available = function(package_name, package_version)
      return true
    end,
    is_installed = function(package_name, package_version)
      local mason_ok, mason_reg = pcall(require, 'mason-registry')
      if not mason_ok then return false end
      local has_pkg = mason_reg.has_package(package_name)
      if not has_pkg then return false end
      local pkg = mason_reg.get_package(package_name)
      return pkg:is_installed()
    end,
    is_outdated = function(packages) return false end,
    install_pkgs = function(packages) end,
    refresh_registry = function() end,
  }
end
--
-- Patch 2: java-core.utils.mason (from nvim-java-core)
package.preload['java-core.utils.mason'] = function()
  return {
    get_pkg_path = function(pkg_name)
      local mason_ok, mason_registry = pcall(require, 'mason-registry')
      if not mason_ok then return "" end

      local has_pkg = mason_registry.has_package(pkg_name)
      if not has_pkg then return "" end

      local pkg = mason_registry.get_package(pkg_name)
      if not pkg:is_installed() then return "" end

      -- Use spec.name instead of get_install_path()
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/" .. pkg_name
      return vim.fn.isdirectory(mason_path) == 1 and mason_path or ""
    end,

    is_pkg_installed = function(pkg_name)
      local mason_ok, mason_registry = pcall(require, 'mason-registry')
      if not mason_ok then return false end

      local has_pkg = mason_registry.has_package(pkg_name)
      if not has_pkg then return false end

      local pkg = mason_registry.get_package(pkg_name)
      return pkg:is_installed()
    end,

    get_shared_path = function(pkg_name)
      local path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/share/" .. pkg_name)
      return path ~= "" and path or ""
    end,
  }
end

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)
