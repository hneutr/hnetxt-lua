local ls = require("luasnip")

local Header = require("htn.text.header")
local Divider = require("htn.text.divider")
local Snippet = require("htl.snippet")

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local ps = ls.parser.parse_snippet

local fmt = require("luasnip.extras.fmt").fmt

local today = function() return vim.fn.strftime("%Y%m%d") end

local function header(trigger, size)
    return ps(
        trigger,
        tostring(Header({size = size, content = "$1"})) .. "\n",
        {trim_empty = false}
    )
end

local function divider(trigger, size, style)
    return ps(
        trigger,
        tostring(Divider(size, style)) .. "\n",
        {trim_empty = false}
    )
end

local snippets = List({
    ps("l", "[$1]($2)"),
    -- dividers
    divider("dl", "large"),
    divider("dm", "medium"),
    divider("ds", "small"),
    divider("dS", "tiny"),
    -- headers
    header("hl", "large"),
    header("hm", "medium"),
    header("hs", "small"),
    header("hS", "tiny"),
    -- metadata dividers
    divider("m", "large", "metadata"),
    s("date", fmt(
        [[
            date: {today}

        ]],
        {today = f(today)})
    ),
})


Snippet.definitions:foreach(function(name, definition)
    snippets:append(ps(name, definition.snippet))
end)

ls.add_snippets("markdown", snippets)
