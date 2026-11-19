---@type LazySpec

-- ============================================================================
-- Native Seamless Centered Markdown + Right Outline Layout Controller
-- Runs synchronously before first UI frame, keeps symmetric left/right borders,
-- and never places a dummy buffer between Markdown and Aerial TOC.
-- ============================================================================
local md_layout = {
  enabled = true, -- toggled via <Leader>mw
  target_width = 98,
  pad_buf = nil,
  closing_aerial = false,
  syncing = false,
  tabs = {}, -- [tabpage] = { left_win = nil, right_win = nil, auto_aerial = false }
}

local function get_tab_state(tab)
  tab = tab or vim.api.nvim_get_current_tabpage()
  if not md_layout.tabs[tab] then
    md_layout.tabs[tab] = { left_win = nil, right_win = nil, auto_aerial = false }
  end
  return md_layout.tabs[tab], tab
end

local function win_valid_in_tab(w, tab)
  return w ~= nil and vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_tabpage(w) == tab
end

local function close_aerial_programmatic()
  md_layout.closing_aerial = true
  pcall(function() require("aerial").close() end)
  md_layout.closing_aerial = false
end

local function blend_hex(bg, fg, alpha)
  local br = math.floor(bg / 65536) % 256
  local bg_g = math.floor(bg / 256) % 256
  local bb = bg % 256
  local fr = math.floor(fg / 65536) % 256
  local fg_g = math.floor(fg / 256) % 256
  local fb = fg % 256
  local r = math.floor(br + (fr - br) * alpha + 0.5)
  local g = math.floor(bg_g + (fg_g - bg_g) * alpha + 0.5)
  local b = math.floor(bb + (fb - bb) * alpha + 0.5)
  return r * 65536 + g * 256 + b
end

local function refresh_markdown_highlights()
  for i = 1, 6 do
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i .. "Bg", {})
  end
  if (vim.g.colors_name or ""):find("^winter%-is%-coming") then
    return
  end

  local is_dark = vim.o.background == "dark"
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local base_bg = normal_hl.bg or (is_dark and 0x1e1e2e or 0xffffff)

  if is_dark then
    local code_bg = blend_hex(base_bg, 0xffffff, 0.045)
    local inline_bg = blend_hex(base_bg, 0x94a3b8, 0.15)
    local dash_fg = blend_hex(base_bg, 0xffffff, 0.16)
    vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = code_bg })
    vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = 0x79c0ff, bg = inline_bg })
    vim.api.nvim_set_hl(0, "RenderMarkdownDash", { fg = dash_fg })
  else
    local code_bg = blend_hex(base_bg, 0x1f2937, 0.035)
    local inline_bg = blend_hex(base_bg, 0x334155, 0.068)
    local dash_fg = blend_hex(base_bg, 0x1f2328, 0.15)
    vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = code_bg })
    vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = 0x0550ae, bg = inline_bg })
    vim.api.nvim_set_hl(0, "RenderMarkdownDash", { fg = dash_fg })

    local h_colors = { 0x0f172a, 0x0550ae, 0x1f2328, 0x334155, 0x475569, 0x64748b }
    for i, fg in ipairs(h_colors) do
      vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i, { fg = fg, bold = true })
      vim.api.nvim_set_hl(0, "@markup.heading." .. i .. ".markdown", { fg = fg, bold = true })
    end
  end

  for i = 1, 6 do
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i .. "Bg", {})
  end
end

local function refresh_pad_highlights()
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg = normal_hl.bg
  vim.api.nvim_set_hl(0, "MdMarginPad", { bg = bg, fg = bg })
end

local function ensure_pad_buf()
  if md_layout.pad_buf and vim.api.nvim_buf_is_valid(md_layout.pad_buf) then
    return md_layout.pad_buf
  end
  local b = vim.api.nvim_create_buf(false, true)
  vim.bo[b].buftype = "nofile"
  vim.bo[b].bufhidden = "hide"
  vim.bo[b].buflisted = false
  vim.bo[b].swapfile = false
  vim.bo[b].modifiable = false
  vim.bo[b].filetype = "md_margin_pad"
  md_layout.pad_buf = b
  return b
