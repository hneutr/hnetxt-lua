require("htl")

local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/.taxonomy.md")

local url = DB.urls:where({path = p})
print(#DB.metadata:get({where = {url = url.id}}))
DB.metadata:remove({url = url.id})
DB.metadata:record(p)
print(#DB.metadata:get({where = {url = url.id}}))
