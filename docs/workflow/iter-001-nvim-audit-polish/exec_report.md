# Execution Report — `iter-001-nvim-audit-polish` (Round 1)

> **Plan Baseline SHA**: `47c9603`
> **Target Repo**: `/mnt/dolphinfs/ssd_pool/docker/user/hadoop-xt-ai-search/ai-search/jzzhang/HOME/.config/nvim`

---

## 1. Summary of Changes

1. **Plugin Pruning & Filetype Scoping (`lua/plugins/user.lua`)**:
   - Disabled 12 redundant AstroNvim v6 bundled plugins (`nvim-dap`, `nvim-dap-ui`, `nvim-nio`, `cmp-dap`, `mason-nvim-dap.nvim`, `blink.compat`, `none-ls.nvim`, `mason-null-ls.nvim`, `toggleterm.nvim`, `smart-splits.nvim`, `astrotheme`, `todo-comments.nvim`).
   - Ran `:Lazy! clean` + `nvim-save` to delete all 12 directories from disk and refresh `share-bundle.tar` (47 → **35** active specs & on-disk directories).
   - Scoped `windwp/nvim-ts-autotag` (`event = function() return {} end`, web filetypes) and `brenoprata10/nvim-highlight-colors` (`event = function() return {} end`, `module = false`, `css/scss/html/lua/json`, composed `exclude_buffer` preserving `astrocore.buffer.is_large`/`is_valid`).
2. **Dead File Cleanup & Host Providers (`init.lua`, `lua/lazy_setup.lua`, `lua/plugins/user.lua`)**:
   - Deleted 8 dead template/note files (`lua/community.lua`, `lua/polish.lua`, `lua/plugins/{astrocore,astrolsp,astroui,mason,none-ls}.lua`, `dashboard-startup-fix.md`), removed `require "polish"` and `{ import = "community" }`.
   - Updated `install.colorscheme = { "winter-is-coming-light", "habamax" }`, disabled `rplugin`/`tutor`, and disabled unused `ruby`/`perl`/`node` host providers.
   - Added `desc = "Visual Block Mode"` to `<leader>q`.
3. **VS Code Winter is Coming Light Polish & Minimalist UI (`lua/winter_is_coming.lua`, `lua/plugins/user.lua`, `lua/plugins/themes.lua`)**:
   - Added complete plugin UI highlights (`SnacksPicker*`, `SnacksDashboard*`, `BlinkCmp*`, `WhichKey*`, `AerialNormal/Guide`, `NeoTree*`), Treesitter captures (`@keyword.*`, `@function.call`, `@string.documentation`, `@attribute`), and LSP semantic tokens (`@lsp.type.*`).
   - Upgraded `LspInlayHint` contrast across all 3 variants to WCAG ≥ 4.5:1 on both `Normal` and `CursorLine`, and added subtle tinted backgrounds for `DiagnosticVirtualText*`.
   - Wired `blink.cmp` rounded borders + explicit `winhighlight` (`BlinkCmpMenu*`, `BlinkCmpDoc*` with `EndOfBuffer:BlinkCmpDoc`, `BlinkCmpSignatureHelp*`) and `which-key.nvim` rounded borders.
   - Disabled redundant `winbar` (`opts.winbar = nil` in Heirline opts function), set `foldcolumn = "0"`, `scrolloff = 5`, `sidescrolloff = 8`, `updatetime = 200`, `timeoutlen = 300`, `pumheight = 12`.
   - Disabled AstroUI italic tabline (`astroui` `status.attributes.buffer_active = { bold = true, italic = false }`).
