local lyaml = require("lyaml")

--[[
what are we trying to do?
1. determine instance types
2. print taxonomies (relative to a directory)

to determine an instance's type:
- construct the taxonomy
- it matches:
    - its lineage (itself + parents)
    - the lineage of anything inherited via a `give_instances` relation

so, how do we construct the taxonomy?
- for now, without `give_instances` stuff

the seeds are:
- instances
- subsets
    - from both files and taxonomies
relative to the given dir

for each of those:
- add them to the tree

we also want to add the global taxonomy, but we're going to do that _AFTER_
- for subsets that don't have a parent:
    - chase them up the global taxonomy tree

----------------------------------------
Fuck it, we're just gonna be lazy and do this:
- for all `subset` relations, add it to the taxonomy

]]

local Taxonomy = class()

Taxonomy.Parser = require("htl.Taxonomy.Parser")

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
        local lines = path:readlines():transform(function(l) return l:gsub(": .*", ":") end)
        tree:add(Tree(lyaml.load(lines:join("\n"))))
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
local _M = class()
_M.conf = Dict(Conf.Taxonomy)
_M.conf.all_attribute_key = "__all"
_M.conf.label_priority = Dict({
    role = List({
        "object",
        "subject",
    }),
    relation = List({
        "other",
        "subset",
        "instance",
    }),
})

_M.Printer = require("htl.Taxonomy.Printer")

function _M:_init(path)
    self.projects = self.get_projects(path)
    
    self.rows = self.get_rows(self.projects)

    self.label_to_entity = self.get_label_map(self.rows)

    self.rows_by_relation = self.get_rows_by_relation(self.rows)
    
    self.taxonomy = self.make_taxonomy(self.rows_by_relation.subset, self.label_to_entity)
    
    self.taxon_to_instances = self.map_instances_to_taxa(self.rows_by_relation.instance)
    
    self.apply_inheritence(
        self.taxonomy,
        self.rows_by_relation.give_instances,
        self.taxon_to_instances,
        self.rows_by_relation.connection
    )
    
    self.instances = self.make_instances(
        self.taxon_to_instances,
        self.label_to_entity
    )
    
    self.map_attributes(
        self.label_to_entity,
        self.rows_by_relation.connection
    )
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
            type = r.type,
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
    entity.from_taxonomy = url.path and Taxonomy.Parser.is_taxonomy_file(url.path) or false

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
        rows_by_relation[row.relation]:append({
            subject = row.subject.label,
            object = row.object.label,
            type = row.type,
        })
    end)
    
    return rows_by_relation
end

function _M.map_subject_to_object(rows)
    return Dict.from_list(rows or List(), function(row) return row.subject, row.object end)
end

function _M.make_taxonomy(rows, label_to_entity)
    local tree = Tree()
    rows:foreach(function(row)
        tree:add_edge(row.object or tree:parents()[row.subject], row.subject)
        
        if label_to_entity[row.subject] then
            label_to_entity[row.subject].type = "subset"
        end
    end)
    
    return tree
end

function _M.map_instances_to_taxa(rows)
    local map = Dict()
    rows:foreach(function(row)
        map:set({row.object, row.subject})
    end)
    
    return map
end

function _M.apply_inheritence(taxonomy, inheritence_rows, taxon_to_instances, connection_rows)
    local children = taxonomy:children()
    inheritence_rows:foreach(function(row)
        local subject = row.subject
        local object = row.object

        local instances = Dict(taxon_to_instances[subject])
        List(children[subject]):foreach(function(_subject)
            instances:update(taxon_to_instances[_subject])
        end)
        
        instances:keys():foreach(function(instance)
            if row.type == "instance" then
                taxon_to_instances:set({object, instance})
            else
                connection_rows:append({
                    subject = instance,
                    object = object,
                    relation = "connection",
                    type = row.type,
                })
            end
        end)
    end)
    
    -- if an instance receives multiple parents in the same lineage, only show the most specific
    local ancestors = taxonomy:ancestors()
    taxon_to_instances:foreach(function(taxon, instances_dict)
        local instances = instances_dict:keys()
        if ancestors[taxon] then
            ancestors[taxon]:foreach(function(ancestor)
                instances:foreach(function(instance)
                    if taxon_to_instances[ancestor] then
                        taxon_to_instances[ancestor][instance] = nil
                    end
                end)
            end)
        end
    end)
end

function _M.make_instances(taxon_to_instances, label_to_entity)
    local instances = Set()
    taxon_to_instances:foreach(function(taxon, taxon_instances_dict)
        instances:add(taxon_instances_dict:keys())
    end)
    
    instances = instances:vals()
    instances:foreach(function(instance)
        label_to_entity[instance].type = "instance"
    end)
    
    return instances
end

function _M.map_attributes(label_to_entity, connection_rows)
    connection_rows:foreach(function(row)
        local subject = row.subject
        local entity = label_to_entity[subject] or Dict()

        if entity then
            entity:default("attributes", Dict())
            local attribute_key = row.type or _M.conf.all_attribute_key
            entity.attributes:default(attribute_key, List())
            entity.attributes[attribute_key]:append(row.object)
        end
    end)
end

function _M.make_instance_to_taxon_map(rows, label_to_entity, path)
    local map = _M.map_subject_to_object(rows)
    
    if path then
        path = path:is_dir() and path or path:parent()

        map = map:filterk(function(label)
            return label_to_entity[label].path:is_relative_to(path)
        end)
    end
    
    return map
end

--[[
when we start here:
- we take an instance
- we follow its parent change, subbing in by taxon_to_instance_taxon
- and we add each of those to the tree
- that's it
]]
function _M.make_instance_taxonomy(taxonomy, taxon_to_instance_taxon, instance_to_taxon)
    local tree = Tree()
    local parents = taxonomy:parents()
    
    taxon_to_instance_taxon.abstract = "instance"
    
    instance_to_taxon:foreach(function(instance, taxon)
        local child = instance
        local parent = taxon

        while parent and child do
            parent = taxon_to_instance_taxon[parent] or parent
            tree:add_edge(parent, child)
            
            child = parent
            parent = parents[parent]
        end
    end)
    
    return tree
end

Taxonomy._M = _M

return Taxonomy
