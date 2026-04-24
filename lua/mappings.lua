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

-- Diffview
map("n", "<leader>go", "<cmd>DiffviewOpen<CR>", { desc = "Git diff view" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Git close diff view" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git file history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<CR>", { desc = "Git repo history" })
map("n", "<leader>gg", "<cmd>Neogit<CR>", { desc = "Neogit status" })

-- Tabs
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "Tab new" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Tab close" })
map("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "Tab next" })
map("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "Tab previous" })
