-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- You can also add or configure plugins by creating files in this `plugins/` folder
-- PLEASE REMOVE THE EXAMPLES YOU HAVE NO INTEREST IN BEFORE ENABLING THIS FILE
-- Here are some examples:

---@type LazySpec
return {

  -- == Examples of Adding Plugins ==
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
      signature = { enabled = true },
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

  -- == Examples of Overriding Plugins ==

  -- customize dashboard options
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
      if opts.tabline and opts.tabline[1] then
        opts.tabline[1] = {
          condition = function(self)
            self.winid = vim.api.nvim_tabpage_list_wins(0)[1]
            self.winwidth = vim.api.nvim_win_get_width(self.winid)
            return self.winwidth ~= vim.o.columns
              and not require("astrocore.buffer").is_valid(vim.api.nvim_win_get_buf(self.winid))
          end,
          {
            provider = function()
              local w = vim.api.nvim_tabpage_list_wins(0)[1]
              return (" "):rep(vim.api.nvim_win_get_width(w))
            end,
            hl = function()
              local w = vim.api.nvim_tabpage_list_wins(0)[1]
              local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
              local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
              if ft == "md_margin_pad" then
                return { bg = normal.bg }
              end
              local nt = vim.api.nvim_get_hl(0, { name = "NeoTreeNormal", link = false })
              return { bg = nt.bg or normal.bg }
            end,
          },
          {
            provider = "│",
            hl = function()
              local w = vim.api.nvim_tabpage_list_wins(0)[1]
              local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
              local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
              if ft == "neo-tree" then
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
              if vim.g.opened_dashboard_on_startup then return end

              local has_neotree = false
              local empty_win, empty_buf

              for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.api.nvim_win_get_config(win).relative == "" then
                  local buf = vim.api.nvim_win_get_buf(win)
                  local filetype = vim.bo[buf].filetype

                  if filetype == "snacks_dashboard" then
                    vim.g.opened_dashboard_on_startup = true
                    return
                  elseif filetype == "neo-tree" then
                    has_neotree = true
                  elseif vim.bo[buf].buftype == ""
                    and vim.api.nvim_buf_get_name(buf) == ""
                    and not vim.bo[buf].modified
                    and vim.api.nvim_buf_line_count(buf) == 1
                    and (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == "" then
                    empty_win, empty_buf = win, buf
                  end
                end
              end

              if not has_neotree or not empty_win then return end

              vim.g.opened_dashboard_on_startup = true
              require("snacks.dashboard").open({ buf = empty_buf, win = empty_win })
            end,
          },
      }
      return opts
    end,
  },

  -- You can disable default plugins as follows:
  { "max397574/better-escape.nvim", enabled = false },

}
