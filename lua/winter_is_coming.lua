local M = {}

local palettes = {
  light = {
    name = "winter-is-coming-light",
    bg_mode = "light",
    bg = "#FFFFFF",
    bg_alt = "#F5F7FA",
    bg_float = "#F3F6FA",
    bg_visual = "#CEE1F0",
    bg_line = "#EFF4F8",
    bg_search = "#CEE1F0",
    bg_code = "#F5F9FD",
    bg_inline_code = "#ECF3FA",
    fg = "#3E3E3E",
    fg_code = "#236EBF",
    fg_muted = "#6E849B",
    fg_linenr = "#7FB3E3",
    fg_linenr_cur = "#2F86D2",
    border = "#B8D4EC",
    status_bg = "#EDF3FA",
    status_fg = "#034C7C",
    comment = "#357B42",
    string = "#A44185",
    number = "#174781",
    constant = "#174781",
    builtin = "#2970C7",
    variable = "#2F86D2",
    property = "#358A7B",
    parameter = "#5A6B7C",
    keyword = "#0991B6",
    operator = "#7B30D0",
    storage = "#DA5221",
    func = "#B1108E",
    type = "#0444AC",
    class = "#1172C7",
    tag = "#0444AC",
    diag_err = "#DE3D3B",
    diag_warn = "#C58600",
    diag_info = "#236EBF",
    diag_hint = "#08916A",
    diff_add_bg = "#E6F4EA",
    diff_change_bg = "#E8F1FB",
    diff_del_bg = "#FCE8E6",
    diff_text_bg = "#CEE1F0",
    -- Authentic Winter is Coming Markdown tokens (distinct H1-H4 hue ladder)
    md_h1 = "#034C7C",
    md_h2 = "#0460B1",
    md_h3 = "#087F9C",
    md_h4 = "#7B30D0",
    md_bold = "#4E76B5",
    md_emphasis = "#87429A",
    md_code = "#0460B1",
    md_list = "#207BB8",
    md_quote = "#003494",
    md_link_text = "#87429A",
    md_link_url = "#236EBF",
    md_rule = "#CFE2F3",
  },
  dark_blue = {
    name = "winter-is-coming-dark-blue",
    bg_mode = "dark",
    bg = "#011627",
    bg_alt = "#072038",
    bg_float = "#0B2942",
    bg_visual = "#103362",
    bg_line = "#08243E",
    bg_search = "#16467A",
    bg_code = "#072238",
    bg_inline_code = "#0B2942",
    fg = "#EEFFFF",
    fg_code = "#A7DBF7",
    fg_muted = "#5F7E97",
    fg_linenr = "#1E6F9F",
    fg_linenr_cur = "#219FD5",
    border = "#1D4B73",
    status_bg = "#072038",
    status_fg = "#A7DBF7",
    comment = "#7E97AC",
    string = "#D3EED6",
    number = "#8DEC95",
    constant = "#A170C6",
    builtin = "#92B6F4",
    variable = "#A4CEEE",
    property = "#7FDBCA",
    parameter = "#D7DBE0",
    keyword = "#00BFF9",
    operator = "#00BFF9",
    storage = "#6DBDFA",
    func = "#87AFF4",
    type = "#D29FFC",
    class = "#F7ECB5",
    tag = "#6DBDFA",
    diag_err = "#EF5350",
    diag_warn = "#FFCB6B",
    diag_info = "#6DBDFA",
    diag_hint = "#7FDBCA",
    diff_add_bg = "#0E2E2B",
    diff_change_bg = "#0C2B4B",
    diff_del_bg = "#351B29",
    diff_text_bg = "#16467A",
    -- Authentic Winter is Coming Dark Markdown tokens
    md_h1 = "#5ABEB0",
    md_h2 = "#4FB4D8",
    md_h3 = "#82AAFF",
    md_h4 = "#C792EA",
    md_bold = "#57CDFF",
    md_emphasis = "#C792EA",
    md_code = "#F7ECB5",
    md_list = "#6DBDFA",
    md_quote = "#82AAFF",
    md_link_text = "#78BD65",
    md_link_url = "#6DBDFA",
    md_rule = "#163B5C",
  },
  dark_black = {
    name = "winter-is-coming-dark-black",
    bg_mode = "dark",
    bg = "#282822",
    bg_alt = "#21211C",
    bg_float = "#32322B",
    bg_visual = "#103362",
    bg_line = "#31312A",
    bg_search = "#16467A",
    bg_code = "#22221D",
    bg_inline_code = "#35362F",
    fg = "#EEFFFF",
    fg_code = "#A7DBF7",
    fg_muted = "#8F969E",
    fg_linenr = "#5F7E97",
    fg_linenr_cur = "#219FD5",
    border = "#45473F",
    status_bg = "#21211C",
    status_fg = "#A7DBF7",
    comment = "#999999",
    string = "#BCF0C0",
    number = "#8DEC95",
    constant = "#A170C6",
    builtin = "#92B6F4",
    variable = "#A4CEEE",
    property = "#7FDBCA",
    parameter = "#D7DBE0",
    keyword = "#00BFF9",
    operator = "#00BFF9",
    storage = "#6DBDFA",
    func = "#87AFF4",
    type = "#D29FFC",
    class = "#F7ECB5",
    tag = "#6DBDFA",
    diag_err = "#EF5350",
    diag_warn = "#FFCB6B",
    diag_info = "#6DBDFA",
    diag_hint = "#7FDBCA",
    diff_add_bg = "#273828",
    diff_change_bg = "#253342",
    diff_del_bg = "#3D2626",
    diff_text_bg = "#1D466B",
    -- Authentic Winter is Coming Dark Markdown tokens
    md_h1 = "#5ABEB0",
    md_h2 = "#4FB4D8",
    md_h3 = "#82AAFF",
    md_h4 = "#C792EA",
    md_bold = "#57CDFF",
    md_emphasis = "#C792EA",
    md_code = "#F7ECB5",
    md_list = "#6DBDFA",
    md_quote = "#82AAFF",
    md_link_text = "#78BD65",
    md_link_url = "#6DBDFA",
    md_rule = "#45473F",
  },
}

