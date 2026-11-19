<!-- reviewer: deepseek | backend: magent | model: deepseek-v4.1-flash | effort: max | gate: iter-001-nvim-audit-polish/plan | round: 1 | session_id: 01a1f30e-d15c-7343-a418-c345b8647458 | elapsed_s: 891.7 -->

I'll start by inspecting the plan and current config, then verify against the installed AstroNvim v6 specs.

## BLOCKER 1 — `event = {}` does not clear AstroNvim's inherited lazy-load trigger

`plan.md:142` says to override the filetype scoping by "explicitly set `event = {}`"; `plan.md:67` and `plan.md:69` rely on this for `nvim-ts-autotag` and `nvim-highlight-colors`. That mechanism is a no-op in lazy.nvim:

- Inherited triggers: `.../AstroNvim/lua/astronvim/plugins/ts-autotag.lua:3` sets `event = "User AstroFile"`; `.../highlight-colors.lua:3` sets `event = { "User AstroFile", "InsertEnter" }`.
- Handler values are merged as **lists**: `~/.local/share/nvim-fast/lazy/lazy.nvim/lua/lazy/core/handler/init.lua:106` calls `Plugin.values(plugin, type, true)`, and `lazy/core/plugin.lua:464-465` then runs `Util.extend(ret, values)`. `Util.extend` (`lazy/core/util.lua:338-349`) only appends entries that are not already present, so appending `{}` changes nothing.
- Fragment chaining (`lazy/core/meta.lua:251`) makes AstroNvim's spec the super of the user spec, so `ret` already contains `"User AstroFile"` (and `"InsertEnter"`) before the user's empty table is merged.

Consequence: both plugins still register `User AstroFile`, and `nvim-highlight-colors` additionally loads on every `InsertEnter`. The scoping in `plan.md:67/69` never takes effect, so the acceptance thresholds `loaded <= 19` / `≤185ms` (`plan.md:13`, verification item 1 at `plan.md:147`) cannot be met by the enumerated changes.

Required change: `event = function(_, _) return {} end`. lazy's function branch (`lazy/core/plugin.lua:458-460`) replaces the accumulated list with the returned table. `ft` needs no special handling (AstroNvim sets no `ft` for these two plugins), and `lazy = true` is preserved because the function is truthy (`plugin.lua:236-241`).

## BLOCKER 2 — the italic guarantee cannot hold; the "skip when winter" branch leaves AstroNvim's own italic tabline in place

`plan.md:111` allows skipping the `strip_italics()` scan when a `winter-is-coming` theme is active and still claims "zero italics". Two facts break that claim:

- AstroNvim's own status config adds italic: `.../AstroNvim/lua/astronvim/plugins/_astroui_status.lua:104` — `buffer_active = { bold = true, italic = true }`. The tabline buffer component applies it through `get_attributes(self.tab_type)` (`.../astroui/lua/astroui/status/config.lua:437-441`, `.../astroui/lua/astroui/status/hl.lua:50-56`).
- Heirline materializes those attributes as highlight groups **at render time and only once**: `.../heirline.nvim/lua/heirline/highlights.lua:101-104` calls `nvim_set_hl` only when a group name is first seen; later renders reuse the group. Any `strip_italics()` that runs before the tabline is first painted (startup `VimEnter`/`ColorScheme` both precede the first redraw) never sees the `Stl…bolditalic` group. If the `User LazyLoad` scan is skipped, the group stays italic for the session, and it is recreated after every theme switch because `astroui` resets `defined_highlights` on `User AstroColorScheme` before the next redraw.

Consequence: verification item 2's assertion "zero groups have `italic = true`" (`plan.md:147-148`) is not achievable as written (a headless check can pass while the tabline renders italic), and the iteration's "No Italics" objective is violated.

Required change: set `status.attributes.buffer_active = { bold = true, italic = false }` in the `astroui` opts (the `italic = false` must be explicit — `Util.merge` keeps the inherited `true` if the key is omitted), and keep the debounced `strip_italics()` unconditional (drop the skip clause).

## Focus answers (no blocker found)

