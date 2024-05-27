local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local parse_snippet = ls.parser.parse_snippet
local f = ls.function_node
local t = ls.text_node
local i = ls.insert_node

local Path = require('hl.Path')

local Snippet = require("htl.snippet")

local Header = require("htl.text.header")
local Divider = require("htl.text.divider")


local today = function() return vim.fn.strftime("%Y%m%d") end
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
    return parse_snippet(
        trigger,
        tostring(Divider(size, style)) .. "\n",
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
    ls.snippet("date", fmt(
        [[
            date: {today}

        ]],
        {today = f(today)})
    ),
})


Conf.snippets:keys():foreach(function(key)
    snippets:append(parse_snippet(key, Conf.snippets[key].snippet))
end)

ls.add_snippets("markdown", snippets)
