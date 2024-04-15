require("htl")

-- local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/.taxonomy.md")
local p = Conf.paths.global_taxonomy_file

local url = DB.urls:where({path = p})
print(Dict(url))
os.exit()

print(#DB.metadata:get({where = {url = url.id}}))
DB.metadata:remove({url = url.id})
DB.metadata:record(p)
print(#DB.metadata:get({where = {url = url.id}}))
