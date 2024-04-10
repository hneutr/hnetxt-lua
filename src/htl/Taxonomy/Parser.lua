local Config = require("htl.Config")
local class = require("pl.class")

--[[
When parsing a row in a taxonomy file, insert into:
  - `db.taxon`:
    - `new_taxon`: val = row
  - `db.taxon_relation`:
    - {subject: `new_taxon`.id, object: `parent_taxon`.id, relation: "subtaxon of"}
    - if there is a predicate:
      - {subject: `new_taxon`.id, object: `predicate.object`.id, relation: "relation"}
when parsing a file, insert into:
  - `db.taxon`:
    - `new_taxon`: url = file.url
  - `db.taxon_relation`:
    - {subject: `new_taxon`.id, object: `predicate`.object.id, relation: "instance of" | `predicate.relation`}
      - make sure to insert the `predicate.object` if none exists
]]

local M = {}
M.conf = Dict(Conf.Taxonomy)
M.conf.relations = Dict(M.conf.relations)



function M:parse_file(path)
    local lines = path:readlines()
end

function M:parse_str(str, subject)
    if not subject then
        subject, str = M:parse_subject(str)
    end

    local object, relation = M:parse_predicate(str)

    return Dict({
        subject = subject,
        object = object,
        relation = relation,
    })
end

function M:parse_subject(str)
    str = str or ""
    return unpack(str:split(":", 1):mapm("strip"))
end

function M:parse_predicate(str)
    str = str or ""
    str = str:strip()
    for relation, symbol in pairs(self.conf.relations) do
        local prefix = string.format("%s(", symbol)
        local suffix = ")"
        if str:startswith(prefix) and str:endswith(suffix) then
            return str:removeprefix(prefix):removesuffix(suffix), relation
        end
    end

    return str
end

return M
