local options = {
  formatters_by_ft = {
    lua = { "stylua" },

    -- Web (HTML/CSS/JS/TS)
    css = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },

    -- Vue/Nuxt
    vue = { "prettier" },

    -- Svelte/SvelteKit
    svelte = { "prettier" },

    -- Rust
    rust = { "rustfmt" },

    -- SQL
    sql = { "sql_formatter" },

    -- Config/Data
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
