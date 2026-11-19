Read-only Plan Review for `/mnt/dolphinfs/ssd_pool/docker/user/hadoop-xt-ai-search/ai-search/jzzhang/HOME/.config/nvim` (`docs/workflow/iter-001-nvim-audit-polish/plan.md`).

### Protocol Requirements
- Strictly read-only: do NOT edit, create, or delete any files, and do NOT run mutating commands. Only read files or run read-only inspection commands (`git status`, `git log`, `git diff`, `rg`, reading installed AstroNvim v6 specs under `~/.local/share/nvim-fast/lazy/AstroNvim/lua/astronvim/plugins/`).
- Forbid style, naming, premature abstraction, or over-engineering nitpicks. Report **ONLY `BLOCKER`** issues with concrete `file:line` or technical evidence, or emit `- Validation request: <exact check>` when runtime proof is needed.
- End your response with:
  `Review coverage: FULL|PARTIAL - <inspected files>`
  `Review verdict: APPROVED` or `Review verdict: FINDINGS`

### Review Focus (Tailored to This Neovim AstroNvim v6 Refactor)
Inspect `docs/workflow/iter-001-nvim-audit-polish/plan.md` alongside the current config files (`init.lua`, `lua/lazy_setup.lua`, `lua/winter_is_coming.lua`, `lua/plugins/user.lua`, `lua/plugins/themes.lua`, `lua/plugins/render-markdown.lua`, `lua/plugins/treesitter.lua`) and the installed AstroNvim v6 plugin specs (`~/.local/share/nvim-fast/lazy/AstroNvim/lua/astronvim/plugins/`):

1. **AstroNvim v6 Dependency & Breakage Safety**:
   - Will disabling `nvim-dap`, `nvim-dap-ui`, `nvim-nio`, `cmp-dap`, `mason-nvim-dap.nvim`, `blink.compat`, `none-ls.nvim`, `mason-null-ls.nvim`, `toggleterm.nvim`, `smart-splits.nvim`, `astrotheme`, and `todo-comments.nvim` break any AstroNvim v6 core specs, `blink.cmp` sources (e.g., `cmp-dap` / `blink.compat` source registration), `mason-tool-installer`, `snacks.dashboard`, or `heirline` components?
   - Does setting `event = {}` + `ft = {...}` on `nvim-ts-autotag` and `nvim-highlight-colors` actually override AstroNvim v6's `event = "User AstroFile"` in `lazy.nvim` (or does `lazy.nvim` merge `event` tables so `event = {}` is a no-op and `event = function() return {} end` is required)?
2. **UI & Theme Correctness (`winter_is_coming.lua`, `themes.lua`, `user.lua`)**:
   - Are there any broken highlight group names, contrast failures, or `strip_italics()` edge cases (e.g., lazy-loaded plugins defining italic highlights after `winter-is-coming-light` loads if `User LazyLoad` is skipped)?
   - Does setting `heirline` `opts.winbar = nil` (or `false`) actually disable AstroNvim v6's winbar cleanly without leaving an empty winbar or Lua error in `astroui.status`?
   - Does deleting `lua/community.lua` / `lua/polish.lua` / unused `lua/plugins/*.lua` cause any breakage in `init.lua`, `lazy_setup.lua`, or `vscode.lua`?
3. **Bug-Fix Soundness & Verification Gaps**:
   - Are the proposed fixes for `MdAirySpacing` autocmd duplication, `open_dashboard_on_startup` auto-unregister, Heirline `tabline[1]` float filtering, and `VimEnter` theme restore complete and bug-free?
   - Are there any other real `BLOCKER` bugs in the current Neovim config that `plan.md` missed?
