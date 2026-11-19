# Iteration 001 — Neovim Config Full Audit, Lightweight Speedup, Aesthetic Polish & Bug Fixes

> **Repo**: `/mnt/dolphinfs/ssd_pool/docker/user/hadoop-xt-ai-search/ai-search/jzzhang/HOME/.config/nvim`
> **Base HEAD**: `7ee04b5` (`main`)
> **Revision**: Round 3 (incorporating all accepted BLOCKER findings from Plan Review Rounds 1 & 2)

---

## 1. Objective & Acceptance Criteria

对当前 AstroNvim v6 配置做一次全面体检与重构升级，实现 **「更轻、更快、更干净、更像 VS Code Winter is Coming Light、零已知 Bug」**：

1. **轻量化与提速**：
   - 活跃插件规格（`#require("lazy").plugins()`）与清理后磁盘插件目录（执行 `:Lazy clean` + `nvim-save`）均从 **47** 精简至 **≤ 35**（禁用并清理 12 个零使用/冗余插件）。
   - 打开 `README.md` 时：加载插件数从 **27** 降至 **≤ 21**，插件累计加载耗时从 **292.60ms** 降至 **≤ 240ms**，且 `none-ls.nvim`、`mason-null-ls.nvim`、`blink.compat`、`todo-comments.nvim`、`nvim-ts-autotag`、`nvim-highlight-colors` 均不加载。
   - 打开 `init.lua` 时：加载插件数从 **26** 降至 **≤ 22**，插件累计加载耗时从 **288.38ms** 降至 **≤ 240ms**，`none-ls.nvim`、`mason-null-ls.nvim`、`todo-comments.nvim`、`nvim-ts-autotag` 均不加载（`nvim-highlight-colors` 因 `.lua` 在颜色白名单内按设计加载，便于编辑配色文件）。
   - 消除 `strip_italics()` 在 `User LazyLoad` 突发期重复 20+ 次全表扫描 highlight groups 的性能浪费，同时保持严格零斜体（包括直接 `:colorscheme` 切换且 Neo-tree 已加载的场景）。
   - 清理 7 个死模板文件（首行 `if true then return {} end` / `return end`）及过时文档 `dashboard-startup-fix.md`。
2. **视觉美化与 VS Code Winter is Coming Light 深度还原**：
   - 补齐所有当前为 `nil` 的核心插件高亮组（`SnacksPicker*`、`SnacksDashboard*`、`BlinkCmp*`、`WhichKey*`、`AerialNormal/Guide`、`NeoTreeGit*/Indent/Root/Dir`），并更新 `blink.cmp` 浮窗 `winhighlight` 使其真正使用 `BlinkCmp*` 高亮组。
   - 补齐 VS Code Winter is Coming Light 原版 Treesitter & LSP Semantic Token 映射（`@keyword.*`、`@function.call`、`@string.documentation`、`@attribute`、`@lsp.type.*`）；修复 `LspInlayHint` 对比度使其在 3 套变体的 `Normal` 和 `CursorLine` 上均满足 WCAG ≥ 4.5:1。
   - 界面去噪：全局 `foldcolumn = "0"`、关闭与 Tabline 重复的 `winbar`（在现有 `heirline.nvim` 的 `opts = function(_, opts)` 中置 `opts.winbar = nil`）、统一浮动窗口圆角边框（`rounded`）、优化 `scrolloff`/`updatetime`/`timeoutlen`。
   - 消除 AstroNvim 状态栏/标签栏隐藏斜体：在 `astroui` `opts` 中显式设置 `status = { attributes = { buffer_active = { bold = true, italic = false } } }`。
3. **Bug 全部修复**：修复已定位的 7 个真实代码/配置缺陷，保持现有 Markdown 居中布局、Aerial 自动大纲、表格横线分隔、Rex OSC 52 剪贴板与 `/tmp` 持久化完全无回归。

---

## 2. Empirical Baseline Audit (Measured on HEAD `7ee04b5`)

