<!-- reviewer: deepseek | backend: magent | model: deepseek-v4.1-flash | effort: max | gate: iter-001-nvim-audit-polish/code | round: 2 | session_id: 01a1f364-a41a-7c82-b03a-34a177904a96 | elapsed_s: 146.0 -->

## Closure verification — `7e468a1`

The commit changes three files: `exec_report.md` (+18 lines), `lua/plugins/render-markdown.lua` (1 line), `lua/plugins/user.lua` (2 lines: callback signature and guard). Both Lua files parse with `luac -p`, and the worktree is clean at HEAD `7e468a1` (only the untracked `docs/workflow/` review artifacts remain).

### 1. [ACCEPTED] `<Leader>mo` outline with `<Leader>mw` off — CLOSED

- `lua/plugins/render-markdown.lua:672`: `ts.auto_aerial = md_layout.enabled and true or "manual_open"` evaluates to `true` when the layout is enabled (identical to `0fb1206`) and to `"manual_open"` when `<Leader>mw` has turned it off.
- I audited every read of `ts.auto_aerial`: lines 188/190 (disabled-layout close), 201/203 (narrow-pane close) and 622/624 (`<Leader>mw` current-tab close) all compare against `== true`, so `"manual_open"` is excluded from each auto-close path. Lines 208/209 and 213/218 special-case only `"manual_closed"` or assign `true` from the auto-open path; line 359 sets `"manual_closed"` from `WinClosed`; line 666 sets `"manual_closed"` on manual close. No truthiness-only test exists, so the string state cannot leak into an auto-close.
- The Round 1 repro now terminates cleanly: `<Leader>mw` (616) → `<Leader>mo` open (671-672) → scheduled `sync_markdown_layout()` (674) → early-return branch (186-192) requires `== true` → the manual outline stays open. TEST A (`exec_report.md:66`) asserts exactly this.

### 2. [ACCEPTED] no-arg startup expiration — CLOSED

- `lua/plugins/user.lua:227` now receives `ev`, and line 271 reads `argc == 0 and (normal_wins > 1 or (ev and ev.event == "VimEnter" and not has_neotree))`.
- `ev` is the Neovim autocmd args table: astrocore passes the callback unchanged into `nvim_create_autocmd` (`astrocore/lua/astrocore/init.lua:600-608`), so `ev.event` is `"VimEnter"` or `"BufEnter"`.
- Event matrix holds: plain/headless no-arg launch (argc 0, one empty window, no Neo-tree, `VimEnter`) → `finish()`; `nvim +vnew` (two normal windows) → `finish()` via the first clause; named-file and 2+ argument launches hit the earlier CLI guard; `nvim .` has `argc == 1`, so the new clause is unreachable and the directory carve-out path is untouched (TEST F).
- With `argc == 0`, every `VimEnter` path now ends in `finish()` (clearing the augroup) or dashboard-open plus `finish()`, so the listener cannot survive startup; the later BufEnter hijack path is gone. TEST C (no-arg headless + `:Neotree show` + `wincmd l`) and TEST D (`+vnew`) cover both branches.

### 3. [REJECTED] `module = false` Blink swatch cache

The adjudication matches the artifacts: the session-cached `hl_provider` no-op is documented in `reviews/plan_round3_codex.md:7`, and `exec_report.md:60-62` records the user's Option A decision. The code path is unchanged by `7e468a1`; inline color highlighting on allowlisted buffers (`css`/`scss`/`html`/`lua`/`json`) still works when the plugin loads on `ft`. No further action needed.

### 4. Round 1 validation requests — CLOSED

- `<Leader>mo` with layout off → **TEST A** (`exec_report.md:66`), matching the code path above.
- Persisted `flexoki-light` VimEnter restore → **TEST E** (`exec_report.md:70`): the reported result (`colors_name="flexoki"`, `bg="light"`, `cs_fired=3`, zero italics) is consistent with `read_saved_theme()` → `is_saved_active()` returning false after forced `habamax` → `apply_theme_entry()` (`themes.lua:90-97`) with `nested = true` forwarded by astrocore.
- Large-buffer `exclude_buffer` → **TEST B** (`exec_report.md:67`): the composed closure (`user.lua:48-55`) returns true through `is_large` for a 2 MB `css` buffer, and Blink opts resolution (`Normal:BlinkCmpMenu` / `BlinkCmpDoc` / `BlinkCmpSignatureHelp`) is covered.

### 5. New-blocker scan

- The behavioral delta of the `<Leader>mo` fix is confined to the disabled-layout state; the enabled state evaluates to `true` exactly as before, so the narrow-pane and multi-tab auto-close paths are unchanged.
- The dashboard guard only fires for `argc == 0` at `VimEnter`; directory launches (`argc == 1`) and the existing CLI/multi-window guards keep their behavior. No other autocmd consumer reads `vim.g.opened_dashboard_on_startup`.
- Report references match the code (`render-markdown.lua:672`, `user.lua:227,271`), and the expanded verification section is internally consistent (TEST A–F, 6 tests).

Review coverage: FULL - git show 7e468a1; lua/plugins/render-markdown.lua (auto_aerial state machine, `<Leader>mw`/`<Leader>mo`); lua/plugins/user.lua (open_dashboard_on_startup); docs/workflow/iter-001-nvim-audit-polish/{exec_report.md,plan.md,reviews/plan_round3_codex.md}; astrocore autocmd creation; lazy/aerial/astroui behavior established in Round 1
Review verdict: APPROVED
