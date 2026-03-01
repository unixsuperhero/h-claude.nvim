if vim.g.loaded_h_claude then return end
vim.g.loaded_h_claude = true

vim.api.nvim_create_user_command("ClaudeReplace", function()
  require("h-claude").ask("replace")
end, { range = true, desc = "Claude: replace selection with response" })

vim.api.nvim_create_user_command("ClaudeAppend", function()
  require("h-claude").ask("append")
end, { range = true, desc = "Claude: append response after quoted selection" })

vim.api.nvim_create_user_command("ClaudeOpen", function()
  require("h-claude").open()
end, { desc = "Claude: open sidebar" })