function M.load(variant)
  local p = palettes[variant] or palettes.light
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.o.background = p.bg_mode
  vim.g.colors_name = p.name

  local set = function(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- Editor UI
  set("Normal", { fg = p.fg, bg = p.bg })
  set("NormalNC", { fg = p.fg, bg = p.bg })
  set("NormalFloat", { fg = p.fg, bg = p.bg_float })
  set("FloatBorder", { fg = p.border, bg = p.bg_float })
  set("FloatTitle", { fg = p.md_h1, bg = p.bg_float, bold = true })
  set("CursorLine", { bg = p.bg_line })
  set("CursorColumn", { bg = p.bg_line })
  set("ColorColumn", { bg = p.bg_alt })
  set("Visual", { bg = p.bg_visual })
  set("VisualNOS", { bg = p.bg_visual })
  set("LineNr", { fg = p.fg_linenr, bg = p.bg })
  set("CursorLineNr", { fg = p.fg_linenr_cur, bg = p.bg_line, bold = true })
  set("SignColumn", { fg = p.fg_muted, bg = p.bg })
  set("CursorLineSign", { fg = p.fg_muted, bg = p.bg_line })
  set("FoldColumn", { fg = p.fg_muted, bg = p.bg })
  set("CursorLineFold", { fg = p.fg_muted, bg = p.bg_line })
  set("Folded", { fg = p.fg_muted, bg = p.bg_alt })
  set("WinSeparator", { fg = p.border, bg = p.bg })
  set("VertSplit", { fg = p.border, bg = p.bg })
  set("EndOfBuffer", { fg = p.bg, bg = p.bg })
  set("NonText", { fg = p.border })
  set("SpecialKey", { fg = p.fg_muted })
  set("Whitespace", { fg = p.border })
  set("Conceal", { fg = p.fg_muted })
  set("MatchParen", { fg = p.func, bg = p.bg_visual, bold = true })
  set("Search", { fg = p.fg, bg = p.bg_search })
  set("IncSearch", { fg = p.bg, bg = p.fg_linenr_cur, bold = true })
  set("CurSearch", { link = "IncSearch" })
  set("Directory", { fg = p.fg_linenr_cur, bold = true })
  set("Title", { fg = p.md_h1, bold = true })

  -- Popup / Statusline / Tabline
  set("Pmenu", { fg = p.fg, bg = p.bg_float })
  set("PmenuSel", { fg = "#FFFFFF", bg = p.fg_linenr_cur, bold = true })
  set("PmenuSbar", { bg = p.bg_alt })
  set("PmenuThumb", { bg = p.fg_muted })
  set("StatusLine", { fg = p.status_fg, bg = p.status_bg })
  set("StatusLineNC", { fg = p.fg_muted, bg = p.bg_alt })
  set("TabLine", { fg = p.fg_muted, bg = p.bg_alt })
  set("TabLineFill", { bg = p.bg })
  set("TabLineSel", { fg = p.md_h1, bg = p.bg, bold = true })
  set("WinBar", { fg = p.fg_muted, bg = p.bg })
  set("WinBarNC", { fg = p.fg_muted, bg = p.bg })

  -- Diff & GitSigns
  set("DiffAdd", { bg = p.diff_add_bg })
  set("DiffChange", { bg = p.diff_change_bg })
  set("DiffDelete", { fg = p.diag_err, bg = p.diff_del_bg })
  set("DiffText", { bg = p.diff_text_bg })
  set("Added", { fg = p.diag_hint })
  set("Changed", { fg = p.diag_info })
  set("Removed", { fg = p.diag_err })
  set("GitSignsAdd", { fg = p.diag_hint })
  set("GitSignsChange", { fg = p.diag_info })
  set("GitSignsDelete", { fg = p.diag_err })

  -- Diagnostics
  set("DiagnosticError", { fg = p.diag_err })
  set("DiagnosticWarn", { fg = p.diag_warn })
  set("DiagnosticInfo", { fg = p.diag_info })
  set("DiagnosticHint", { fg = p.diag_hint })
  set("DiagnosticUnderlineError", { sp = p.diag_err, undercurl = true })
  set("DiagnosticUnderlineWarn", { sp = p.diag_warn, undercurl = true })
  set("DiagnosticUnderlineInfo", { sp = p.diag_info, undercurl = true })
  set("DiagnosticUnderlineHint", { sp = p.diag_hint, undercurl = true })

  -- Standard Syntax & Treesitter (strictly NO italics)
  set("Comment", { fg = p.comment })
  set("String", { fg = p.string })
  set("Character", { fg = p.string })
  set("Number", { fg = p.number })
  set("Boolean", { fg = p.number })
  set("Float", { fg = p.number })
  set("Constant", { fg = p.constant })
  set("Identifier", { fg = p.variable })
  set("Function", { fg = p.func })
  set("Statement", { fg = p.keyword })
  set("Conditional", { fg = p.keyword })
  set("Repeat", { fg = p.keyword })
  set("Label", { fg = p.keyword })
  set("Operator", { fg = p.operator })
  set("Keyword", { fg = p.keyword })
  set("Exception", { fg = p.keyword })
  set("PreProc", { fg = p.storage })
  set("Include", { fg = p.keyword })
  set("Type", { fg = p.type })
  set("StorageClass", { fg = p.storage })
  set("Structure", { fg = p.class })
  set("Typedef", { fg = p.type })
  set("Special", { fg = p.builtin })
  set("Delimiter", { fg = p.fg_code })
  set("Underlined", { fg = p.md_link_url, underline = true })
  set("Error", { fg = p.diag_err })
  set("Todo", { fg = p.bg, bg = p.diag_info, bold = true })
  set("Bold", { bold = true })
  set("Italic", { fg = p.md_emphasis })

  set("@variable", { fg = p.variable })
  set("@variable.builtin", { fg = p.builtin })
  set("@variable.parameter", { fg = p.parameter })
  set("@variable.member", { fg = p.property })
  set("@property", { fg = p.property })
  set("@constant", { fg = p.constant })
  set("@constant.builtin", { fg = p.builtin })
  set("@module", { fg = p.class })
  set("@string", { fg = p.string })
  set("@string.escape", { fg = p.operator })
  set("@number", { fg = p.number })
  set("@boolean", { fg = p.number })
  set("@function", { fg = p.func })
  set("@function.builtin", { fg = p.builtin })
  set("@function.method", { fg = p.func })
  set("@constructor", { fg = p.class })
  set("@keyword", { fg = p.keyword })
  set("@keyword.operator", { fg = p.operator })
  set("@keyword.return", { fg = p.keyword })
  set("@operator", { fg = p.operator })
  set("@type", { fg = p.type })
  set("@type.builtin", { fg = p.type })
  set("@tag", { fg = p.tag })
  set("@tag.attribute", { fg = p.property })
  set("@tag.delimiter", { fg = p.fg_muted })
  set("@punctuation", { fg = p.fg_code })
  set("@punctuation.bracket", { fg = p.fg_code })
  set("@punctuation.delimiter", { fg = p.fg_code })
  set("@comment", { fg = p.comment })

  -- Authentic Winter is Coming Markdown & render-markdown.nvim groups
  local h_cols = { p.md_h1, p.md_h2, p.md_h3, p.md_h4, p.md_h4, p.md_h4 }
  for i, hc in ipairs(h_cols) do
    set("@markup.heading." .. i .. ".markdown", { fg = hc, bold = true })
    set("RenderMarkdownH" .. i, { fg = hc, bold = true })
    set("RenderMarkdownH" .. i .. "Bg", {})
    set("markdownH" .. i, { fg = hc, bold = true })
  end
  set("@markup.heading", { fg = p.md_h1, bold = true })
  set("@markup.strong", { fg = p.md_bold, bold = true })
  set("@markup.italic", { fg = p.md_emphasis })
  set("@markup.strikethrough", { fg = p.diag_err, strikethrough = true })
  set("@markup.raw", { fg = p.md_code, bg = p.bg_inline_code })
  set("@markup.raw.markdown_inline", { fg = p.md_code, bg = p.bg_inline_code })
  set("@markup.raw.block", { fg = p.fg })
  set("@markup.list", { fg = p.md_list, bold = true })
  set("@markup.list.checked", { fg = p.diag_hint, bold = true })
  set("@markup.list.unchecked", { fg = p.md_list })
  set("@markup.quote", { fg = p.md_quote })
  set("@markup.link", { fg = p.md_link_text })
  set("@markup.link.label", { fg = p.md_link_text })
  set("@markup.link.url", { fg = p.md_link_url, underline = true })

  set("RenderMarkdownCode", { bg = p.bg_code })
  set("RenderMarkdownCodeInline", { fg = p.md_code, bg = p.bg_inline_code })
  set("RenderMarkdownBullet", { fg = p.md_list, bold = true })
  set("RenderMarkdownQuote", { fg = p.md_quote })
  set("RenderMarkdownDash", { fg = p.md_rule })
  set("RenderMarkdownLink", { fg = p.md_link_text })
  set("RenderMarkdownChecked", { fg = p.diag_hint, bold = true })
  set("RenderMarkdownUnchecked", { fg = p.md_list })
  set("RenderMarkdownTableHead", { fg = p.md_h1, bold = true })
  set("RenderMarkdownTableRow", { fg = p.md_list })

  -- Neo-tree / Aerial / Snacks / Flash polish
  set("NeoTreeNormal", { fg = p.fg, bg = p.bg_alt })
  set("NeoTreeNormalNC", { fg = p.fg, bg = p.bg_alt })
  set("NeoTreeEndOfBuffer", { fg = p.bg_alt, bg = p.bg_alt })
  set("NeoTreeWinSeparator", { fg = p.border, bg = p.bg })
  set("NeoTreeTabActive", { fg = p.md_h1, bg = p.bg, bold = true })
  set("NeoTreeTabInactive", { fg = p.fg_muted, bg = p.bg_alt })
  set("NeoTreeTabSeparatorActive", { fg = p.border, bg = p.bg })
  set("NeoTreeTabSeparatorInactive", { fg = p.border, bg = p.bg_alt })
  set("AerialLine", { bg = p.bg_visual, bold = true })
  set("FlashBackdrop", { fg = p.fg_muted })
  set("FlashMatch", { fg = p.fg, bg = p.bg_visual })
  set("FlashCurrent", { fg = p.bg, bg = p.fg_linenr_cur, bold = true })
  set("FlashLabel", {
    fg = p.bg_mode == "light" and "#FFFFFF" or "#011627",
    bg = p.bg_mode == "light" and "#B1108E" or "#FFCB6B",
    bold = true,
  })
end

return M
