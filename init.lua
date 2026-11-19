-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  local result = vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
  if vim.v.shell_error ~= 0 then
    -- stylua: ignore
    vim.api.nvim_echo({ { ("Error cloning lazy.nvim:\n%s\n"):format(result), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
    vim.fn.getchar()
    vim.cmd.quit()
  end
end

vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"

-- Split current line
vim.keymap.set('n', '<leader>j', 'i<CR><Esc>', { noremap = true, silent = true, desc="Split current line" })

-- Insert empty line
vim.keymap.set('n', '<leader>o', 'o<Esc>', {noremap = true, silent = true, desc = 'Insert empty line below'  })
vim.keymap.set('n', '<leader>O', 'O<Esc>', {noremap = true, silent = true, desc = 'Insert empty line above' })

if vim.env.TMUX then
    vim.g.clipboard = {
        name = 'tmux-clipboard',
        copy = {
            ['+'] = {'tmux', 'load-buffer', '-w', '-'},
        },
        paste = {
            ['+'] = {'tmux', 'save-buffer', '-'},
        },
        cache_enabled = true,
    }
elseif vim.env.HERDR_ENV == "1" or vim.env.REX_SESSION or vim.env.TERM_PROGRAM == "rex" then
    -- Herdr and Rex forward OSC 52 writes from panes to the attached client's clipboard.
    -- Copy via OSC 52; paste from the last yank so `p` never waits on the terminal.
    local osc52 = require("vim.ui.clipboard.osc52")
    local last = { { "" }, "v" }
    local function copy(reg)
        local write = osc52.copy(reg)
        return function(lines, regtype)
            last = { lines, regtype }
            write(lines)
        end
    end
    vim.g.clipboard = {
        name = "osc52-write",
        copy = { ["+"] = copy("+"), ["*"] = copy("*") },
        paste = { ["+"] = function() return last end, ["*"] = function() return last end },
    }
    if vim.g.loaded_clipboard_provider == 0 then
        vim.g.loaded_clipboard_provider = nil
        vim.cmd("runtime autoload/provider/clipboard.vim")
    end
end

-- Auto-copy Visual mouse selection on left-click release without leaving Visual mode
if vim.g.clipboard then
    local left_release = vim.keycode("<LeftRelease>")
    local ns = vim.api.nvim_create_namespace("osc52_mouse_copy")
    local pending = false
    vim.on_key(function(key, typed)
        local k = (typed and typed ~= "") and typed or key
        if k and not pending and k:find(left_release, 1, true) then
            pending = true
            vim.schedule(function()
                pending = false
                local m = vim.fn.mode()
                if m:find("^[vV\22]") then
                    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = m })
                    vim.fn.setreg("+", lines, m)
                end
            end)
        end
    end, ns)
end

vim.keymap.set("n", "<leader>q", "<C-v>", { noremap = true, silent = true, desc = "Visual Block Mode" })

-- Auto-persist /tmp plugin/parser/mason updates back to DolphinFS after :Lazy operations
local lazy_dirty = false
local lazy_save_timer = nil
local function spawn_nvim_save()
  if not lazy_dirty then return end
  lazy_dirty = false
  if lazy_save_timer then
    lazy_save_timer:stop()
    lazy_save_timer:close()
    lazy_save_timer = nil
  end
  if vim.env.NVIM_APPNAME == "nvim-fast" and vim.fn.executable("nvim-save") == 1 then
    vim.system({ "nvim-save" }, { detach = true, stdout = false, stderr = false })
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazyClean", "LazySync" },
  callback = function()
    if vim.env.NVIM_APPNAME ~= "nvim-fast" then return end
    lazy_dirty = true
    if lazy_save_timer then
      lazy_save_timer:stop()
      lazy_save_timer:close()
    end
    lazy_save_timer = vim.uv.new_timer()
    lazy_save_timer:start(3000, 0, vim.schedule_wrap(spawn_nvim_save))
  end,
  desc = "Persist /tmp Neovim plugins back to DolphinFS after Lazy changes",
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = spawn_nvim_save,
  desc = "Flush pending /tmp Neovim plugin persistence on exit",
})



