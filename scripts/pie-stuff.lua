require("htl").init()

local langdir = Path.home / "eidola/language"
local src = langdir / "pieroots.md"

local lines = List(src:read():split("\n\n")[2]:split("\n"))

local function get_path(root)
    root = root:removeprefix("-"):removesuffix("-")
    root = root:gsub("ē", "e")
    root = root:gsub("ā", "a")
    return langdir / string.format("_%s_.md", root)
end

local function get_content(root)
    return List({
        "is a: root",
        "  meaning:",
        "  origin:",
        string.format("  [etymonline](https://www.etymonline.com/word/*%s)", root:removeprefix("-")),
        "  @unchecked",
        "",
    })
end

lines:foreach(function(l)
    local p = get_path(l)
    p:write(get_content(l))
end)
