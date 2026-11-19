---@type LazySpec
local state_file = vim.fn.stdpath("state") .. "/reading_theme.json"

local curated_themes = {
  -- ❄️ VS Code Winter is Coming 官方无斜体原版移植（本地纯 Lua，零插件开销）
  { text = "winter-is-coming-light     │ ❄️ VS Code Winter is Coming 浅色原版 (No Italics)", scheme = "winter-is-coming-light", bg = "light" },
  { text = "winter-is-coming-dark-blue │ ❄️ VS Code Winter is Coming 经典深海蓝 (No Italics)", scheme = "winter-is-coming-dark-blue", bg = "dark" },
  { text = "winter-is-coming-dark-black│ ❄️ VS Code Winter is Coming 深碳黑 (No Italics)", scheme = "winter-is-coming-dark-black", bg = "dark" },

  -- ☀️ 精选轻量备选（浅色 / 暗色）
  { text = "github_light               │ 🌤️ GitHub 官方纯白文档风", scheme = "github_light", bg = "light" },
  { text = "flexoki-light              │ ☀️ Obsidian 温暖纸墨阅读风", scheme = "flexoki-light", bg = "light" },
  { text = "catppuccin-latte           │ 🌤️ Catppuccin 奶油暖白", scheme = "catppuccin-latte", bg = "light" },
  { text = "github_dark_dimmed         │ 🌙 GitHub 官方柔和暗灰", scheme = "github_dark_dimmed", bg = "dark" },
  { text = "flexoki-dark               │ 🌙 Obsidian 温暖碳黑暗色", scheme = "flexoki-dark", bg = "dark" },
  { text = "catppuccin-mocha           │ 🌙 Catppuccin 经典柔和暗色", scheme = "catppuccin-mocha", bg = "dark" },
}

local valid_schemes = {}
for _, item in ipairs(curated_themes) do
  valid_schemes[item.scheme] = true
end

local function read_saved_theme()
  local f = io.open(state_file, "r")
  if not f then return nil end
  local raw = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, raw)
  if
    ok
    and type(decoded) == "table"
    and type(decoded.scheme) == "string"
    and valid_schemes[decoded.scheme]
    and (decoded.bg == "light" or decoded.bg == "dark")
  then
    return decoded
  end
  return nil
end

local function save_theme(scheme, bg)
  local f = io.open(state_file, "w")
  if not f then return end
  f:write(vim.json.encode({ scheme = scheme, bg = bg }))
  f:close()
end

local strip_scheduled = false

