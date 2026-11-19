# Project Iteration Log

Chronological overview of each `iter-NNN` cycle: goal, Git commits, key review adjudications, and outcomes.


## `iter-001-nvim-audit-polish` — Neovim Config Audit, Lightweight Speedup, Aesthetic Polish & Bug Fixes

- **Goal**: Audit `~/.config/nvim` (AstroNvim v6) for redundant plugins, startup/file-open speed, VS Code Winter is Coming Light visual fidelity, and latent bugs; keep all changes verified and cleanly tracked in local Git.
- **Milestone Commits**:
  - Base HEAD: `7ee04b5`
  - Plan baseline: `47c9603` (`docs(iter-001): finalize plan for nvim-audit-polish`)
  - Round 1 implementation: `0fb1206` (`feat(iter-001): implement nvim-audit-polish (round1)`)
  - Round 1 review fixes: `7e468a1` (`fix(iter-001): address round1 review blockers`)
- **Key Review Adjudications**:
  - **Plan Review (4-way, 3 rounds → 3/4 `APPROVED`, user approved Option A)**:
    - `[ACCEPTED]` Replace `event = {}` (lazy.nvim list-extend no-op) with `event = function() return {} end` on `nvim-ts-autotag` & `nvim-highlight-colors`.
    - `[ACCEPTED]` Add `module = false` on `nvim-highlight-colors` + compose `exclude_buffer` with `astrocore.buffer.is_large`/`is_valid`; disable AstroUI italic tabline (`status.attributes.buffer_active.italic = false`); schedule `strip_italics()` unconditionally on `ColorScheme`/`Syntax`/`User LazyLoad`; wire explicit `BlinkCmp*` `winhighlight` strings; upgrade `LspInlayHint` to WCAG ≥ 4.5:1; carve out `nvim .` directory launches in `open_dashboard_on_startup`; run `:Lazy! clean` + `nvim-save`.
  - **Code+Test Review (4-way, 2 rounds → 3/4 `APPROVED` [Gemini, GLM-5.3, DeepSeek])**:
    - `[ACCEPTED]` Fix `<Leader>mw` off + manual `<Leader>mo` outline being closed by `sync_markdown_layout()` (`ts.auto_aerial = md_layout.enabled and true or "manual_open"`).
    - `[ACCEPTED]` Expire `open_dashboard_on_startup` on no-arg `VimEnter` when `not has_neotree`.
    - `[ACCEPTED]` Expand automated verification (TEST A–F: `<Leader>mw`+`<Leader>mo`, 2MB `.css` `is_large`/`exclude_buffer`, resolved Blink `winhighlight`, `flexoki-light` nested `VimEnter` restore + `ColorScheme` hooks, `nvim +vnew`, `nvim .`).
    - `[REJECTED]` `module = false` Blink dropdown swatch session-order cache (previously accepted by user at Plan Round 3) and synthetic no-arg `nofile`-beside-Neo-tree-then-clear-`buftype` edge case.
- **Verified Outcomes**:
  - Active specs & on-disk plugin dirs: **47 → 35** (`-12`, `-25.5%`), persisted to `share-bundle.tar` via `nvim-save`.
  - Warm median file-open plugin load: `README.md` **292.60ms → 210.16ms** (`-82.44ms`, `-28.2%`, 27 → 20 plugins); `init.lua` **288.38ms → 220.07ms** (`-68.31ms`, `-23.7%`, 26 → 21 plugins).
  - Net diff: 14 config/dead files touched (`-184` net lines), WCAG ≥ 4.95:1 `LspInlayHint` across all 3 Winter variants, zero italic highlight groups, 13/13 automated headless tests passing.
