require("htl")

local p = Path("/Users/hne/eidola/language/atelo_.md")

local u = DB.urls:get_file(p)
local e = DB.Elements:where({url = u.id})

DB.Relations:get({where = {subject = e.id}}):foreach(function(r) print(Dict(r)) end)

os.exit()

local Taxonomy = require("htl.Taxonomy")

print(#DB.Instances:get())
local taxonomy = Taxonomy()
print(#DB.Instances:get())

print(#DB.Instances:get({where = {taxon = "quote"}}))

-- print(pt:get_printable_taxon_instances())
