local M = {}

M.config = {
  prompt_prefix = "> ",
  claude_prefix = "",
}

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  vim.keymap.set("v", "<leader>cr", function() M.ask("replace") end,
    { desc = "Claude: replace selection with response" })
  vim.keymap.set("v", "<leader>ca", function() M.ask("append") end,
    { desc = "Claude: append response after quoted selection" })
end

-- Get the visual selection lines and range
local function get_visual_selection()
  -- Exit visual mode to update '< and '> marks
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  local start_row = vim.fn.line("'<")
  local end_row = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  return lines, start_row, end_row
end

local function prefix_lines(lines, prefix)
  if prefix == "" then
    return lines
  end
  local result = {}
  for _, line in ipairs(lines) do
    table.insert(result, prefix .. line)
  end
  return result
end

function M.ask(mode)
  local lines, start_row, end_row = get_visual_selection()
  local prompt = table.concat(lines, "\n")
  local bufnr = vim.api.nvim_get_current_buf()

  -- Replace selection with waiting message
  local waiting = { "# ...waiting for claude's response..." }
  vim.api.nvim_buf_set_lines(bufnr, start_row - 1, end_row, false, waiting)

  -- Run claude in background
  local stdout_chunks = {}

  local job_id = vim.fn.jobstart({ "claude", "-p" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, chunk in ipairs(data) do
          table.insert(stdout_chunks, chunk)
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        -- Verify buffer is still valid
        if not vim.api.nvim_buf_is_valid(bufnr) then return end

        -- Find the waiting line (it may have shifted)
        local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local wait_row = nil
        for i, line in ipairs(buf_lines) do
          if line == "# ...waiting for claude's response..." then
            wait_row = i
            break
          end
        end

        if not wait_row then return end

        if exit_code ~= 0 then
          vim.api.nvim_buf_set_lines(bufnr, wait_row - 1, wait_row, false,
            { "# claude error (exit " .. exit_code .. ")" })
          return
        end

        -- Clean up trailing empty string from jobstart
        while #stdout_chunks > 0 and stdout_chunks[#stdout_chunks] == "" do
          table.remove(stdout_chunks)
        end

        local response_lines = stdout_chunks
        local cfg = M.config

        -- Apply claude_prefix to response lines
        response_lines = prefix_lines(response_lines, cfg.claude_prefix)

        local result = {}
        if mode == "append" then
          -- Re-insert original selection with prompt_prefix, then response
          local quoted = prefix_lines(lines, cfg.prompt_prefix)
          for _, l in ipairs(quoted) do table.insert(result, l) end
          table.insert(result, "")
          for _, l in ipairs(response_lines) do table.insert(result, l) end
        else
          -- Replace: only the response
          for _, l in ipairs(response_lines) do table.insert(result, l) end
        end

        vim.api.nvim_buf_set_lines(bufnr, wait_row - 1, wait_row, false, result)
      end)
    end,
  })

  if job_id > 0 then
    vim.fn.chansend(job_id, prompt)
    vim.fn.chanclose(job_id, "stdin")
  end
end

return M
