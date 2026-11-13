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
  -- Note: jdtls is configured separately below
  "kotlin_lsp",

  -- Rust
  -- Note: rust_analyzer is managed by rustaceanvim plugin

  -- SQL
  "sqlls",
}

vim.lsp.enable(servers)

-- Setup nvim-java
-- Wrap in pcall to gracefully handle any issues
local java_setup_ok, java_setup_err = pcall(function()
  require("java").setup({
    jdk = {
      auto_install = false,
      path = "/opt/homebrew/opt/openjdk",
    },
    lombok = {
      enable = true,
    },
    java_test = {
      enable = true,
    },
    java_debug_adapter = {
      enable = true,
    },
  })
end)

if not java_setup_ok then
  vim.notify(
    "nvim-java setup encountered an issue: " .. tostring(java_setup_err) .. "\nSkipping jdtls setup",
    vim.log.levels.WARN
  )
else
  -- Setup jdtls using native vim.lsp.config API
  vim.lsp.config("jdtls", {
    root_markers = {
      "settings.gradle",
      "settings.gradle.kts",
      "pom.xml",
      "build.gradle",
      "mvnw",
      "gradlew",
      "build.gradle.kts",
      ".git",
    },
    handlers = {
      ["language/status"] = function() end,
    },
  })
  vim.lsp.enable("jdtls")
end

-- read :h vim.lsp.config for changing options of lsp servers
