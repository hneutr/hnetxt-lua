require("htl")

local p = Path.home / "eidola" / 'people' / "Brandon-Sanderson.md"

local u = DB.urls:where({path = p})

DB.Relations:get({where = {object = u.id}}):foreach(function(url)
    print(DB.urls:where({id = url.subject}).path)
end)
os.exit()


local to_recreate = List()
local to_delete = List()

-- local lowest_taxonomy_id = DB.urls:get({where = {resource_type = "taxonomy_entry"}}):col('id'):sorted()[1]

-- local urls = DB.urls:get():filter(function(u) return u.id > lowest_taxonomy_id and u.resource_type ~= "taxonomy_entry" end)

-- DB.urls:remove({resource_type = "taxonomy_entry"})
-- DB.urls:remove({id = {11515, 11516, 11517, 11518}})

local to_recreate = List({
    {
        created = "20240207",
        path = Path("/Users/hne/corpus/lines/writing-with-a-gun-to-your-head.md"),
    },
    {
        created = "20240102",
        path = Path("/Users/hne/corpus/grist/aliens-harvesting-human-shit.md"),
    },
    {
        created = "20240513",
        path = Path("/Users/hne/corpus/grist/what-would-it-be-like-to-take-a-vacation-from-yourself.md"),
    },
    {
        created = "20240514",
        path = Path("/Users/hne/corpus/ego/journal/20240514.md")
    },
})

-- to_recreate:foreach(function(d)
--     print(DB.urls:where({path = d.path}))
-- end)

local urls = DB.urls:get():col('id'):sorted()
local highest_id = urls[#urls]
print(highest_id)
