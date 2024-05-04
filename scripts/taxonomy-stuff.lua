require("htl")

local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/glossary/agulectory.md")

local u = DB.urls:get_file(p)
local e = DB.Elements:where({url = u.id})

DB.Relations:get({where = {subject = e.id}}):foreach(function(r)
    r.object = Dict(DB.Elements:where({id = r.object}))
    r.subject = Dict(DB.Elements:where({id = r.subject}))
    
    if r.type == "lexis.morphemes" then
        print(Dict(r))
    end
end)

os.exit()

local Taxonomy = require("htl.Taxonomy")

print(#DB.Instances:get())
local taxonomy = Taxonomy()
print(#DB.Instances:get())

print(#DB.Instances:get({where = {taxon = "quote"}}))

-- print(pt:get_printable_taxon_instances())
