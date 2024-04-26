local lyaml = require("lyaml")

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
_M.conf.entity_type_map = Dict({
    subset = {subject = "subset", object = "subset"},
    instance = {subject = "instance", object = "subset"},
    connection = {object = "attribute"},
    give_instances = {subject = "subset"},
    tag = {subject = "instance", object = "tag"},
})

_M.Printer = require("htl.Taxonomy.Printer")

function _M:_init(path)
    self.projects = self.get_projects(path)
    
    self.rows = self.get_rows(self.projects)

    self.label_to_entity = self.get_label_map(self.rows)

    self.rows_by_relation = self.get_rows_by_relation(self.rows, self.label_to_entity, self.projects)
    
    self.taxonomy = self.make_taxonomy(self.rows_by_relation.subset, self.label_to_entity)
    
    self.taxon_to_instances = self.map_instances_to_taxa(self.rows_by_relation.instance)
    
    self.apply_inheritence(
        self.taxonomy,
        self.rows_by_relation.give_instances,
        self.taxon_to_instances,
        self.rows_by_relation.connection
    )
    
    self.map_attributes(
        self.label_to_entity,
        self.rows_by_relation.connection
    )
end

function _M:trim_for_relevance(path, include_instances)
    local relevant_instances = Set()
    local relevant_subsets = Set()
    self.label_to_entity:foreach(function(label, entity)
        if entity.path and entity.path:is_relative_to(path) then
            if entity.type == "instance" then
                relevant_instances:add(label)
            elseif entity.type == "subset" then
                relevant_subsets:add(label)
            end
        end
    end)
    
    self.taxon_to_instances:transformv(function(instances)
        return instances:filterk(function(k) return relevant_instances:has(k) end)
    end):filterk(function(taxon)
        return #self.taxon_to_instances[taxon]:keys() > 0
    end)
    
    relevant_subsets:add(self.taxon_to_instances:keys())

    local ancestors = self.taxonomy:ancestors()
    relevant_subsets:foreach(function(subset)
        relevant_subsets:add(ancestors[subset])
    end)
    
    Set(self.taxonomy:nodes()):difference(relevant_subsets):foreach(function(subset_to_remove)
        self.taxonomy:pop(subset_to_remove)
    end)
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
    
    List({"id", "path", "label", "project"}):foreach(function(k) entity[k] = url[k] end)
    
    entity.label = _M.get_label(row[fmt:format(role, "label")], url)
    entity.from_taxonomy = url.path and Taxonomy.Parser.is_taxonomy_file(url.path) or false
    entity.type = _M.get_entity_type(row, role)

    return entity
end

function _M.get_entity_type(row, role)
    row = row or {}
    local role_to_type = _M.conf.entity_type_map[row.relation] or {}
    return role_to_type[role]
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
            local entity = row[role]

            if entity then
                local priority = _M.get_priority(role, row.relation)
                while #labels_by_priority < priority do
                    labels_by_priority:append(Dict())
                end
                
                labels_by_priority[priority][entity.label] = entity
            end
        end)
    end)
    
    local map = Dict()
    while #labels_by_priority > 0 do
        map = map:update(labels_by_priority:pop())
    end
    return map
end

function _M.get_rows_by_relation(rows, label_to_entity, projects)
    local rows_by_relation = Dict()
    rows:foreach(function(row)
        rows_by_relation:default(row.relation, List())
        
        rows_by_relation[row.relation]:append({
            subject = row.subject.label,
            object = row.object.label,
            type = row.type,
        })
    end)
    
    if #projects > 1 then
        local primary_project = projects[#projects]
        rows_by_relation.instance = rows_by_relation.instance:filter(function(r)
            local project = label_to_entity[r.subject].project
            return project and project == primary_project
        end)
    end
    
    return rows_by_relation
end

function _M.map_subject_to_object(rows)
    return Dict.from_list(rows or List(), function(row) return row.subject, row.object end)
end

function _M.make_taxonomy(rows, label_to_entity)
    local tree = Tree()
    rows:foreach(function(row)
        tree:add_edge(row.object or tree:parents()[row.subject], row.subject)
    end)
    
    local nodes = Set(tree:nodes())
    local subset_entities = label_to_entity:keys():filter(function(label)
        return label_to_entity[label].type == "subset"
    end)
    
    Set(subset_entities):difference(nodes):vals():foreach(function(label)
        tree[label] = Tree()
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

Taxonomy._M = _M

return Taxonomy
