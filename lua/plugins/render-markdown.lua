---@type LazySpec
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown", "Avante" },
    opts = {
      heading = {
        enabled = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      bullet = {
        enabled = true,
        icons = { "●", "○", "◆", "◇" },
      },
      checkbox = {
        enabled = true,
      },
      code = {
        enabled = true,
        style = "full",
      },
    },
  },
  -- Ensure markdown treesitter parsers are installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = require("astrocore").list_insert_unique(
          opts.ensure_installed or {},
          { "markdown", "markdown_inline" }
        )
      end
    end,
  },
  -- Set conceallevel for markdown files
  {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        markdown_conceal = {
          {
            event = "FileType",
            pattern = { "markdown" },
            desc = "Set conceallevel for markdown rendering",
            callback = function()
              vim.opt_local.conceallevel = 2
            end,
          },
        },
      },
    },
  },
}
