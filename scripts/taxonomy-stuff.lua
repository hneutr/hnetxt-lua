require("htl")

local TParser = require("htl.Taxonomy.Parser")

local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/glossary/Rogbones-agulectory.md")
local url = DB.urls:where({path = p})

function printit(url)
    local e = DB.Elements:where({source = url, url = url})
    DB.Relations:get({where = {subject = e.id}}):foreach(function(u)
        u.object = Dict(DB.Elements:where({id = u.object}))
        print(Dict(u))
    end)
end

printit(url.id)
print(DB.urls:get_label(url))

-- local cf = Path("/Users/hne/Documents/text/written/fiction/chasefeel")

-- DB.metadata.record(Conf.paths.global_taxonomy_file)
-- DB.metadata.record(cf / Conf.paths.taxonomy_file)

-- local glossary = cf / "glossary"
-- glossary:iterdir({dirs = false}):foreach(DB.metadata.record)
