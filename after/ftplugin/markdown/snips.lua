local ls = require("luasnip")

local Header = require("htn.text.header")
local Divider = require("htn.text.divider")

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local ps = ls.parser.parse_snippet

local fmt = require("luasnip.extras.fmt").fmt

local today = function() return vim.fn.strftime("%Y%m%d") end

local function header(trigger, size, as_link)
    local content = "$1"

    if as_link then
        content = "[$1]($2)"
    end

    return ps(
        trigger,
        tostring(Header({size = size, content = content})) .. "\n",
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

ls.add_snippets("markdown", {
    ps("l", "[$1]($2)"),
    -- dividers
    divider("dl", "large"),
    divider("dm", "medium"),
    divider("ds", "small"),
    -- headers
    header("hl", "large"),
    header("hm", "medium"),
    header("hs", "small"),
    header("Hl", "large", true),
    header("Hm", "medium", true),
    header("Hs", "small", true),
    -- metadata dividers
    divider("m", "large", "metadata"),
    -- misc
    ps("person", [[
        first name: $1
        middle name: $2
        last name: $3
    ]]),
    ps("book", [[
        is a: book
        by: $1
        published in: ${2:YYYY}
        type: ${3|read,recommendation|}
        read in: ${4:YYYY}
        recommended by: $5
    ]]),
    ps("quote", [[
        is a: quote
        of: $1
        on page: $2

        $5
    ]]),
    s("date", fmt(
        [[
            date: {today}

        ]],
        {today = f(today)})
    ),
    -- make snippet to look for all tags and make a popup selector
    -- ps("t", "@$1"),
    s("thought", fmt(
        [[
            date: {today}
            is a: {i1}
            @{i2}
        ]],
        {today = f(today), i1 = i(1, ""), i2 = i(2, "tag")})
    ),
    ps("word", [[
        is a: word
        seen in: $1
        type: ${2|unknown,cool|}
    ]]),
})
