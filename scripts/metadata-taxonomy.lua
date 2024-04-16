require("htl")

local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/test-clitch-subspecies.md")
local u = DB.urls:where({path = p})
print(Dict(u))
-- local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/.taxonomy.md")
-- local p = Conf.paths.global_taxonomy_file

function print_q(q)
    DB.Relations:get_annotated(q):foreach(function(r)
        print(Dict(r))
    end)
end

print_q({where = {relation = "instance taxon"}})
print_q({where = {subject_url = u.id}})

local M = require("htl.Taxonomy")
print(M._M(Path("/Users/hne/Documents/text/written/fiction/chasefeel")).taxonomy)
