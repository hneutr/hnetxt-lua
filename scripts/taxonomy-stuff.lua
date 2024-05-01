require("htl")

-- DB.Elements:drop()
-- DB.Relations:drop()
-- DB.drop(DB, "Elements")
-- require("htl.db").drop_table("Elements")



local TParser = require("htl.Taxonomy.Parser")

-- print(TParser:parse_taxonomy_lines(p:readlines()))
DB.Relations:get({where = {relation = "tag", type = "remind"}}):foreach(function(r)
    print(Dict(r))
    -- local e = Dict(DB.Elements:where({id = r.subject}))
    -- print(Dict(DB.urls:where({id = e.source})))
end)
os.exit()

-- local url = DB.urls:where({path = p})

-- function printit(url)
--     local e = DB.Elements:where({source = url, url = url})
--     DB.Relations:get({where = {subject = e.id}}):foreach(function(u)
--         u.object = Dict(DB.Elements:where({id = u.object}))
--         print(Dict(u))
--     end)
-- end

-- printit(url.id)
