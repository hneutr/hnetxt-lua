require("htl")

local cf = Path("/Users/hne/Documents/text/written/fiction/chasefeel")

DB.metadata.record(Conf.paths.global_taxonomy_file)
DB.metadata.record(cf / Conf.paths.taxonomy_file)


local glossary = cf / "glossary"
glossary:iterdir({dirs = false}):foreach(DB.metadata.record)
