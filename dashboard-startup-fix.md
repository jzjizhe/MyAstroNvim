# Neovim Dashboard Startup Fix

## Goal

When opening Neovim on a directory, keep `neo-tree` on the left and show the `Snacks` dashboard on the right instead of an empty buffer.

## Problem

The startup layout looked like this:

- left pane: `neo-tree`
- right pane: empty unnamed buffer (`Untitled`)

The expected layout was:

- left pane: `neo-tree`
- right pane: AstroNvim / Snacks start page

## Files Involved

- `lua/plugins/user.lua`
- AstroNvim built-in references checked during debugging:
  - `lua/astronvim/plugins/neo-tree.lua`
  - `lua/astronvim/plugins/snacks.lua`

## Investigation Process

### 1. Locate the relevant plugins

The Neovim config already had:

- `nvim-neo-tree/neo-tree.nvim`
- `folke/snacks.nvim`

The dashboard itself was already configured correctly in `lua/plugins/user.lua`.

So the issue was not the dashboard theme or content. The issue was **startup behavior**.

### 2. Confirm AstroNvim startup flow

AstroNvim opens `neo-tree` on startup when Neovim is launched with a directory. That behavior comes from AstroNvim's built-in `neo-tree` startup autocmd.

This means the right side is not automatically turned into a dashboard window. It remains a normal empty buffer unless we explicitly replace it.

### 3. First attempt

The first implementation added a startup autocmd and called:

```lua
Snacks.dashboard.open()
```

That was not correct for this layout.

Why it failed:

- `Snacks.dashboard.open()` can create its own dashboard window
- the existing empty right-hand pane was not necessarily reused
- this could leave the empty buffer in place or create an extra window instead of replacing the target pane

### 4. Inspect Snacks implementation

After checking the local `snacks.nvim` source, the important detail was:

```lua
require("snacks.dashboard").open({ buf = empty_buf, win = empty_win })
```

`snacks.dashboard.open()` supports passing an existing buffer and window.

That is the key to making the dashboard appear exactly in the right pane.

## Final Solution

A new AstroCore autocmd was added in `lua/plugins/user.lua`.

Behavior of the final logic:

1. Wait during startup on `VimEnter` / `BufEnter`
2. Scan normal windows in the current tab
3. Detect whether `neo-tree` is already open
4. Find an empty unnamed buffer window
5. If both are present, open the dashboard **inside that existing buffer/window**
6. Guard with `vim.g.opened_dashboard_on_startup` so it only runs once

## Final Code

Location: `lua/plugins/user.lua:118`

```lua
open_dashboard_on_startup = {
  {
    event = { "VimEnter", "BufEnter" },
    desc = "Show dashboard in empty window beside neo-tree during startup",
    nested = true,
    callback = function()
      if vim.g.opened_dashboard_on_startup then return end

      local has_neotree = false
      local empty_win, empty_buf

      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
          local buf = vim.api.nvim_win_get_buf(win)
          local filetype = vim.bo[buf].filetype

          if filetype == "snacks_dashboard" then
            vim.g.opened_dashboard_on_startup = true
            return
          elseif filetype == "neo-tree" then
            has_neotree = true
          elseif vim.bo[buf].buftype == ""
            and vim.api.nvim_buf_get_name(buf) == ""
            and not vim.bo[buf].modified
            and vim.api.nvim_buf_line_count(buf) == 1
            and (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == "" then
            empty_win, empty_buf = win, buf
          end
        end
      end

      if not has_neotree or not empty_win then return end

      vim.g.opened_dashboard_on_startup = true
      require("snacks.dashboard").open({ buf = empty_buf, win = empty_win })
    end,
  },
},
```

## Verification

Verified on branch:

- `fix/dashboard-startup`

Confirmed working behavior:

- when launching Neovim with a directory argument, the left pane is `neo-tree`
- the right pane becomes `snacks_dashboard`
- the empty buffer is replaced instead of an extra dashboard window being created

## Summary

The successful fix was not “open the dashboard on startup” in a generic way.

The real fix was:

> detect AstroNvim's startup split, find the empty right-hand pane, and render the Snacks dashboard into that exact window.
