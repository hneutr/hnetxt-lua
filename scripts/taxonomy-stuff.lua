require("htl")

-- DB.Elements:drop()
-- DB.Relations:drop()
-- DB.drop(DB, "Elements")
-- require("htl.db").drop_table("Elements")


local PTaxonomy = require("htl.Taxonomy.Persistent")

print(#DB.Instances:get())
local pt = PTaxonomy()
print(#DB.Instances:get())

print(#DB.Instances:get({where = {taxon = "quote"}}))

-- print(pt:get_printable_taxon_instances())
