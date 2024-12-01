require("htl")

local Taxonomy = require("htl.Metadata.Taxonomy")

local url = DB.urls.get_file(Conf.paths.lineage_file)
print(#DB.Metadata:get())
DB.Metadata:remove({source = url.id})
print(#DB.Metadata:get())
