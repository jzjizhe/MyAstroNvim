---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@param opts AstroCoreOpts
  opts = function(_, opts)
    opts.treesitter = opts.treesitter or {}
    opts.treesitter.ensure_installed = require("astrocore").list_insert_unique(
      opts.treesitter.ensure_installed or {},
      {
        "bash",
        "diff",
        "json",
        "lua",
        "python",
        "query",
        "regex",
        "toml",
        "vim",
        "vimdoc",
        "yaml",
      }
    )
  end,
}