### 2.1 Startup & File-Open Profiling
- **Total installed plugins**: `47` (7 loaded on bare startup, `26` on `init.lua`, `27` on `README.md`).
- **Top wasted plugin load time on every file open (`README.md` = `292.60ms` sum, `init.lua` = `288.38ms` sum)**:
  - `none-ls.nvim` (**21.25ms**) + `mason-null-ls.nvim` (**20.93ms**) = **~42.2ms wasted on EVERY file open**, while `lua/plugins/none-ls.lua` is disabled and `~/.local/share/nvim*/mason/packages` is **completely empty**.
  - `nvim-ts-autotag` (**5.06ms** on `.md` / **4.50ms** on `.lua`) — HTML/JSX tag auto-closer loading on non-web files.
  - `todo-comments.nvim` (**4.71ms** on every file).
  - `nvim-highlight-colors` (**4.39ms** on every file — scans buffers for color literals).
  - `blink.compat` (**2.42ms** on `.md`) — only pulled in by AstroNvim's `cmp-dap` bridge.
  - 6 DAP plugins installed (`nvim-dap`, `nvim-dap-ui`, `nvim-nio`, `cmp-dap`, `mason-nvim-dap.nvim`, `blink.compat`) with zero debuggers installed on this CPU-only container.
  - `toggleterm.nvim` & `smart-splits.nvim` installed despite using Rex native panes (`<C-H/J/K/L>` falls back to AstroNvim core `_astrocore_mappings.lua:124-131`).
  - `astrotheme` installed as unused AstroNvim default colorscheme.

