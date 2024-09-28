local ls = require("luasnip")
local parse_snippet = ls.parser.parse_snippet

local function header(trigger, size)
    return parse_snippet(
        trigger,
        string.format("%s $1", Conf.sizes[size].prefix)
    )
end

local snippets = List({
    parse_snippet("l", "[$1]($2)"),
    -- dividers
    parse_snippet("d", "---\n", {trim_empty = false}),
    -- headers
    header("h", "large"),
    header("hl", "large"),
    header("hm", "medium"),
    header("hs", "small"),
    header("hsx", "tiny"),
})

Conf.snippets:keys():foreach(function(key)
    snippets:append(parse_snippet(key, Conf.snippets[key].template))
end)

ls.add_snippets("markdown", snippets)
