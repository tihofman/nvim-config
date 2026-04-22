require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
vim.keymap.set('n', 'fr', '<cmd>Telescope lsp_references<CR>', { desc = "Find references (telescope)", noremap=true, silent=true })

map("n", "<leader>cp", "<cmd>Copilot panel<cr>", { desc = "Copilot Panel" })
map("i", "<C-l>", function() vim.fn.feedkeys(vim.fn['copilot#Accept'](), '') end, { desc = "Copilot Accept", replace_keycodes = true, nowait=true, silent=true, expr=true, noremap=true })

-- Code actions with actions-preview
map({ "n", "v" }, "<leader>ca", require("actions-preview").code_actions, { desc = "Code action menu", noremap = true, silent = true })


