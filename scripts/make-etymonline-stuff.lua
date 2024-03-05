require("hl")
local Link = require("htl.text.Link")
local db = require("htl.db").get()

local urls = db.urls
local metadata = db.metadata

local desktop = Path.home:join("Desktop")
local language_dir = Path.home:join("eidola", "language")
local src_file = desktop:join("etylist.md")

function get_etymonline_url(word)
    return string.format("https://www.etymonline.com/word/%s", word)
end

function get_type(l)
    if l:endswith("-") then
        return "prefix"
    elseif l:startswith("-") then
        return "suffix"
    end
end

local type_to_field = Dict({
    prefix = "before:",
    suffix = "after:",
})

src_file:readlines():filter(function(l)
    return #l > 0
end):foreach(function(l)
    local l_type = get_type(l)
    local link = Link({label = l, url = get_etymonline_url(l)})

    local path = language_dir:join(string.format("%s.md", l:gsub('-', '_')))
    
    if not path:exists() then
        print(path)
        path:write(
            List({
                "is a: " .. l_type,
                "  " .. "meaning: ",
                "  " .. "origin: ",
                "  " .. "variants: ",
                "  " .. type_to_field[l_type],
                "  " .. "etymonline: " .. tostring(link),
                "  " .. "@unchecked"
            })
        )

        urls:add_if_missing(path)
        metadata:save_file_metadata(path)
    end
end)
