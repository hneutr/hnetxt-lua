local ls = require("luasnip")
local parse_snippet = ls.parser.parse_snippet

local snippets = List({
    parse_snippet("l", "[$1]($2)"),
    -- dividers
    parse_snippet("d", "---\n$1"),
    -- headers
    parse_snippet("h", "# $1"),
    parse_snippet("hf", "## $1"),
    parse_snippet("hd", "### $1"),
    parse_snippet("hs", "#### $1"),
    parse_snippet("ha", "##### $1"),
    parse_snippet("hg", "###### $1"),
})

Conf.snippets:keys():foreach(function(key)
    snippets:append(parse_snippet(key, Conf.snippets[key].template))
end)

ls.add_snippets("markdown", snippets)
