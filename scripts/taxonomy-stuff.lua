require("htl")

local Taxonomy = require("htl.Taxonomy")
local args = {
    path = Path("/Users/hne/Documents/text/written/fiction/chasefeel"),
    include_instances = true,
    include_attributes = true,
}
local taxonomy = Taxonomy._M(args.path)
taxonomy.Printer(taxonomy, args)
print(taxonomy.Printer(taxonomy, args))


-- local cf = Conf.paths.global_taxonomy_file
-- local cf = Path("/Users/hne/Documents/text/written/fiction/chasefeel")
-- local cf_tax = cf / Conf.paths.taxonomy_file
-- local p = cf / "glossary" / "hagdei.md"

-- function printit(url)
--     DB.Relations:get({where = {subject_url = url}}):foreach(function(u) print(Dict(u)) end)
-- end

-- -- local u = DB.urls:where({path = p})
-- -- printit(u.id)

-- DB.metadata.record(Conf.paths.global_taxonomy_file)
-- DB.metadata.record(cf / Conf.paths.taxonomy_file)

-- local glossary = cf / "glossary"
-- glossary:iterdir({dirs = false}):foreach(DB.metadata.record)
