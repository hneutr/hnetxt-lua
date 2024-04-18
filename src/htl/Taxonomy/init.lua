local lyaml = require("lyaml")

local Taxonomy = require("pl.class")()

Taxonomy.Parser = require("htl.Taxonomy.Parser")

function Taxonomy.is_taxonomy_file(path)
    return path:name() == tostring(Conf.paths.taxonomy_file) or path == Conf.paths.global_taxonomy_file
end

function Taxonomy:_init(path)
    self.tree = self.read_tree(path)
    self:solidify()
end

function Taxonomy:solidify()
    List({
        "parents",
        "ancestors",
        "generations",
        "descendants",
        "children",
    }):foreach(function(key)
        self[key] = self.tree[key](self.tree)
    end)
end

function Taxonomy.read_tree(path)
    local paths = List()
    if path then
        paths = path:parents()

        if path:is_dir() then
            paths:append(path)
        end

        paths = paths:transform(function(p)
            return p:join(Conf.paths.taxonomy_file)
        end):filter(function(p)
            return p:exists()
        end)
    end

    paths:put(Conf.paths.global_taxonomy_file)

    local tree = Tree()

    paths:foreach(function(path)
        tree:add(Tree(lyaml.load(path:read())))
    end)

    return tree
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  testing                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local _M = require("pl.class")()
_M.conf = Dict(Conf.Taxonomy)
_M.conf.relations = Dict(_M.conf.relations)
_M.conf.all_relation_key = "__all"
_M.conf.label_priority = Dict({
    role = List({
        "object",
        "subject",
    }),
    relation = List({
        "other",
        "subset of",
        "instance of",
    }),
})

_M.Printer = require("htl.Taxonomy.Printer")

--[[
relation types handled:
    ✓ subset of
    ✓ instance taxon
    ✓ instance of
    ⨉ attribute of
]]
function _M:_init(path)
    self.projects = self.get_projects(path)
    
    self.rows = self.get_rows(self.projects)
    
    self.label_to_entity = self.get_label_map(self.rows)

    self.rows_by_relation = _M.get_rows_by_relation(self.rows)
    
    self.taxonomy = self.make_taxonomy(self.rows_by_relation["subset of"])
    self.taxon_to_instance_taxon = self.make_taxon_to_instance_taxon_map(
        self.taxonomy,
        self.rows_by_relation["instance taxon"]
    )

    self.instances = self.map_subject_to_object(self.rows_by_relation["instance of"])
end

function _M.get_projects(path)
    return List({
        Conf.paths.global_taxonomy_file,
        path,
    }):map(DB.projects.get_by_path):filter(function(p)
        return p
    end):col('title')
end

function _M.get_rows(projects)
    local urls_by_id = Dict.from_list(
        DB.urls:get(),
        function(u)
            u.label = DB.urls:get_label(u)
            return u.id, Dict(u)
        end
    )
    
    return DB.Relations:get():transform(function(r)
        return Dict({
            subject = _M.get_entity(r, "subject", urls_by_id),
            object = _M.get_entity(r, "object", urls_by_id),
            relation = r.relation,
        })
    end):filter(function(r)
        return projects:index(r.subject.project)
    end):sorted(function(a, b)
        return projects:index(a.subject.project) < projects:index(b.subject.project)
    end)
end

function _M.get_entity(row, role, urls_by_id)
    local entity = Dict()
    
    local fmt = "%s_%s"
    
    local url = urls_by_id[row[fmt:format(role, "url")]] or {}
    
    entity:update(url)
    entity.label = _M.get_label(row[fmt:format(role, "label")], url)
    entity.from_taxonomy = url.path and Taxonomy.is_taxonomy_file(url.path) or false

    return entity
end

function _M.get_label(label, url)
    label = label or url and url.label
    
    if label and #label == 0 then
        return
    end
    
    return label
end

function _M.get_priority(role, relation)
    local order = _M.conf.label_priority

    local role = order.role:index(role) * #order.relation
    local relation = order.relation:index(relation) or order.relation:index("other")
    
    return 1 + role + relation
end

-- TODO: we might need to change this to prefer more information over less
function _M.get_label_map(rows)
    local labels_by_priority = List()
    
    rows:foreach(function(row)
        _M.conf.label_priority.role:foreach(function(role)
            if row[role] then
                local priority = _M.get_priority(role, row.relation)
                while #labels_by_priority < priority do
                    labels_by_priority:append(Dict())
                end
                
                labels_by_priority[priority][row[role].label] = row[role]
            end
        end)
    end)
    
    local map = Dict()
    while #labels_by_priority > 0 do
        map = map:update(labels_by_priority:pop())
    end
    return map
end

function _M.get_rows_by_relation(rows)
    local rows_by_relation = Dict()
    rows:foreach(function(row)
        rows_by_relation:default(row.relation, List())
        rows_by_relation[row.relation]:append({subject = row.subject.label, object = row.object.label})
    end)
    
    return rows_by_relation
end

function _M.map_subject_to_object(rows)
    return Dict.from_list(rows or List(), function(row) return row.subject, row.object end)
end

function _M.make_taxonomy(rows)
    local tree = Tree()
    rows:foreach(function(row)
        tree:add_edge(row.object or tree:parents()[row.subject], row.subject)
    end)
    
    return tree
end

function _M.make_taxon_to_instance_taxon_map(taxonomy, taxon_to_instance_taxon_rows)
    local map = _M.map_subject_to_object(taxon_to_instance_taxon_rows)
    local parents = taxonomy:parents()
    parents:keys():foreach(_M.get_instance_taxon, parents, map)
end

function _M.get_instance_taxon(taxon, parents, taxon_to_instance_taxon_map)
    local instance_taxon
    while taxon and not instance_taxon do
        instance_taxon = taxon_to_instance_taxon_map[taxon]
        taxon = parents[taxon]
    end

    return instance_taxon or "instance"
end

Taxonomy._M = _M

return Taxonomy