### 2.2 Unstyled UI Highlight Groups Audit
Measured under active `winter-is-coming-light`:
- `SnacksPicker*` / `SnacksDashboard*`: **all `nil`**
- `BlinkCmpMenu*` / `BlinkCmpDoc*` / `BlinkCmpSignatureHelp*`: **all `nil`** (and AstroNvim's `blink.lua:127,145,157` remaps `winhighlight` to `NormalFloat`/`FloatBorder`/`PmenuSel`)
- `WhichKeyNormal` / `WhichKeyBorder` / `WhichKeyGroup` / `WhichKeyDesc`: **all `nil`**
- `AerialNormal` / `AerialGuide`: **all `nil`**
- `LspInlayHint`: `fg=#B8D4EC` on `#FFFFFF` (nearly invisible, contrast < 1.5:1)
- `DiagnosticVirtualText*`: no subtle tinted pill background

### 2.3 Confirmed Bugs
1. **Duplicate autocmd accumulation (`lua/plugins/render-markdown.lua:760-763`)**: `FileType markdown` registers buffer-local `BufEnter`/`TextChanged`/`InsertLeave` autocmds without clearing prior entries for that buffer.
2. **`strip_italics()` storm & incomplete theme restore (`lua/plugins/themes.lua:49-64, 198-226`)**:
   - `User LazyLoad` fires synchronously 20+ times during file open, scanning all ~800 highlight groups each time.
   - Synchronous `ColorScheme` scan runs before Neo-tree's `ColorScheme` callback recreates italic `NeoTreeMessage`/`NeoTreeGitConflict` on direct `:colorscheme`.
   - `VimEnter` callback is non-nested (suppressing `ColorScheme` hooks that refresh AstroUI/Heirline/Markdown), ignores `vim.g.vscode`, and misses `vim.g.colors_name ~= s.scheme` (with `flexoki-light`/`flexoki-dark` both reporting `vim.g.colors_name == "flexoki"`).
3. **AstroUI italic tabline (`_astroui_status.lua:104`)**: `buffer_active = { bold = true, italic = true }` causes Heirline to materialize italic `Stl*` highlight groups dynamically at render time.
4. **Permanent & over-eager `open_dashboard_on_startup` (`lua/plugins/user.lua:132-169`)**: Never unregisters itself after firing, AND stays active after named-file launches (`nvim README.md` → open Neo-tree → `:enew` replaces the new buffer with the dashboard).
5. **Heirline `tabline[1]` window assumption (`lua/plugins/user.lua:80-120`)**: Uses `nvim_tabpage_list_wins(0)[1]` without filtering floating windows (`relative == ""`).
6. **Multi-tab `<Leader>mw` outline leak (`lua/plugins/render-markdown.lua:609-623`)**: Toggling Markdown layout off clears `ts.auto_aerial = false` on inactive tabs without closing their auto-opened Aerial outlines.
7. **Undocumented keymap override (`init.lua:91`)**: `vim.keymap.set("n", "<leader>q", "<C-v>")` lacks `desc`.

---

## 3. Concrete Design Specs

### 3.1 Plugin Pruning & Filetype Scoping (`lua/plugins/user.lua`)
Disable 12 redundant AstroNvim v6 bundled plugins (`enabled = false`), then run `:Lazy clean` (+ `nvim-save`) to remove unused directories from disk:
- DAP stack (6): `mfussenegger/nvim-dap`, `rcarriga/nvim-dap-ui`, `nvim-neotest/nvim-nio`, `rcarriga/cmp-dap`, `jay-babu/mason-nvim-dap.nvim`, `saghen/blink.compat`
- Legacy null-ls stack (2): `nvimtools/none-ls.nvim`, `jay-babu/mason-null-ls.nvim`
- Redundant terminal/mux/theme/todo (4): `akinsho/toggleterm.nvim`, `mrjones2014/smart-splits.nvim`, `AstroNvim/astrotheme`, `folke/todo-comments.nvim`

Scope web/color plugins strictly by filetype using `event = function() return {} end` (replacing AstroNvim's inherited `User AstroFile` / `InsertEnter` list in `lazy.nvim`):
- `windwp/nvim-ts-autotag`:
  - `event = function() return {} end`
  - `ft = { "html", "xml", "javascriptreact", "typescriptreact", "vue", "svelte" }`
- `brenoprata10/nvim-highlight-colors`:
  - `event = function() return {} end`
  - `module = false` *(prevents `lazy.nvim` from autoloading the plugin when AstroNvim's `blink.lua:50` calls `pcall(require, "nvim-highlight-colors")` on non-allowlisted buffers, while preserving AstroNvim's full `mini.icons` kind-icon logic)*
  - `ft = { "css", "scss", "html", "lua", "json" }`
  - `opts.exclude_buffer`: compose the filetype allowlist with AstroNvim's large-buffer & valid-buffer guard:
    ```lua
    exclude_buffer = function(bufnr)
      local buf_utils = require("astrocore.buffer")
      return not color_fts[vim.bo[bufnr].filetype]
        or buf_utils.is_large(bufnr)
        or not buf_utils.is_valid(bufnr)
    end
    ```
- Keep `stevearc/resession.nvim`, `catppuccin`, `flexoki`, `github-theme` as `lazy = true` (zero startup cost).

### 3.2 Dead File Cleanup & Provider Disabling
- Delete 7 unused AstroNvim starter template files (`if true then return {} end` / `return end`):
  - `lua/community.lua` (remove `{ import = "community" }` from `lua/lazy_setup.lua`)
  - `lua/polish.lua` (remove `require "polish"` from `init.lua`)
  - `lua/plugins/astrocore.lua`, `lua/plugins/astrolsp.lua`, `lua/plugins/astroui.lua`, `lua/plugins/mason.lua`, `lua/plugins/none-ls.lua`
  - `dashboard-startup-fix.md`
- In `astrocore` `options.g`: `loaded_ruby_provider = 0`, `loaded_perl_provider = 0`, `loaded_node_provider = 0`.
- In `lua/lazy_setup.lua`: `install = { colorscheme = { "winter-is-coming-light", "habamax" } }`, add `"rplugin"`, `"tutor"` to `disabled_plugins`.

### 3.3 Visual Polish & Authentic VS Code Winter is Coming Light (`lua/winter_is_coming.lua`, `lua/plugins/user.lua`, `lua/plugins/themes.lua`)
1. **Complete `lua/winter_is_coming.lua` highlight coverage (all 3 variants: `light`, `dark_blue`, `dark_black`)**:
   - **Treesitter & LSP Semantic Tokens**:
     - `@keyword.function`, `@keyword.import`, `@keyword.conditional`, `@keyword.repeat`, `@keyword.exception`, `@keyword.storage` → `p.keyword` / `p.storage`
     - `@function.call`, `@function.method.call` → `p.func`
     - `@string.documentation`, `@comment.documentation` → `p.comment`
     - `@attribute`, `@attribute.builtin` → `p.storage`
     - `@lsp.type.{namespace,class,struct,interface,type,parameter,property,variable,function,method,decorator,enumMember}`
   - **Modern Plugin UI**:
     - `SnacksPickerNormal`, `SnacksPickerBorder`, `SnacksPickerTitle`, `SnacksPickerPrompt`, `SnacksPickerMatch`, `SnacksPickerListCursorLine`, `SnacksPickerDir`, `SnacksPickerFile`
     - `SnacksDashboardHeader` (`p.md_h1`), `SnacksDashboardIcon` (`p.md_h2`), `SnacksDashboardKey` (`p.func`), `SnacksDashboardDesc` (`p.fg`), `SnacksDashboardFooter` (`p.fg_muted`)
     - `BlinkCmpMenu`, `BlinkCmpMenuBorder`, `BlinkCmpMenuSelection`, `BlinkCmpLabel`, `BlinkCmpLabelMatch`, `BlinkCmpLabelDeprecated`, `BlinkCmpDoc`, `BlinkCmpDocBorder`, `BlinkCmpSignatureHelp`, `BlinkCmpSignatureHelpBorder`, `BlinkCmpKind*`
     - `WhichKeyNormal`, `WhichKeyBorder`, `WhichKeyTitle`, `WhichKeyGroup`, `WhichKeyDesc`, `WhichKeySeparator`, `WhichKeyValue`
     - `AerialNormal`, `AerialGuide`, `AerialLine`
     - `NeoTreeRootName`, `NeoTreeDirectoryName`, `NeoTreeDirectoryIcon`, `NeoTreeIndentMarker`, `NeoTreeFileNameOpened`, `NeoTreeGitModified`, `NeoTreeGitUntracked`, `NeoTreeGitAdded`, `NeoTreeGitDeleted`, `NeoTreeGitIgnored`, `NeoTreeTitleBar`
   - **Diagnostics & Inlay Hints (WCAG ≥ 4.5:1 on both `Normal` and `CursorLine`)**:
     - `LspInlayHint`: `light` `#5A6B7C` (5.5:1 / 5.0:1), `dark_blue` `#7E97AC` (6.2:1 / 5.4:1), `dark_black` `#99A3AD` (5.7:1 / 5.0:1).
     - Subtle tinted backgrounds for `DiagnosticVirtualTextError/Warn/Info/Hint`.
2. **Minimalist UI Chrome & Blink Winhighlight Wiring (`lua/plugins/user.lua`, `lua/plugins/themes.lua`)**:
   - `astrocore` `options.opt`: `foldcolumn = "0"`, `scrolloff = 5`, `sidescrolloff = 8`, `updatetime = 200`, `timeoutlen = 300`, `pumheight = 12`.
   - `astroui` `opts`: set `status = { attributes = { buffer_active = { bold = true, italic = false } } }` so Heirline never materializes italic tabline groups.
   - `heirline.nvim`: inside the existing `opts = function(_, opts)` in `lua/plugins/user.lua`, set `opts.winbar = nil` (removing the redundant breadcrumb bar).
   - `blink.cmp`: set `rounded` borders AND explicit `winhighlight` so our `BlinkCmp*` groups take effect:
     - `completion.menu.border = "rounded"`, `completion.menu.winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None"`
     - `completion.documentation.window.border = "rounded"`, `completion.documentation.window.winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc,Search:None"`
     - `signature.window.border = "rounded"`, `signature.window.winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder"`
   - `which-key.nvim`: `opts = { win = { border = "rounded" } }`.

### 3.4 Bug Fixes
1. **Markdown autocmd deduplication (`lua/plugins/render-markdown.lua`)**:
   - Create `local spacing_grp = vim.api.nvim_create_augroup("MdAirySpacing", { clear = true })` **once** at setup time.
   - Inside `FileType markdown`, call `vim.api.nvim_clear_autocmds({ group = spacing_grp, buffer = args.buf })` before registering the buffer-local `BufEnter`/`TextChanged`/`InsertLeave` autocmd; skip scanning on `TextChanged`/`InsertLeave` when `not vim.b[args.buf].md_airy_spacing`.
2. **Multi-tab `<Leader>mw` Aerial cleanup (`lua/plugins/render-markdown.lua`)**:
   - When `<Leader>mw` disables `md_layout.enabled`, close Aerial in the current tab (resetting `ts.auto_aerial = false` for `cur_tab`), and **retain** `ts.auto_aerial = true` for inactive tabs.
   - In `sync_markdown_layout()`, when `not md_layout.enabled`, close pads AND if `ts.auto_aerial == true and aerial_win` close that tab's auto-opened Aerial via `close_aerial_programmatic()` and set `ts.auto_aerial = false`.
3. **Debounced unconditional `strip_italics()` + Nested `VimEnter` theme restore (`lua/plugins/themes.lua`)**:
   - Skip `restore_reading_theme` completely when `vim.g.vscode` is truthy.
   - Add `nested = true` to the `VimEnter` theme restore autocmd so `ColorScheme` hooks (AstroUI/Heirline/Markdown) run when applying the saved scheme.
   - Normalize scheme matching: `local function is_saved_active(s)` handles `flexoki-light`/`flexoki-dark` (`vim.g.colors_name == "flexoki"` + `vim.o.background == s.bg`) as well as exact `vim.g.colors_name == s.scheme and vim.o.background == s.bg`.
   - Use `schedule_strip_italics()` (`strip_scheduled` flag + `vim.schedule`) unconditionally on `ColorScheme`, `Syntax`, AND `User LazyLoad` across ALL themes (including `winter-is-coming-*`) so:
     - Burst `LazyLoad` events collapse to 1 scan per event-loop tick;
     - Direct `:colorscheme` switches strip italic groups (e.g. `NeoTreeMessage`/`NeoTreeGitConflict`) AFTER plugin `ColorScheme` callbacks finish executing.
4. **Startup dashboard expiration with directory carve-out (`lua/plugins/user.lua`)**:
   - In `open_dashboard_on_startup`:
     - If `vim.g.opened_dashboard_on_startup` is already true → `return true`.
     - Check CLI args: `local argc = vim.fn.argc()`. If `argc > 1` or (`argc == 1` and `vim.fn.isdirectory(vim.fn.argv(0)) == 0`) → ineligible file-argument launch (`nvim README.md`, etc.) → set `vim.g.opened_dashboard_on_startup = true` and `return true`.
     - Scan non-floating normal windows (`buftype == ""`): if any buffer is modified, non-empty, or has `name ~= ""` with `vim.fn.isdirectory(name) == 0` → ineligible launch → set `vim.g.opened_dashboard_on_startup = true` and `return true`.
     - *(Directory launches like `nvim .` have `argc == 1` with `isdirectory(argv(0)) == 1`, and their pre-hijack buffer name satisfies `isdirectory(name) == 1`, so the handler stays alive until Neo-tree hijacks the directory into a blank window beside Neo-tree and opens `snacks.dashboard`.)*
     - When `snacks_dashboard` is already open or after `snacks.dashboard.open(...)` → set `vim.g.opened_dashboard_on_startup = true` and `return true`.
5. **Heirline `tabline[1]` float-safe helper (`lua/plugins/user.lua`)**:
   - Add `first_normal_win()` iterating `vim.api.nvim_tabpage_list_wins(0)` for the first window with `vim.api.nvim_win_get_config(w).relative == ""`, guarding `not first_win`.
6. **Keymap desc (`init.lua`)**:
   - `vim.keymap.set("n", "<leader>q", "<C-v>", { noremap = true, silent = true, desc = "Visual Block Mode" })`.

---

## 4. Files to Touch & Non-Goals

### Files to Touch
- `init.lua`
- `lua/lazy_setup.lua`
- `lua/winter_is_coming.lua`
- `lua/plugins/themes.lua`
- `lua/plugins/user.lua`
- `lua/plugins/render-markdown.lua`
- **Delete**: `lua/community.lua`, `lua/polish.lua`, `lua/plugins/astrocore.lua`, `lua/plugins/astrolsp.lua`, `lua/plugins/astroui.lua`, `lua/plugins/mason.lua`, `lua/plugins/none-ls.lua`, `dashboard-startup-fix.md`

### Non-Goals
- Do NOT break or redesign the verified Markdown centered layout, Aerial TOC auto-open/manual-close state machine, table row horizontal dividers, or blockquote wrapping.
- Do NOT touch `~/.local/bin/nvim` or Rex OSC 52 clipboard logic.
- Do NOT `git push` unless explicitly requested.

---

## 5. Verification Plan (Bounded Headless & UI-Safe Neovim Suite)

1. **Startup, Cleanup & Plugin Load Benchmark**:
   - Run `:Lazy clean` (+ `nvim-save`) and assert both `#require("lazy").plugins() <= 35` AND on-disk plugin directory count under `stdpath("data") .. "/lazy"` `<= 35`.
   - Assert `loaded <= 21` and cumulative load `<= 240ms` on `README.md`, with `nvim-ts-autotag` and `nvim-highlight-colors` both unloaded (`_.loaded == nil`).
   - Assert `loaded <= 22` and cumulative load `<= 240ms` on `init.lua`, with `nvim-ts-autotag` unloaded and `nvim-highlight-colors` loaded by design.
   - Assert `vim.deep_equal(require("lazy.core.plugin").values(plugins[name], "event", true), {})` for both `nvim-ts-autotag` and `nvim-highlight-colors`.
   - Assert Blink resolved providers contain no `dap` entry and triggering Blink completion on `README.md` does not autoload `nvim-highlight-colors` (`module = false`).
   - Assert `nvim-highlight-colors` `exclude_buffer` rejects both non-allowlisted filetypes and large/invalid buffers.
2. **Highlight, Contrast & Zero-Italic Verification**:
   - Assert all `SnacksPicker*`, `SnacksDashboard*`, `BlinkCmp*`, `WhichKey*`, `AerialNormal/Guide`, `NeoTreeGit*`, `LspInlayHint` resolve to non-nil colors.
   - Compute WCAG contrast ratio for `LspInlayHint` on `Normal` and `CursorLine` across all 3 variants (`>= 4.5:1`).
   - Verify `astroui` `status.attributes.buffer_active.italic == false` and zero highlight groups have `italic == true` after startup, lazy loads, `<Leader>mt` theme switches, AND direct `:colorscheme winter-is-coming-light` with Neo-tree already loaded.
3. **Bug-Fix Regression Tests**:
   - Trigger `FileType markdown` 3 times on one buffer → assert only 1 autocmd per event in `MdAirySpacing` group for that buffer (and other markdown buffers remain intact).
   - Verify `nvim README.md` + opening Neo-tree + `:enew` leaves an editable buffer and `open_dashboard_on_startup` autocmd is auto-deleted; verify `nvim .` opens dashboard beside Neo-tree and auto-deletes the autocmd.
   - Verify `<Leader>mw` off with 2 Markdown tabs closes Aerial in both tabs when switching to tab 2.
   - Verify Heirline `tabline[1]` with a floating window open over a left sidebar stays aligned and `vim.o.winbar == ""`.
   - Verify `VimEnter` theme restore works for both `winter-is-coming-light` and `flexoki-light` without suppressing `ColorScheme` hooks.