end

local function style_pad_win(w, width)
  if not (w and vim.api.nvim_win_is_valid(w)) then return end
  refresh_pad_highlights()
  vim.wo[w].number = false
  vim.wo[w].relativenumber = false
  vim.wo[w].cursorline = false
  vim.wo[w].cursorcolumn = false
  vim.wo[w].signcolumn = "no"
  vim.wo[w].foldcolumn = "0"
  vim.wo[w].foldenable = false
  vim.wo[w].list = false
  vim.wo[w].wrap = false
  vim.wo[w].spell = false
  vim.wo[w].winfixwidth = true
  vim.wo[w].statusline = " "
  -- Keep default 'vert' & 'WinSeparator' so left boundary line matches right boundary line!
  vim.wo[w].fillchars = "eob: ,stl: ,stlnc: "
  vim.wo[w].winhighlight =
    "Normal:MdMarginPad,NormalNC:MdMarginPad,EndOfBuffer:MdMarginPad,StatusLine:MdMarginPad,StatusLineNC:MdMarginPad"
  pcall(vim.api.nvim_win_set_width, w, width)
end

local function close_win_safe(w)
  if w and vim.api.nvim_win_is_valid(w) then
    local tab = vim.api.nvim_win_get_tabpage(w)
    if #vim.api.nvim_tabpage_list_wins(tab) > 1 then
      pcall(vim.api.nvim_win_close, w, true)
    end
  end
end

local function close_pads(tab)
  local ts = get_tab_state(tab)
  close_win_safe(ts.left_win)
  close_win_safe(ts.right_win)
  ts.left_win = nil
  ts.right_win = nil
end

local function find_markdown_and_other_wins(tab)
  local ts, t = get_tab_state(tab)
  local md_wins = {}
  local other_real_wins = 0
  local aerial_win = nil
  local neotree_w = 0

  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(t)) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      local b = vim.api.nvim_win_get_buf(w)
      local ft = vim.bo[b].filetype
      local bt = vim.bo[b].buftype
      if w == ts.left_win or w == ts.right_win or ft == "md_margin_pad" then
        -- skip our own margin pads
      elseif ft == "aerial" then
        aerial_win = w
      elseif ft == "neo-tree" then
        neotree_w = neotree_w + vim.api.nvim_win_get_width(w)
      elseif ft == "markdown" and bt == "" then
        table.insert(md_wins, w)
      elseif bt == "" then
        other_real_wins = other_real_wins + 1
      end
    end
  end
  return md_wins, other_real_wins, aerial_win, neotree_w
end

