# h-claude.nvim

Neovim plugin that pipes visual selections to `claude -p` and inserts the response back into your buffer.

## Requirements

- Neovim 0.9+
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` available in PATH)

## Installation

### lazy.nvim

```lua
{
  "unixsuperhero/h-claude.nvim",
  config = function()
    require("h-claude").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "unixsuperhero/h-claude.nvim",
  config = function()
    require("h-claude").setup()
  end,
}
```

### Local (development)

```lua
-- lazy.nvim
{ dir = "~/proj/h-claude.nvim" }

-- or add to runtimepath manually
vim.opt.rtp:prepend("~/proj/h-claude.nvim")
require("h-claude").setup()
```

## Configuration

```lua
require("h-claude").setup({
  prompt_prefix = "> ",  -- prepended to each line of the original selection in append mode
  claude_prefix = "",    -- prepended to each line of claude's response
  sidebar = {
    width = 50,          -- width of the sidebar window in characters
    side = "right",      -- "left" or "right"
  },
})
```

## Usage

### Mappings

| Mode | Mapping | Description |
|---|---|---|
| Visual | `<leader>cr` | **Replace** — replaces the selection with claude's response |
| Visual | `<leader>ca` | **Append** — re-inserts the selection (quoted with `prompt_prefix`), then claude's response below |
| Normal | `<leader>co` | **Open** — opens the sidebar window |

### User Commands

These also work from visual mode with `:'<,'>`:

- `:ClaudeReplace` — same as `<leader>cr`
- `:ClaudeAppend` — same as `<leader>ca`
- `:ClaudeOpen` — same as `<leader>co`

### How It Works

1. Select text in visual mode
2. Trigger a mapping or command
3. The selection is replaced with `# ...waiting for claude's response...`
4. `claude -p` runs in the background with the selection piped to stdin
5. Once complete, the waiting line is replaced with the result

### Example

Given this selection with `<leader>ca`:

```
explain what a monad is in one sentence
```

The buffer becomes:

```
> explain what a monad is in one sentence

A monad is a design pattern that wraps values in a context and chains
operations on those values while preserving the context.
```

With `<leader>cr`, only the response is inserted (no quoted original).
