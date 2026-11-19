<!-- reviewer: deepseek | backend: magent | model: deepseek-v4.1-flash | effort: max | gate: iter-001-nvim-audit-polish/code | round: 1 | session_id: 01a1f364-a41a-7c82-b03a-34a177904a96 | elapsed_s: 664.0 -->

I'll start by inspecting the repository state, the commit range, and the referenced docs.

## Review: implementation commit `0fb1206` (`git diff 47c9603..0fb1206`)

### BLOCKER — the manual outline toggle is undone whenever the centered layout is off

`lua/plugins/render-markdown.lua:186-192` (new) closes the current tab's Aerial window any time `md_layout.enabled == false`, and `lua/plugins/render-markdown.lua:659-675` is the only manual way to open it in that state.

Evidence chain:

- `lua/plugins/render-markdown.lua:616` sets `md_layout.enabled = false` on `<Leader>mw`.
- `lua/plugins/render-markdown.lua:671-674` (`<Leader>mo`, open branch) calls `aerial.open({ focus = false, direction = "right" })`, sets `ts.auto_aerial = true` (672), and then unconditionally schedules `sync_markdown_layout()` (674).
- `sync_markdown_layout()` takes the `not md_layout.enabled` branch (186), finds the just-opened outline because `aerial_win` comes from `ft == "aerial"` (`find_markdown_and_other_wins`, 149-151; Aerial sets that filetype at `aerial.nvim/lua/aerial/window.lua:109`; the configured `placement = "edge"` is a normal split, so it also passes `relative == ""`), and calls `close_aerial_programmatic()` (189) then clears the flag (190).

So after `<Leader>mw` off, every `<Leader>mo` press opens the outline and the scheduled sync immediately closes it; the same happens for a manual outline opened in a non-Markdown buffer while the layout is off. On `47c9603` that branch only ran `close_pads(tab)`, which left manually opened outlines in place — this is a functional regression, and it violates the plan's non-goal of preserving the Aerial auto-open/manual-close state machine (`plan.md` §4 Non-Goals).

The `ts.auto_aerial == "manual_closed"` case is protected, but it does not include this path: `<Leader>mo` records the manual open as `true`, which is indistinguishable from an auto-open. A fix needs a distinct state for auto-opened outlines (or closing only on the enabled→disabled transition instead of on every sync).

### Self-test audit (`exec_report.md`)

- **TEST 4 (`exec_report.md:50`)** only covers `<Leader>mw` off with an *auto-opened* outline in two tabs. It never presses `<Leader>mo` after disabling, which is why the regression above is invisible to the suite.
- **TEST 2 (`exec_report.md:44`)** never exercises the `astrocore.buffer.is_large` branch of the composed `exclude_buffer`, although plan §5.1 requires rejecting large buffers as well as non-allowlisted filetypes.
- **No test covers the new `is_saved_active()` / nested `VimEnter` restore** with a persisted `reading_theme.json`. Plan §5.3 requires verifying restore for both `winter-is-coming-light` and `flexoki-light` with `ColorScheme` hooks running; TEST 3 only exercises explicit `:colorscheme` switching and reads `astroui.config`.
- **TEST 4's float-tabline assertion** is "redrawtabline with float open succeeds cleanly", which proves absence of an error and says nothing about the padding width/alignment the plan asked to verify.
- TESTs 1–3, 5–7 otherwise match the stated invariants (autocmd counts, provider absence, contrast values reproduce exactly: 5.48/4.95, 6.03/5.18 and 5.78/5.11).

- Validation request: with `<Leader>mw` off, press `<Leader>mo` in a Markdown buffer and assert `aerial.is_open()` remains true after the scheduled `sync_markdown_layout()`.
- Validation request: write `{"scheme":"flexoki-light","bg":"light"}` to `reading_theme.json`, start `nvim`, and assert `g:colors_name == "flexoki"`, `background == "light"`, and that `User AstroColorScheme`/heirline color refresh ran.
- Validation request: open a `css` buffer above `features.large_buf.size` and assert `exclude_buffer` returns true and no `nvim-highlight-colors` extmarks exist.

### Areas checked and found sound

- **Plugin pruning:** `M:del` calls `fragments:del`, which recursively deletes a plugin's child `specs` (`lazy.nvim/lua/lazy/core/fragments.lua:44-70`). The DAP, smart-splits and toggleterm injected astrocore mappings and blink's `sources.providers.dap` disappear together with their disabled parents, so no stale `require("dap")`/`require("smart-splits")`/`ToggleTerm` keymaps remain; this agrees with the report's `dap == nil`.
- **Filetype scoping:** the user's `opts` table is merged last (`lazy.nvim/lua/lazy/core/plugin.lua:459-484`), `module = false` only blocks module autoloading, and the plugin validates the buffer before calling `exclude_buffer` (`nvim-highlight-colors/lua/nvim-highlight-colors/init.lua:146-154`); every refresh path funnels through `refresh_highlights`.
- **blink / which-key / heirline:** the `winhighlight` keys match the installed blink schema (`config/completion/menu.lua:31`, `config/completion/documentation.lua:48`, `config/signature.lua:51`); AstroNvim's heirline `opts` function is inner to the user's, so `opts.winbar = nil` survives; the child `provider`/`hl` inherit the condition-set `self.winid` through heirline's `__index` chain and fall back to `first_normal_win()` safely.
- **Dashboard:** astrocore names the augroup after the config key (`astrocore/lua/astrocore/init.lua:600-608`), so `nvim_clear_autocmds({ group = "open_dashboard_on_startup" })` resolves and removes both the `VimEnter` and `BufEnter` registrations; `finish()` inside a running callback is safe; the `argc`, directory and `+vnew` guards have no error path. The only residual hijack case (plain `nvim`, then Neo-tree over an empty buffer) is identical in `47c9603`.
- **Themes:** astrocore forwards all autocmd fields including `nested`; `is_saved_active` normalizes `flexoki`; every `p.<field>` used in `winter_is_coming.lua` exists in all three palettes; `MdAirySpacing` yields one `BufEnter` plus `TextChanged`/`InsertLeave` per buffer and leaves no stale extmarks with the skip guard.
- **Dead files / providers:** all seven deleted Lua files were inert (`if true then return {} end` / `return end`), no references remain, every changed file passes `luac -p`, and both the live plugin tree and the persisted `share-bundle.tar` contain 35 directories with none of the 12 removed plugins.

Review coverage: FULL - init.lua, lua/lazy_setup.lua, lua/winter_is_coming.lua, lua/plugins/user.lua, lua/plugins/themes.lua, lua/plugins/render-markdown.lua, lua/plugins/treesitter.lua, lua/plugins/vscode.lua, colors/*.lua, deleted files at 47c9603, docs/workflow/iter-001-nvim-audit-polish/{plan.md,exec_report.md}, installed specs for lazy.nvim, astrocore, astroui, AstroNvim, blink.cmp, heirline.nvim, aerial.nvim, neo-tree.nvim, nvim-highlight-colors
Review verdict: FINDINGS