local function sync_markdown_layout()
  if md_layout.syncing then return end
  md_layout.syncing = true

  local tab = vim.api.nvim_get_current_tabpage()
  local ts = get_tab_state(tab)

  local ok_err, _ = pcall(function()
    local orig_win = vim.api.nvim_get_current_win()
    local md_wins, other_real_wins, aerial_win, neotree_w = find_markdown_and_other_wins(tab)

    if not md_layout.enabled or #md_wins ~= 1 or other_real_wins > 0 then
      close_pads(tab)
      if not md_layout.enabled and ts.auto_aerial == true and aerial_win then
        close_aerial_programmatic()
        ts.auto_aerial = false
      end
      return
    end

    local main_win = md_wins[1]
    local total_cols = vim.o.columns - (neotree_w > 0 and (neotree_w + 1) or 0)

    -- Narrow pane (< 100 cols remaining): give 100% width to Markdown, hide pads & auto-aerial
    if total_cols < 100 then
      close_pads(tab)
      if ts.auto_aerial == true and aerial_win then
        close_aerial_programmatic()
        ts.auto_aerial = false
      end
      return
    end

    if aerial_win and ts.auto_aerial == "manual_closed" then
      ts.auto_aerial = true
    end

    -- Whenever >= 100 cols are available, auto-open Aerial TOC on the right edge (focus main_win first so Aerial attaches to Markdown!)
    if total_cols >= 100 and not aerial_win and ts.auto_aerial ~= "manual_closed" then
      local ok_a, aerial = pcall(require, "aerial")
      if ok_a and not aerial.is_open({ winid = main_win }) then
        vim.api.nvim_set_current_win(main_win)
        pcall(aerial.open, { focus = false, direction = "right" })
        ts.auto_aerial = true
        _, _, aerial_win, _ = find_markdown_and_other_wins(tab)
      end
    end

    local aerial_w = win_valid_in_tab(aerial_win, tab)
        and vim.api.nvim_win_get_width(aerial_win)
      or 0

    -- If Neo-tree is open on the left, NEVER put a dummy left_pad beside or outside Neo-tree!
    if neotree_w > 0 then
      close_win_safe(ts.left_win)
      ts.left_win = nil
    end

    if aerial_w > 0 then
      -- Aerial is on the right! NEVER put a right_pad between Markdown and Aerial!
      close_win_safe(ts.right_win)
      ts.right_win = nil

      if neotree_w == 0 then
        local free_cols = total_cols - md_layout.target_width - aerial_w - 2
        local desired_left = math.min(math.floor(total_cols * 0.25), free_cols)
        if desired_left >= 10 then
          if not win_valid_in_tab(ts.left_win, tab) then
            vim.api.nvim_set_current_win(main_win)
            vim.cmd("leftabove vertical " .. desired_left .. "split")
            ts.left_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(ts.left_win, ensure_pad_buf())
          end
          style_pad_win(ts.left_win, desired_left)
        else
          close_win_safe(ts.left_win)
          ts.left_win = nil
        end
      end
    else
      local free_cols = total_cols - md_layout.target_width
      local side_w = neotree_w > 0 and free_cols or math.floor(free_cols / 2)
      if side_w >= 10 then
        if neotree_w == 0 then
          if not win_valid_in_tab(ts.left_win, tab) then
            vim.api.nvim_set_current_win(main_win)
            vim.cmd("leftabove vertical " .. side_w .. "split")
            ts.left_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(ts.left_win, ensure_pad_buf())
          end
          style_pad_win(ts.left_win, side_w)
        end

        if not win_valid_in_tab(ts.right_win, tab) then
          vim.api.nvim_set_current_win(main_win)
          vim.cmd("rightbelow vertical " .. side_w .. "split")
          ts.right_win = vim.api.nvim_get_current_win()
          vim.api.nvim_win_set_buf(ts.right_win, ensure_pad_buf())
        end
        style_pad_win(ts.right_win, side_w)
      else
        close_pads(tab)
      end
    end

    if win_valid_in_tab(main_win, tab) then
      vim.wo[main_win].winfixwidth = false
      local used = (
        win_valid_in_tab(ts.left_win, tab)
          and (vim.api.nvim_win_get_width(ts.left_win) + 1)
        or 0
      )
        + (win_valid_in_tab(ts.right_win, tab) and (vim.api.nvim_win_get_width(ts.right_win) + 1) or 0)
        + (aerial_w > 0 and (aerial_w + 1) or 0)
        + (neotree_w > 0 and (neotree_w + 1) or 0)
      local main_target = math.max(40, vim.o.columns - used)
      pcall(vim.api.nvim_win_set_width, main_win, main_target)
      if
        win_valid_in_tab(orig_win, tab)
        and orig_win ~= ts.left_win
        and orig_win ~= ts.right_win
      then
        vim.api.nvim_set_current_win(orig_win)
      elseif vim.api.nvim_get_current_win() ~= main_win then
        vim.api.nvim_set_current_win(main_win)
      end
    end
  end)
  if not ok_err then close_pads(tab) end
  md_layout.syncing = false
