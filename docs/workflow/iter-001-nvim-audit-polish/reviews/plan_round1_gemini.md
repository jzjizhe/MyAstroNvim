### Plan Review Findings (`docs/workflow/iter-001-nvim-audit-polish/plan.md`)

1. **[BLOCKER] `event = {}` is a no-op in `lazy.nvim` and will NOT clear AstroNvim v6's `User AstroFile` / `InsertEnter` triggers**
   - **Plan reference**: `docs/workflow/iter-001-nvim-audit-polish/plan.md:67,69,142` ("explicitly set `event = {}` when overriding `ft`").
   - **Evidence**:
     - `lazy.nvim` evaluates `event` as a list via `Plugin.values(plugin, type, true)` (`~/.local/share/nvim-fast/lazy/lazy.nvim/lua/lazy/core/handler/init.lua:106`).
     - In `~/.local/share/nvim-fast/lazy/lazy.nvim/lua/lazy/core/plugin.lua:458-465`:
       ```lua
       elseif type(values) == "function" then
         ret = values(root, ret) or ret
         return type(ret) == "table" and ret or { ret }
       end
       values = type(values) == "table" and values or { values }
       if is_list then
         return Util.extend(ret, values)
       ```
     - Passing `event = {}` extends AstroNvim's inherited `event = "User AstroFile"` (`AstroNvim/lua/astronvim/plugins/ts-autotag.lua:3`) and `event = { "User AstroFile", "InsertEnter" }` (`AstroNvim/lua/astronvim/plugins/highlight-colors.lua:3`) with an empty list, leaving both triggers intact so both plugins still load on every file open.
   - **Required fix**: Use `event = function() return {} end` on both `windwp/nvim-ts-autotag` and `brenoprata10/nvim-highlight-colors` so `lazy.nvim` replaces the inherited `event` list with `{}`.

2. **[BLOCKER] Skipping `strip_italics()` on `User LazyLoad` for `winter-is-coming` themes breaks the zero-italic invariant**
   - **Plan reference**: `docs/workflow/iter-001-nvim-audit-polish/plan.md:111,146` ("skip full scan on `User LazyLoad` unless a non-`winter-is-coming` theme is active or at most once per scheduled tick" vs. "Assert ... zero groups have `italic = true`").
   - **Evidence**: Even when `winter-is-coming-light` is active, lazy-loaded plugins (`snacks.nvim`, `blink.cmp`, `render-markdown.nvim`, `aerial.nvim`, `gitsigns.nvim`, `which-key.nvim`, `neo-tree.nvim`, etc.) register default highlight groups on load (often with `italic = true, default = true`). Any plugin highlight group not explicitly overridden in `lua/winter_is_coming.lua` will retain `italic = true` if `User LazyLoad` skips stripping when a `winter-is-coming` scheme is active.
   - **Required fix**: Remove the theme-conditional skip on `User LazyLoad`; unconditionally debounce `strip_italics()` with a `strip_scheduled` flag (`vim.schedule`) across all themes so burst `User LazyLoad` events collapse to a single scan per event-loop tick while preserving the zero-italic guarantee.

---

### Verified Safe (No Blockers Found)
- **Disabling 12 AstroNvim v6 plugins** (`nvim-dap`, `nvim-dap-ui`, `nvim-nio`, `cmp-dap`, `mason-nvim-dap.nvim`, `blink.compat`, `none-ls.nvim`, `mason-null-ls.nvim`, `toggleterm.nvim`, `smart-splits.nvim`, `astrotheme`, `todo-comments.nvim`): Verified in `lazy.nvim/lua/lazy/core/fragments.lua` + `meta.lua` and AstroNvim v6 plugin specs (`dap.lua`, `blink.lua:84`, `none-ls.lua`, `mason-tool-installer.lua:24`, `toggleterm.lua`, `smart-splits.lua`, `todo-comments.lua`, `_astrotheme.lua`, `_astroui.lua:38`) that disabling cleanly prunes all child `specs`/`dependencies` and mappings without breaking `blink.cmp`, `mason-tool-installer`, or `neo-tree` (and `smart-splits` cleanly falls back to `_astrocore_mappings.lua:124-131`).
- **Heirline `opts.winbar = nil`**: Verified in `heirline.nvim/lua/heirline/init.lua:88-91` and `astroui/lua/astroui/status/heirline.lua` that omitting `config.winbar` cleanly skips winbar setup and autocmds with no Lua errors.
- **Dead file deletions**: Verified all 7 template Lua files start with `if true then return {} end` (or `return end`), and `lua/plugins/vscode.lua` has no references to them.
- **Bug fixes (`MdAirySpacing`, `open_dashboard_on_startup`, `tabline[1]` float filtering, `VimEnter` scheme check)**: All sound (ensure `open_dashboard_on_startup` returns `true` on all 3 exit paths once `vim.g.opened_dashboard_on_startup` is true, and `tabline[1]` guards `not first_win`).

- Validation request: After updating `plan.md` and implementing `event = function() return {} end`, verify in headless Neovim opening `README.md` that neither `nvim-ts-autotag` nor `nvim-highlight-colors` appears in `require("lazy.core.config").plugins` with `_.loaded ~= nil`.

Review coverage: FULL - docs/workflow/iter-001-nvim-audit-polish/plan.md, init.lua, lua/lazy_setup.lua, lua/winter_is_coming.lua, lua/plugins/user.lua, lua/plugins/themes.lua, lua/plugins/render-markdown.lua, lua/plugins/treesitter.lua, lua/plugins/vscode.lua, colors/winter-is-coming-light.lua, dead template files, lazy.nvim (plugin.lua, meta.lua, fragments.lua, handler/init.lua), AstroNvim v6 specs (dap.lua, blink.lua, none-ls.lua, heirline.lua, ts-autotag.lua, highlight-colors.lua, mason-tool-installer.lua, toggleterm.lua, smart-splits.lua, todo-comments.lua, which-key.lua, _astroui.lua, _astrocore_mappings.lua, _astrocore_options.lua), heirline.nvim/lua/heirline/init.lua, astroui/lua/astroui/status/heirline.lua
Review verdict: FINDINGS