4. **Bug Fixes (`lua/plugins/themes.lua`, `lua/plugins/user.lua`, `lua/plugins/render-markdown.lua`)**:
   - `themes.lua`: Unconditional debounced `schedule_strip_italics()` across `ColorScheme`/`Syntax`/`User LazyLoad`, nested `VimEnter` restore with `vim.g.vscode` guard and `flexoki` `colors_name` normalization.
   - `user.lua`: Float-safe `first_normal_win()` helper in Heirline `tabline[1]`; `open_dashboard_on_startup` directory carve-out + `nvim +vnew` guard + `nvim_clear_autocmds({ group = "open_dashboard_on_startup" })` so BOTH `VimEnter` and `BufEnter` registrations are removed cleanly upon completion/expiration.
   - `render-markdown.lua`: Single `MdAirySpacing` augroup with per-buffer `nvim_clear_autocmds` deduplication + skip scanning when `md_airy_spacing` is false; multi-tab `<Leader>mw` Aerial cleanup retaining `ts.auto_aerial` until inactive tabs sync.

---

## 2. Verification Evidence

### 2.1 Before vs After Performance Benchmark (3-trial warm median)
| Metric | Baseline (`7ee04b5`) | After (`iter-001`) | Delta |
| :--- | ---: | ---: | ---: |
| Active specs / on-disk plugin dirs | 47 / 47 | **35 / 35** | **-12 (-25.5%)** |
| `README.md` loaded plugins | 27 | **20** | **-7** |
| `README.md` cumulative plugin load | 292.60 ms | **210.16 ms** (trials: 203.21, 225.84, 210.16) | **-82.44 ms (-28.2%)** |
| `init.lua` loaded plugins | 26 | **21** | **-5** |
| `init.lua` cumulative plugin load | 288.38 ms | **220.07 ms** (trials: 220.07, 224.71, 198.06) | **-68.31 ms (-23.7%)** |

### 2.2 Automated Headless Verification Suite (7/7 Passed)
1. **TEST 1 (`README.md` + Lazy + Blink)**: `total_plugins=35`, `readme_loaded=20`, `Plugin.values(..., "event", true) == {}` for both `nvim-ts-autotag` and `nvim-highlight-colors`, both unloaded on `README.md`, `blink_cfg.sources.providers.dap == nil`, `pcall(require, "nvim-highlight-colors")` blocked by `module = false`, `winbar == ""`, `foldcolumn == "0"`.
2. **TEST 2 (`init.lua` + `exclude_buffer`)**: `lua_loaded=21`, `nvim-ts-autotag` unloaded, `nvim-highlight-colors` loaded on `.lua`, `exclude_buffer` returns `true` for markdown and unlisted/nofile lua buffers, `false` for `init.lua`.
3. **TEST 3 (Highlights, WCAG Contrast, Zero Italics)**: All required `SnacksPicker*`/`SnacksDashboard*`/`BlinkCmp*`/`WhichKey*`/`Aerial*`/`NeoTree*`/`LspInlayHint`/`@lsp.type.*` non-nil; WCAG contrast ratios on `Normal` / `CursorLine`:
   - `winter-is-coming-light`: **5.48:1 / 4.95:1**
   - `winter-is-coming-dark-blue`: **6.03:1 / 5.18:1**
   - `winter-is-coming-dark-black`: **5.78:1 / 5.11:1**
   - Zero italic highlight groups across all 3 themes even after loading `neo-tree.nvim` + direct `:colorscheme`; `astroui.config.status.attributes.buffer_active.italic == false`.
4. **TEST 4 (`MdAirySpacing` dedup + multi-tab `<Leader>mw` + float tabline)**: 3x `FileType markdown` leaves exactly 3 autocmds on `b1` while preserving `b2` (3 autocmds); `<Leader>mw` off closes Aerial in both active tab 2 and inactive tab 1 upon switching back; `redrawtabline` with float open succeeds cleanly.
5. **TEST 5 (`nvim README.md` + Neo-tree + `:enew`)**: `open_dashboard_on_startup` autocmd count = `0`; `:enew` stays editable (not hijacked by dashboard).
6. **TEST 6 (`nvim .` directory startup)**: Both `neo-tree` and `snacks_dashboard` present; `open_dashboard_on_startup` autocmd count = `0` (caught and fixed multi-event `return true` only clearing 1 of 2 events!).
7. **TEST 7 (`nvim +vnew`)**: `open_dashboard_on_startup` autocmd count = `0`.
