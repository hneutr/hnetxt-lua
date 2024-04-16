require("htl")
local M = require("htl.Taxonomy")

local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/glossary/Rogbonesrogbonebone.md")

-- DB.metadata.record(p)
-- os.exit()

local T = M._M(Path("/Users/hne/Documents/text/written/fiction/chasefeel"))

print(T.taxonomy)
print(T.instance_taxonomy)
