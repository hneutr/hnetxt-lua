local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local parse_snippet = ls.parser.parse_snippet
local f = ls.function_node
local i = ls.insert_node

local Path = require('hl.Path')

local Snippet = require("htl.Snippet")

local link_id = function()
    return tostring(DB.urls:new_link(Path.this()).id)
end

local function header(trigger, size)
    return parse_snippet(
        trigger,
        string.format("%s $1", Conf.sizes[size].prefix),
        {trim_empty = false}
    )
end

local function divider(trigger)
    return parse_snippet(trigger, "---" .. "\n", {trim_empty = false})
end

local snippets = List({
    parse_snippet("l", "[$1]($2)"),
    ls.snippet("L", fmt("[{label}](:{link_id}:)", {label = i(1), link_id = f(link_id)})),
    -- dividers
    divider("d"),
    divider("dl"),
    divider("dm"),
    divider("ds"),
    divider("dsx"),
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
