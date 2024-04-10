require("hl")
require("htl.db").setup()

local Urls = require("htl.db.urls")
local metadata = require("htl.db.metadata")
local Link = require("htl.text.Link")

local dir = Path.home / "eidola" / "language"
local p = dir / "a_.md"

local prefix = "etymonline: "

Urls:get({contains = {path = string.format("%s*", dir)}}):foreach(function(u)
    local lines = u.path:readlines()

    local new_lines = lines:map(function(l)
        local indent, l = l:match("(%s*)(.*)")

        if l:startswith(prefix) then
            l = l:removeprefix(prefix)
            link = Link:from_str(l)

            link.label = "etymonline"
            
            l = tostring(link)
        end

        return indent .. l
    end)

    u.path:write(new_lines)
    metadata.record(u.path)
end)