local function strip_italics()
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if hl.italic or (hl.cterm and hl.cterm.italic) then
      hl.italic = false
      if hl.cterm then hl.cterm.italic = false end
      pcall(vim.api.nvim_set_hl, 0, name, hl)
    end
  end
  for _, group in ipairs({ "Italic", "@markup.italic", "markdownItalic", "htmlItalic" }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.italic = false
    hl.cterm = hl.cterm or {}
    hl.cterm.italic = false
    pcall(vim.api.nvim_set_hl, 0, group, hl)
  end
end

local function schedule_strip_italics()
  if strip_scheduled then return end
  strip_scheduled = true
  vim.schedule(function()
    strip_scheduled = false
    strip_italics()
  end)
end

local function is_saved_active(s)
  if not s or vim.o.background ~= s.bg then return false end
  local cur = vim.g.colors_name
  if not cur then return false end
  if cur == s.scheme then return true end
  if (s.scheme == "flexoki-light" or s.scheme == "flexoki-dark") and cur == "flexoki" then
    return true
  end
  return false
end

local function apply_theme_entry(entry)
  if not entry then return end
  vim.o.background = entry.bg or "light"
  local ok = pcall(vim.cmd.colorscheme, entry.scheme)
  if not ok then
    vim.o.background = "light"
    pcall(vim.cmd.colorscheme, "winter-is-coming-light")
  end
  strip_italics()
  schedule_strip_italics()
end

local saved = read_saved_theme()

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      flavour = "latte",
      no_italic = true,
      background = { light = "latte", dark = "mocha" },
      integrations = {
        aerial = true,
        flash = true,
        gitsigns = true,
        markdown = true,
        mason = true,
        mini = { enabled = true },
        neotree = true,
        render_markdown = true,
        snacks = true,
        treesitter = true,
        which_key = true,
      },
    },
  },
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    lazy = true,
  },
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = true,
  },

  -- Set default colorscheme and disable italic tabline via AstroUI
  {
    "AstroNvim/astroui",
    opts = {
      colorscheme = saved and saved.scheme or "winter-is-coming-light",
      status = {
        attributes = {
          buffer_active = { bold = true, italic = false },
        },
      },
    },
  },

  -- Live-preview Curated Reading Theme Switcher (<Leader>mt)
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.opt = opts.options.opt or {}
      opts.options.opt.background = saved and saved.bg or "light"

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>mt"] = {
        function()
          local prev_state = {
            scheme = vim.g.colors_name or "winter-is-coming-light",
            bg = vim.o.background,
          }
          local confirmed = false

          local ok_snacks, snacks = pcall(require, "snacks")
          if ok_snacks and snacks.picker then
            local picker_items = {}
            for idx, entry in ipairs(curated_themes) do
              picker_items[#picker_items + 1] = {
                idx = idx,
                text = entry.text,
                entry = entry,
              }
            end
            snacks.picker.pick({
              title = "🎨 精选主题 (j/k 上下实时预览 · Enter 保存 · Esc 还原)",
              items = picker_items,
              format = "text",
              layout = {
                preset = "select",
                layout = { width = 0.62, height = 0.45 },
              },
              on_change = function(_, item)
                if item and item.entry then
                  vim.schedule(function() apply_theme_entry(item.entry) end)
                end
              end,
              confirm = function(picker, item)
                confirmed = true
                picker:close()
                if item and item.entry then
                  vim.schedule(function()
                    apply_theme_entry(item.entry)
                    save_theme(item.entry.scheme, item.entry.bg)
                    vim.notify("已保存默认主题: " .. item.entry.scheme .. " (" .. item.entry.bg .. ")", vim.log.levels.INFO)
                  end)
                end
              end,
              on_close = function()
                if not confirmed then
                  vim.schedule(function() apply_theme_entry(prev_state) end)
                end
              end,
            })
          else
            vim.ui.select(curated_themes, {
              prompt = "选择阅读/编辑配色主题 (自动记忆):",
              format_item = function(item) return item.text end,
            }, function(choice)
              if not choice then return end
              apply_theme_entry(choice)
              save_theme(choice.scheme, choice.bg)
              vim.notify("已保存默认主题: " .. choice.scheme, vim.log.levels.INFO)
            end)
          end
        end,
        desc = "Live-preview & switch reading themes",
      }

      opts.autocmds = opts.autocmds or {}
      if not vim.g.vscode then
        opts.autocmds.restore_reading_theme = {
          {
            event = "VimEnter",
            nested = true,
            desc = "Ensure persisted reading theme & italic-free state after startup",
            callback = function()
              local s = read_saved_theme()
              if s and not is_saved_active(s) then
                apply_theme_entry(s)
              else
                schedule_strip_italics()
              end
            end,
          },
          {
            event = { "ColorScheme", "Syntax" },
            desc = "Disable italic styles across all colorschemes and syntax files",
            callback = function()
              if package.loaded["flash"] then
                pcall(function() require("flash.highlight").setup() end)
              end
              schedule_strip_italics()
            end,
          },
          {
            event = "User",
            pattern = "LazyLoad",
            desc = "Strip italics from lazy-loaded plugin highlight groups",
            callback = function()
              schedule_strip_italics()
            end,
          },
        }
      end
    end,
  },
}