end

return {
  {
    "stevearc/aerial.nvim",
    optional = true,
    ft = { "markdown" },
    opts = {
      layout = {
        placement = "edge",
        default_direction = "right",
        width = 22,
        min_width = 18,
        max_width = { 26, 0.18 },
        resize_to_content = false,
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.icons",
    },
    ft = { "markdown", "Avante", "codecompanion" },
    cmd = { "RenderMarkdown" },
    init = function()
      local grp = vim.api.nvim_create_augroup("MdSeamlessLayout", { clear = true })

      -- Run synchronously on VimEnter BEFORE Neovim paints Frame #1!
      vim.api.nvim_create_autocmd("VimEnter", {
        group = grp,
        callback = function()
          sync_markdown_layout()
        end,
      })

      vim.api.nvim_create_autocmd({ "BufWinEnter", "VimResized", "TabEnter" }, {
        group = grp,
        callback = function()
          if vim.v.vim_did_enter == 1 then
            vim.schedule(sync_markdown_layout)
          end
        end,
      })

      vim.api.nvim_create_autocmd("WinClosed", {
        group = grp,
        callback = function(args)
          local closed_win = tonumber(args.match)
          if closed_win and vim.api.nvim_win_is_valid(closed_win) then
            local buf = vim.api.nvim_win_get_buf(closed_win)
            if vim.bo[buf].filetype == "aerial" and not md_layout.closing_aerial then
              local tab = vim.api.nvim_win_get_tabpage(closed_win)
              get_tab_state(tab).auto_aerial = "manual_closed"
            end
          end
          if vim.v.vim_did_enter == 1 then
            vim.schedule(sync_markdown_layout)
          end
        end,
      })

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = grp,
        callback = function()
          vim.schedule(function()
            refresh_markdown_highlights()
            for tab, ts in pairs(md_layout.tabs) do
              if vim.api.nvim_tabpage_is_valid(tab) then
                if win_valid_in_tab(ts.left_win, tab) then
                  style_pad_win(ts.left_win, vim.api.nvim_win_get_width(ts.left_win))
                end
                if win_valid_in_tab(ts.right_win, tab) then
                  style_pad_win(ts.right_win, vim.api.nvim_win_get_width(ts.right_win))
                end
              else
                md_layout.tabs[tab] = nil
              end
            end
          end)
        end,
      })

      vim.api.nvim_create_autocmd("WinEnter", {
        group = grp,
        callback = function()
          local cur = vim.api.nvim_get_current_win()
          local buf = vim.api.nvim_win_get_buf(cur)
          if vim.bo[buf].filetype == "md_margin_pad" then
            local md_wins = find_markdown_and_other_wins()
            if md_wins[1] and vim.api.nvim_win_is_valid(md_wins[1]) then
              vim.api.nvim_set_current_win(md_wins[1])
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd("QuitPre", {
        group = grp,
        callback = function()
          local cur_win = vim.api.nvim_get_current_win()
          local cur_buf = vim.api.nvim_win_get_buf(cur_win)
          if vim.bo[cur_buf].buftype ~= "" then return end

          local md_wins, other_real_wins = find_markdown_and_other_wins()
          if (#md_wins + other_real_wins) <= 1 then
            close_pads()
            close_aerial_programmatic()
          end
        end,
      })
    end,
    opts = {
      render_modes = { "n", "c", "t" },
      anti_conceal = {
        enabled = true,
        above = 0,
        below = 0,
      },
      heading = {
        enabled = true,
        sign = false,
        position = "inline",
        icons = { "▊H₁ ", "▊H₂ ", "▊H₃ ", "▊H₄ ", "▊H₅ ", "▊H₆ " },
        backgrounds = {},
        border = false,
      },
      bullet = {
        enabled = true,
        icons = { "\u{f444}", "\u{f4c3}", "\u{f445}", "▫" },
        right_pad = 0,
      },
      checkbox = {
        enabled = true,
        right_pad = 0,
      },
      quote = {
        enabled = true,
        repeat_linebreak = true,
      },
      dash = {
        enabled = true,
        width = 80,
      },
      code = {
        enabled = true,
        sign = false,
        style = "full",
        width = "block",
        left_pad = 2,
        right_pad = 2,
        min_width = 60,
        border = "thin",
        inline_pad = 0,
      },
      pipe_table = {
        enabled = true,
        preset = "round",
        style = "full",
        cell = "padded",
        padding = 1,
        wrap = true,
      },
      latex = {
        enabled = true,
        converter = { "utftex", "latex2text" },
        inline = true,
        block = true,
        position = "center",
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      local ok_t, TableRender = pcall(require, "render-markdown.render.markdown.table")
      local ok_s, str = pcall(require, "render-markdown.lib.str")
      if ok_t and ok_s and type(TableRender) == "table" and type(TableRender.border) == "function" then
        if not TableRender._row_dividers_patched then
          TableRender._row_dividers_patched = true
          local orig_border = TableRender.border
          TableRender.border = function(self, wrapped)
            orig_border(self, wrapped)

            local rows = self.data and self.data.rows
            local cols = self.data and self.data.cols
            local border = self.config and self.config.border
            if not (rows and cols and border and #rows > 1) then
              return
            end

            if self.config.cell == "raw" then
              for _, r in ipairs({ rows[1], rows[#rows] }) do
                for i, cell in ipairs(r.cells) do
                  if cell.width ~= cols[i].width then
                    return
                  end
                end
              end
            elseif self.config.cell == "overlay" then
              local delim_w = str.width(self.data.delim.text)
              if str.width(rows[1].node.text) ~= delim_w or str.width(rows[#rows].node.text) ~= delim_w then
                return
              end
            elseif not vim.tbl_contains({ "trimmed", "padded" }, self.config.cell) then
              return
            end

            local parts = {}
            for i, col in ipairs(cols) do
              parts[i] = border[11]:rep(col.width)
            end
            local sep_text = border[4] .. table.concat(parts, border[5]) .. border[6]
            local highlight = self.config.row

            for idx = 1, #rows - 1 do
              local item = rows[idx]
              if item.node.type == "pipe_table_row" then
                local pfx = self.data.prefixes and self.data.prefixes[item.node.start_row]
                local virtual_line
                if pfx then
                  virtual_line = self:line():extend(pfx):text(sep_text, highlight):get()
                else
                  local line = self:line():pad(self.data.layout.col):text(sep_text, highlight)
                  virtual_line = self:indent():line(true):extend(line):get()
                end

                local lines = wrapped and wrapped[idx]
                if lines then
                  lines[#lines + 1] = virtual_line
                else
                  self.marks:add(self.config, "virtual_lines", item.node.start_row, 0, {
                    virt_lines = { virtual_line },
                    virt_lines_above = false,
                  })
                end
              end
            end
          end
        end
      end
      refresh_markdown_highlights()
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      local astrocore = require("astrocore")
      local spacing_ns = vim.api.nvim_create_namespace("markdown_airy_spacing")
      local spacing_grp = vim.api.nvim_create_augroup("MdAirySpacing", { clear = true })

      local function refresh_markdown_spacing(buf)
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
          return
        end
        vim.api.nvim_buf_clear_namespace(buf, spacing_ns, 0, -1)
        if not vim.b[buf].md_airy_spacing then
          return
        end

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local in_fence = false
        local in_frontmatter = false

        for i, line in ipairs(lines) do
          if i == 1 and line:match("^---%s*$") then
            in_frontmatter = true
          elseif in_frontmatter and line:match("^---%s*$") then
            in_frontmatter = false
          elseif not in_frontmatter then
            if line:match("^%s*```") or line:match("^%s*~~~") then
              if not in_fence and i > 1 and not lines[i - 1]:match("^%s*$") then
                vim.api.nvim_buf_set_extmark(buf, spacing_ns, i - 1, 0, {
                  virt_lines = { { { "", "Normal" } } },
                  virt_lines_above = true,
                })
              end
              in_fence = not in_fence
            elseif not in_fence and i > 1 then
              local prev = lines[i - 1]
              if not prev:match("^%s*$") then
                local is_list = line:match("^%s*[%-%*%+]%s+") or line:match("^%s*%d+[%.%)]%s+")
                local is_heading = line:match("^#+%s+")
                local is_quote_start = line:match("^%s*>") and not prev:match("^%s*>")
                if is_list or is_heading or is_quote_start then
                  vim.api.nvim_buf_set_extmark(buf, spacing_ns, i - 1, 0, {
                    virt_lines = { { { "", "Normal" } } },
                    virt_lines_above = true,
                  })
                end
              end
            end
          end
        end
      end

      opts.treesitter = opts.treesitter or {}
      opts.treesitter.ensure_installed = astrocore.list_insert_unique(
        opts.treesitter.ensure_installed or {},
        { "markdown", "markdown_inline", "latex", "html", "yaml" }
      )

      opts.options = opts.options or {}
      opts.options.opt = opts.options.opt or {}
      opts.options.opt.autoread = true

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>m"] = { desc = "󰍔 Markdown" }
      opts.mappings.n["<Leader>mr"] = { "<Cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown render" }
      opts.mappings.n["<Leader>mw"] = {
        function()
          md_layout.enabled = not md_layout.enabled
          if not md_layout.enabled then
            local cur_tab = vim.api.nvim_get_current_tabpage()
            for _, t in ipairs(vim.api.nvim_list_tabpages()) do
              close_pads(t)
              local ts = get_tab_state(t)
              if t == cur_tab and ts.auto_aerial == true then
                close_aerial_programmatic()
                ts.auto_aerial = false
              end
            end
          else
            sync_markdown_layout()
          end
        end,
        desc = "Toggle centered readable width + outline",
      }
      opts.mappings.n["<Leader>m="] = {
        function()
          md_layout.target_width = math.min(150, md_layout.target_width + 6)
          sync_markdown_layout()
        end,
        desc = "Widen reading column (+6)",
      }
      opts.mappings.n["<Leader>m-"] = {
        function()
          md_layout.target_width = math.max(68, md_layout.target_width - 6)
          sync_markdown_layout()
        end,
        desc = "Narrow reading column (-6)",
      }
      opts.mappings.n["<Leader>ms"] = {
        function()
          local buf = vim.api.nvim_get_current_buf()
          vim.b[buf].md_airy_spacing = not vim.b[buf].md_airy_spacing
          refresh_markdown_spacing(buf)
          vim.notify(
            "Markdown 段落宽松间距: " .. (vim.b[buf].md_airy_spacing and "开启" or "关闭"),
            vim.log.levels.INFO
          )
        end,
        desc = "Toggle airy list/paragraph spacing",
      }
      opts.mappings.n["<Leader>mo"] = {
        function()
          local ts = get_tab_state()
          local md_wins, _, aerial_win, _ = find_markdown_and_other_wins()
          local aerial = require("aerial")
          if aerial_win or aerial.is_open() then
            aerial.close()
            ts.auto_aerial = "manual_closed"
          else
            if md_wins[1] and vim.api.nvim_win_is_valid(md_wins[1]) then
              vim.api.nvim_set_current_win(md_wins[1])
            end
            aerial.open({ focus = false, direction = "right" })
            ts.auto_aerial = md_layout.enabled and true or "manual_open"
          end
          vim.schedule(sync_markdown_layout)
        end,
        desc = "Toggle Markdown outline (TOC)",
      }
      opts.mappings.n["<Leader>mz"] = {
        function()
          local ok, snacks = pcall(require, "snacks")
          if ok and snacks.zen then snacks.zen() end
        end,
        desc = "Toggle Zen reading mode",
      }

      local function open_markdown_link_under_cursor()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1
        local target = nil

        local init_pos = 1
        while true do
          local s, e = line:find("%b[]%b()", init_pos)
          if not s then break end
          if col >= s and col <= e then
            target = line:sub(s, e):match("^%b[]%((.*)%)$")
            break
          end
          init_pos = e + 1
        end

        if not target then
          target = vim.fn.expand("<cfile>")
        end
        if not target or target == "" or target:match("^https?://") or target:match("^mailto:") then
          return false
        end

        target = target:gsub("^file://", ""):gsub("%%20", " ")

        local lnum = nil
        local path_part, frag = target:match("^(.-)#(.+)$")
        if path_part then
          target = path_part
          lnum = tonumber(frag:match("^[Ll](%d+)"))
        else
          local p2, ln2 = target:match("^(.*%.[%w_]+):(%d+)")
          if p2 then
            target = p2
            lnum = tonumber(ln2)
          end
        end

        if not target:match("^/") and not target:match("^~") then
          local cur_dir = vim.fn.expand("%:p:h")
          target = cur_dir .. "/" .. target
        end
        target = vim.fn.fnamemodify(target, ":p")

        if vim.fn.filereadable(target) == 1 or vim.fn.isdirectory(target) == 1 then
          vim.cmd("edit " .. vim.fn.fnameescape(target))
          if lnum then
            pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
            vim.cmd("normal! zz")
          end
          return true
        end
        return false
      end

      opts.autocmds = opts.autocmds or {}
      opts.autocmds.markdown_conceal = {
        {
          event = "FileType",
          pattern = { "markdown" },
          desc = "Configure Markdown conceal, list hang-indent, and link jump",
          callback = function(args)
            vim.b[args.buf].snacks_indent = false
            vim.opt_local.conceallevel = 2
            vim.opt_local.wrap = true
            vim.opt_local.linebreak = true
            vim.opt_local.breakindent = true
            vim.opt_local.formatlistpat =
              [[^\s*\(\(>\+\s*\)\+\(\d\+[.)]\s\+\|[-*+]\s\+\)\?\|\d\+[.)]\s\+\|[-*+]\s\+\)\s*]]
            vim.opt_local.breakindentopt = "list:-1"
            vim.opt_local.foldcolumn = "0"

            if vim.b[args.buf].md_airy_spacing == nil then
              vim.b[args.buf].md_airy_spacing = false
            end
            refresh_markdown_spacing(args.buf)

            vim.api.nvim_clear_autocmds({ group = spacing_grp, buffer = args.buf })
            vim.api.nvim_create_autocmd("BufEnter", {
              group = spacing_grp,
              buffer = args.buf,
              callback = function() refresh_markdown_spacing(args.buf) end,
            })
            vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
              group = spacing_grp,
              buffer = args.buf,
              callback = function()
                if vim.b[args.buf].md_airy_spacing then
                  refresh_markdown_spacing(args.buf)
                end
              end,
            })

            vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { buffer = args.buf, expr = true, silent = true })
            vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { buffer = args.buf, expr = true, silent = true })
            vim.keymap.set("n", "gf", function()
              if not open_markdown_link_under_cursor() then
                vim.cmd("normal! gf")
              end
            end, { buffer = args.buf, silent = true, desc = "Jump to file/link (supports file:// & #L)" })
            vim.keymap.set("n", "<CR>", function()
              if not open_markdown_link_under_cursor() then
                vim.cmd("normal! +")
              end
            end, { buffer = args.buf, silent = true, desc = "Follow Markdown file link under cursor" })
          end,
        },
      }

      opts.autocmds.agent_doc_autoreload = {
        {
          event = { "FocusGained", "BufEnter", "CursorHold" },
          desc = "Auto-reload buffers modified on disk by AI agents",
          callback = function()
            if vim.fn.getcmdwintype() == "" then
              vim.cmd("silent! checktime")
            end
          end,
        },
      }
    end,
  },
}
