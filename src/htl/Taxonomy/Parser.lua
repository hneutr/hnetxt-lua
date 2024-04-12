local Config = require("htl.Config")
local db = require("htl.db")

-- ┏━━━━━━━━━━━━━━━━━━╸
-- ┇ relations
-- ┗━━━━━━━━━━━━━━━━━━╸
-- - `instance of`
-- - `instance taxon`
-- - `subtaxon of`
-- - `attribute of`


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
M.conf.indent_size = "  "
M.conf.root_taxon = "__root"

function M:parse_taxonomy(path)
    local project = DB.projects.get_by_path(path) or {}
    M:parse_taxonomy_lines(path:readlines()):foreach(function(r)
        DB.Relations:insert(r, project.title)
    end)
end

function M:parse_taxonomy_lines(lines)
    local indent_to_parent = Dict({[""] = M.conf.root_taxon})

    local relations = List()
    lines:foreach(function(l)
        local indent, l = l:match("(%s*)(.*)")
        local parse = M:parse_line(l)

        indent_to_parent[indent .. M.conf.indent_size] = parse.subject
        
        relations:append({
            subject = parse.subject,
            object = indent_to_parent[indent],
            relation = "subset of",
        })
        
        if parse.object and parse.relation then
            relations:append(parse)
        end
    end)
    
    return relations
end

function M:record_taxonomy_relations(relations)
    
end

function M:parse_line(s, subject)
    if not subject then
        subject, s = M:parse_subject(s)
    end

    local object, relation = M:parse_predicate(s)

    return Dict({
        subject = subject,
        object = object,
        relation = relation,
    })
end

function M:parse_subject(s)
    s = s or ""
    local subject, s = unpack(s:split(":", 1):mapm("strip"))
    return subject, s
end

function M:parse_predicate(s)
    s = s or ""
    s = s:strip()
    for relation, symbol in pairs(self.conf.relations) do
        local prefix = string.format("%s(", symbol)
        local suffix = ")"
        if s:startswith(prefix) and s:endswith(suffix) then
            s = s:removeprefix(prefix):removesuffix(suffix)
            
            local link = Link:from_str(s)
            if link then
                s = tonumber(link.url)
            end
            
            return s, relation
        end
    end

    return s
end

return M
