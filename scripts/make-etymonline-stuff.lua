require("hl")
local Link = require("htl.text.Link")

local db = require("htl.db").get()
local urls = db.urls
local metadata = db.metadata

local bad_lines = Set({
    "before:",
    "after:",
    "variants:",
})

local dir = Path.home:join("eidola", "language")
Path.home:join("eidola", "language"):iterdir({dirs = false}):filter(function(p)
    return p:stem():startswith("_") or p:stem():endswith("_")
end):foreach(function(p)
    local lines = p:readlines()
    local n = #lines

    lines = lines:filter(function(l)
        return not bad_lines:has(l:strip())
    end)

    if #lines ~= n then
        p:write(lines)
        metadata.record(p)
    end
end)
