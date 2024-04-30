require("htl")

local TParser = require("htl.Taxonomy.Parser")

-- local url = DB.urls:where({path = p})

-- function printit(url)
--     local e = DB.Elements:where({source = url, url = url})
--     DB.Relations:get({where = {subject = e.id}}):foreach(function(u)
--         u.object = Dict(DB.Elements:where({id = u.object}))
--         print(Dict(u))
--     end)
-- end

-- printit(url.id)
-- print(DB.urls:get_label(url))
