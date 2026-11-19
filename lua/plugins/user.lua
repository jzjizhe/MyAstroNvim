---@type LazySpec
local color_fts = {
  css = true,
  scss = true,
  html = true,
  lua = true,
  json = true,
}

local function first_normal_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      return w
    end
  end
  return nil
end

return {
  -- == Prune Redundant AstroNvim Bundled Plugins ==
  -- DAP stack (6)
  { "mfussenegger/nvim-dap", enabled = false },
  { "rcarriga/nvim-dap-ui", enabled = false },
  { "nvim-neotest/nvim-nio", enabled = false },
  { "rcarriga/cmp-dap", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "saghen/blink.compat", enabled = false },
  -- Legacy null-ls stack (2)
  { "nvimtools/none-ls.nvim", enabled = false },
  { "jay-babu/mason-null-ls.nvim", enabled = false },
  -- Redundant terminal / mux / theme / todo (4)
  { "akinsho/toggleterm.nvim", enabled = false },
  { "mrjones2014/smart-splits.nvim", enabled = false },
  { "AstroNvim/astrotheme", enabled = false },
  { "folke/todo-comments.nvim", enabled = false },
  { "max397574/better-escape.nvim", enabled = false },

  -- == Strict Filetype Scoping for Web / Color Plugins ==
  {
    "windwp/nvim-ts-autotag",
    event = function() return {} end,
    ft = { "html", "xml", "javascriptreact", "typescriptreact", "vue", "svelte" },
  },
  {
    "brenoprata10/nvim-highlight-colors",
    event = function() return {} end,
    module = false,
    ft = { "css", "scss", "html", "lua", "json" },
    opts = {
      exclude_buffer = function(bufnr)
        local buf_utils = require("astrocore.buffer")
        return not color_fts[vim.bo[bufnr].filetype]
          or buf_utils.is_large(bufnr)
          or not buf_utils.is_valid(bufnr)
      end,
    },
  },

  -- == Core Plugin Customizations ==
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        hijack_netrw_behavior = "open_default",
        bind_to_cwd = true,
        cwd_target = {
          sidebar = "global",
          current = "global",
        },
        filtered_items = {
          hide_gitignored = false,
          hide_dotfiles = true,
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          border = "rounded",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
        },
        documentation = {
          window = {
            border = "rounded",
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc,Search:None",
          },
        },
      },
      signature = {
        enabled = true,
        window = {
          border = "rounded",
          winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      win = {
        border = "rounded",
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = { enabled = false },
        char = { jump_labels = false },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<C-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            " █████  ███████ ████████ ██████   ██████ ",
            "██   ██ ██         ██    ██   ██ ██    ██",
            "███████ ███████    ██    ██████  ██    ██",
            "██   ██      ██    ██    ██   ██ ██    ██",
            "██   ██ ███████    ██    ██   ██  ██████ ",
            "",
            "███    ██ ██    ██ ██ ███    ███",
            "████   ██ ██    ██ ██ ████  ████",
            "██ ██  ██ ██    ██ ██ ██ ████ ██",
            "██  ██ ██  ██  ██  ██ ██  ██  ██",
            "██   ████   ████   ██ ██      ██",
          }, "\n"),
        },
      },
    },
  },
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      -- Remove redundant winbar breadcrumb to maximize vertical space
      opts.winbar = nil
      if opts.tabline and opts.tabline[1] then
        opts.tabline[1] = {
          condition = function(self)
            local w = first_normal_win()
            if not w then return false end
            self.winid = w
            self.winwidth = vim.api.nvim_win_get_width(w)
            return self.winwidth ~= vim.o.columns
              and not require("astrocore.buffer").is_valid(vim.api.nvim_win_get_buf(w))
          end,
          {
            provider = function(self)
              local w = (self.winid and vim.api.nvim_win_is_valid(self.winid)) and self.winid or first_normal_win()
              if not w then return "" end
              return (" "):rep(vim.api.nvim_win_get_width(w))
            end,
            hl = function(self)
              local w = (self.winid and vim.api.nvim_win_is_valid(self.winid)) and self.winid or first_normal_win()
              local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
              if not w then return { bg = normal.bg } end
              local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
              if ft == "md_margin_pad" then
                return { bg = normal.bg }
              end
              local nt = vim.api.nvim_get_hl(0, { name = "NeoTreeNormal", link = false })
              return { bg = nt.bg or normal.bg }
            end,
          },
          {
            provider = "│",
            hl = function(self)
              local w = (self.winid and vim.api.nvim_win_is_valid(self.winid)) and self.winid or first_normal_win()
              local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
              if w and vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then
                local ntws = vim.api.nvim_get_hl(0, { name = "NeoTreeWinSeparator", link = false })
                if ntws.fg or ntws.bg then
                  return { fg = ntws.fg, bg = ntws.bg or normal.bg }
                end
              end
              local ws = vim.api.nvim_get_hl(0, { name = "WinSeparator", link = false })
              return { fg = ws.fg, bg = ws.bg or normal.bg }
            end,
          },
        }
      end
      return opts
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.opt = vim.tbl_deep_extend("force", opts.options.opt or {}, {
        foldcolumn = "0",
        scrolloff = 5,
        sidescrolloff = 8,
        updatetime = 200,
        timeoutlen = 300,
        pumheight = 12,
      })
      opts.options.g = vim.tbl_deep_extend("force", opts.options.g or {}, {
        loaded_ruby_provider = 0,
        loaded_perl_provider = 0,
        loaded_node_provider = 0,
      })
      opts.rooter = vim.tbl_deep_extend("force", opts.rooter or {}, {
        autochdir = true,
      })
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.open_dashboard_on_startup = {
        {
          event = { "VimEnter", "BufEnter" },
          desc = "Show dashboard in empty window beside neo-tree during startup",
          nested = true,
          callback = function()
            local function finish()
              vim.g.opened_dashboard_on_startup = true
              pcall(vim.api.nvim_clear_autocmds, { group = "open_dashboard_on_startup" })
              return true
            end

            if vim.g.opened_dashboard_on_startup then return finish() end

            local argc = vim.fn.argc()
            if argc > 1 or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 0) then
              return finish()
            end

            local has_neotree = false
            local empty_win, empty_buf
            local normal_wins = 0

            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_win_get_config(win).relative == "" then
                local buf = vim.api.nvim_win_get_buf(win)
                local filetype = vim.bo[buf].filetype

                if filetype == "snacks_dashboard" then
                  return finish()
                elseif filetype == "neo-tree" then
                  has_neotree = true
                elseif vim.bo[buf].buftype == "" then
                  normal_wins = normal_wins + 1
                  local name = vim.api.nvim_buf_get_name(buf)
                  local is_dir = name ~= "" and vim.fn.isdirectory(name) == 1
                  local is_empty = not vim.bo[buf].modified
                    and vim.api.nvim_buf_line_count(buf) == 1
                    and (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == ""
                  if (name ~= "" and not is_dir) or not is_empty then
                    return finish()
                  end
                  if name == "" and is_empty then
                    empty_win, empty_buf = win, buf
                  end
                end
              end
            end

            if argc == 0 and normal_wins > 1 then
              return finish()
            end

            if not has_neotree or not empty_win then return end

            finish()
            require("snacks.dashboard").open({ buf = empty_buf, win = empty_win })
            return true
          end,
        },
      }
      return opts
    end,
  },
}
