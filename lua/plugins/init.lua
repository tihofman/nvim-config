return {
  {
    "stevearc/conform.nvim",
     event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },
  {
    'nvim-java/nvim-java',
    lazy = false,  -- Load on startup (patch is applied in init.lua)
    dependencies = {
      'MunifTanjim/nui.nvim',
      'neovim/nvim-lspconfig',
      'mfussenegger/nvim-dap',
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("neotest").setup(require "configs.neotest")
    end,
  },
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    lazy = false,
    ft = { 'rust' },
    config = function()
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(client, bufnr)
            -- Use NvChad's default on_attach if available
            local nvchad_on_attach = require("nvchad.configs.lspconfig").on_attach
            if nvchad_on_attach then
              nvchad_on_attach(client, bufnr)
            end
          end,
        },
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  { import = "nvchad.blink.lazyspec" },
  {
    "aznhe21/actions-preview.nvim",
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_horizontal",
        },
      },
      file_panel = {
        listing_style = "tree",
      },
    },
  },
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    opts = {
      integrations = {
        diffview = true,
      },
      disable_commit_confirmation = true,
    },
  },
  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = {
  		ensure_installed = {
  			"vim", "lua", "vimdoc",
       "html", "css",
       -- JavaScript/TypeScript/Node/React
       "javascript", "typescript", "tsx", "jsdoc",
       -- Vue/Nuxt
       "vue",
       -- Svelte/SvelteKit
       "svelte",
       -- Java/JVM
       "java", "kotlin",
       -- Rust
       "rust", "toml",
       -- SQL
       "sql",
       -- Config/Data formats
       "json", "yaml", "markdown",
  		},
  	},
  },
}
