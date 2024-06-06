local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local parse_snippet = ls.parser.parse_snippet
local f = ls.function_node
local i = ls.insert_node

local Path = require('hl.Path')

local Snippet = require("htl.Snippet")

local Header = require("htl.text.header")
local Divider = require("htl.text.divider")

local link_id = function()
    return tostring(DB.urls:new_link(Path.this()).id)
end

local function header(trigger, size)
    return parse_snippet(
        trigger,
        tostring(Header({size = size, content = "$1"})) .. "\n",
        {trim_empty = false}
    )
end

local function divider(trigger, size, style)
    -- print(size)
    -- print(style)
    return parse_snippet(
        trigger,
        tostring(Divider({size = size, style = style})) .. "\n",
        {trim_empty = false}
    )
end

local snippets = List({
    parse_snippet("l", "[$1]($2)"),
    ls.snippet("L", fmt("[{label}](:{link_id}:)", {label = i(1), link_id = f(link_id)})),
    -- dividers
    divider("dl", "large"),
    divider("dm", "medium"),
    divider("ds", "small"),
    divider("dsx", "tiny"),
    -- metadata dividers
    divider("m", "large", "metadata"),
    -- headers
    header("hl", "large"),
    header("hm", "medium"),
    header("hs", "small"),
    header("hsx", "tiny"),
})

Conf.snippets:keys():foreach(function(key)
    snippets:append(parse_snippet(key, Conf.snippets[key].template))
end)

ls.add_snippets("markdown", snippets)
