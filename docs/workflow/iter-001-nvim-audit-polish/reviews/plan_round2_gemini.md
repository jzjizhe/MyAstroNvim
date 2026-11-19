### Plan Review Round 2 Findings (`docs/workflow/iter-001-nvim-audit-polish/plan.md`)

Both Round 1 BLOCKERs (`event = function() return {} end` and unconditional debounced `strip_italics()`) are fully resolved. However, **1 new BLOCKER** was introduced in the Round 2 revision:

1. **[BLOCKER] `vim.fn.argc() > 0` in `open_dashboard_on_startup` breaks `nvim .` (directory startup)**
   - **Plan reference**: `docs/workflow/iter-001-nvim-audit-polish/plan.md:134` ("if `vim.fn.argc() > 0` or any non-floating normal buffer is already named/modified/non-empty ... → set `vim.g.opened_dashboard_on_startup = true` and `return true` immediately") vs. `plan.md:174` ("verify `nvim .` opens dashboard beside Neo-tree and auto-deletes the autocmd") and `dashboard-startup-fix.md:5` ("When opening Neovim on a directory, keep `neo-tree` on the left and show the `Snacks` dashboard on the right").
   - **Evidence**:
     - Launching Neovim on a directory (`nvim .` or `nvim /path/to/dir`) sets `vim.fn.argc() == 1` with `vim.fn.argv(0)` being that directory.
     - Additionally, before `neo-tree` finishes hijacking the directory buffer on `BufEnter`/`VimEnter`, the initial buffer's `nvim_buf_get_name(buf)` is that directory path (non-empty).
     - With the planned `vim.fn.argc() > 0` (or unguarded `name ~= ""`) check, `open_dashboard_on_startup` will immediately expire and delete itself on `nvim .`, regressing the exact directory-launch dashboard feature it exists to provide.
   - **Required fix**: In §3.4 item 4, only expire on startup arguments when launching with a non-directory argument (`argc > 1` or (`argc == 1` and `vim.fn.isdirectory(vim.fn.argv(0)) == 0`)), and only treat a named non-floating normal buffer as disqualifying when `name ~= ""` and `vim.fn.isdirectory(name) == 0`.

Review coverage: FULL - docs/workflow/iter-001-nvim-audit-polish/plan.md, dashboard-startup-fix.md, lua/plugins/user.lua
Review verdict: FINDINGS
