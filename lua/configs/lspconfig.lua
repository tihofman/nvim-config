require("nvchad.configs.lspconfig").defaults()

local servers = {
  -- Web
  "html",
  "cssls",
  "angularls",

  -- JavaScript/TypeScript/Node
  "ts_ls",  -- TypeScript/JavaScript
  "vue_ls",  -- Vue/Nuxt
  "svelte",  -- Svelte/SvelteKit

  -- Java/JVM
  -- Note: jdtls is configured separately below (installed via mason)
  "kotlin_lsp",

  -- Rust
  -- Note: rust_analyzer is managed by rustaceanvim plugin

  -- SQL
  "sqlls",
}

vim.lsp.enable(servers)

-- Setup nvim-java (patch is applied in plugin init)
-- Wrap in pcall to gracefully handle any issues
local java_setup_ok, java_setup_err = pcall(function()
  require('java').setup({
    -- Configure root markers for project detection
    root_markers = {
      'settings.gradle',
      'settings.gradle.kts',
      'pom.xml',
      'build.gradle',
      'mvnw',
      'gradlew',
      'build.gradle.kts',
      '.git',
    },
    lombok = {
      enable = true,
    },

    -- Use mason-installed jdtls
    java_test = {
      enable = true,
    },

    java_debug_adapter = {
      enable = true,
    },

    jdk = {
      auto_install = false,
    },

    notifications = {
      dap = true,
    },
  })
end)

if not java_setup_ok then
  vim.notify(
    "nvim-java setup encountered an issue: " .. tostring(java_setup_err) .. "\nSkipping jdtls setup",
    vim.log.levels.WARN
  )
else
  -- nvim-java registers the base jdtls config via vim.lsp.config().
  -- Extend that config with local overrides, then enable the server.
  vim.lsp.config("jdtls", {
    on_attach = require("nvchad.configs.lspconfig").on_attach,
    capabilities = require("nvchad.configs.lspconfig").capabilities,

    -- Use JDK 21 to run jdtls (jdtls doesn't support JDK 25 yet)
    -- cmd_env = {
    --   JAVA_HOME = "/opt/homebrew/opt/openjdk@21",
    -- },

    -- Modify the jdtls command for JDK compatibility
    on_new_config = function(new_config, new_root_dir)
      -- Insert --enable-native-access flag after 'java' command
      -- to suppress native access warnings
      table.insert(new_config.cmd, 2, '--enable-native-access=ALL-UNNAMED')

      -- Ensure JDK 21 is used to run jdtls
      -- new_config.cmd_env = new_config.cmd_env or {}
      -- new_config.cmd_env.JAVA_HOME = "/opt/homebrew/opt/openjdk@21"
      -- new_config.cmd_env.PATH = "/opt/homebrew/opt/openjdk@21/bin:" .. (vim.env.PATH or "")
    end,

    -- Handlers to suppress verbose status messages
    handlers = {
      ['language/status'] = function() end,
    },
  })

  vim.lsp.enable("jdtls")
end

-- read :h vim.lsp.config for changing options of lsp servers