- **Disabling the 12 plugins is clean.** lazy's `Meta:disable` (`meta.lua:258-262`) deletes the plugin fragment and its child fragments (`fragments.lua:72-77`), so the `astrocore` mapping/`opts` fragments contributed by `dap.lua`, `none-ls.lua`, `toggleterm.lua`, `smart-splits.lua`, and `todo-comments.lua` are removed with their parents — no dangling `require("dap")`/`require("toggleterm")` keymaps. `blink.cmp`'s `enabled()` uses `astrocore.is_available "cmp-dap"` (`blink.lua:84`; `astrocore/init.lua:201-209`), which returns false after removal; blink's default sources are `lsp/path/snippets/buffer` and the `dap` provider registration lives entirely in `cmp-dap`'s child spec; `blink.compat` is only referenced by `cmp-dap`'s config. `mason-tool-installer` already sets both integrations false (`mason-tool-installer.lua:24`). `snacks.lua`, `heirline.lua`, and `astroui.status` have no references. `astroui`'s colorscheme is overridden at `lua/plugins/themes.lua:113-119`, and `install.colorscheme` is only consulted when a plugin is missing (`lazy/core/loader.lua:66-82`). `astrocore.toggle_term_cmd` is only invoked from `toggleterm.lua` itself.
- **Behavior change to be aware of:** `<Leader>t*`, `<F7>`, `<C-'>`, `<C-H/J/K/L>`, `]T`/`[T`/`<Leader>fT`, `<Leader>lI`, `<Leader>d*`/F5 etc. disappear; AstroNvim's `snacks.lua` defines no terminal keymaps to replace toggleterm's.
- **`heirline` `opts.winbar = nil` is safe:** `heirline/init.lua:88-91` only sets `M.winbar` and registers the winbar autocmd when `config.winbar` is truthy, so no empty bar and no `astroui.status` call.
- **Deleting `community.lua` / `polish.lua` / unused `lua/plugins/*.lua` is safe:** only `init.lua:26` and `lazy_setup.lua:14` reference them; `lua/plugins/vscode.lua` does not.
- **Proposed bug fixes are sound:** `MdAirySpacing` duplicate registration is real (`lua/plugins/render-markdown.lua:760-763`); returning truthy from `open_dashboard_on_startup` (`lua/plugins/user.lua:138`) deletes the autocmd (runtime `api.txt:2142`; astrocore passes the callback through at `astrocore/init.lua:604-608`); the tabline float filter and `VimEnter` scheme check are correct.

## Validation requests

- Validation request: after implementing the `ft` scoping, run `:lua print(vim.inspect(require("lazy.core.plugin").values(require("lazy.core.config").plugins["nvim-ts-autotag"], "event", true)))` (and the same for `nvim-highlight-colors`); expect `{}` — `{"User AstroFile"}` / `{"User AstroFile","InsertEnter"}` proves the inherited triggers remain.
- Validation request: with the dashboard/tabline rendered in a UI session (not headless), run `:lua for n,h in pairs(vim.api.nvim_get_hl(0,{})) do if h.italic then print(n) end end`; expect no `Stl*` group. A repeated check right after a `<Leader>mt` theme switch exposes the heirline regression.
- Validation request: recompute acceptance criterion 1. The plan's own baseline is `292.60ms`; the enumerated "top wasted" removals total `58.76ms` (21.25+20.93+5.06+4.71+4.39+2.42), leaving `~233.8ms`, which misses `≤185ms` by ~49ms. Likewise only 6 of the 26–27 loaded plugins are removed (→ ~20–21, not `≤19`). Confirm the profiling script's accounting or relax the thresholds before treating a miss as an implementation defect.

Review coverage: FULL - `docs/workflow/iter-001-nvim-audit-polish/plan.md`, `init.lua`, `lua/lazy_setup.lua`, `lua/winter_is_coming.lua`, `colors/*.lua`, `lua/plugins/{user,themes,render-markdown,treesitter,vscode,astrocore,astrolsp,astroui,mason,none-ls}.lua`, `lua/community.lua`, `lua/polish.lua`; installed AstroNvim v6 specs (`dap`, `none-ls`, `ts-autotag`, `highlight-colors`, `blink`, `heirline`, `snacks`, `toggleterm`, `smart-splits`, `todo-comments`, `mason-tool-installer`, `_astroui`, `_astroui_status`, `_astrocore_mappings`, `configs/*`); lazy.nvim core (`plugin.lua`, `util.lua`, `meta.lua`, `fragments.lua`, `loader.lua`, `handler/init.lua`); astrocore/astroui/heirline/snacks/which-key/blink/aerial/neo-tree sources; Neovim runtime docs (`api.txt`, `autocmd.txt`).
Review verdict: FINDINGS
