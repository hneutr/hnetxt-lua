local Config = require("htl.Config")

-- ┏━━━━━━━━━━━━━━━━━━╸
-- ┇ relations
-- ┗━━━━━━━━━━━━━━━━━━╸
-- - `instance of`
-- - `instance taxon`
-- - `subtaxon of`
-- - `attribute of`

local M = require("sqlite.tbl")("Relation", {
    id = true,
    subject = {
        type = "integer",
        reference = "Taxa.id",
        on_delete = "cascade",
    },
    relation = "text",
    object = {
        type = "integer",
        reference = "Taxa.id",
        on_delete = "cascade",
    },
})

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
      
return M
