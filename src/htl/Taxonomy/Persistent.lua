--[[
what to do first:
- get all urls for the project
- assign them to either instance or subset

]]

local M = class()
M.conf = Dict(Conf.Taxonomy)

function M:_init(path)
    local info = M.get_urls(path)
    
    self.element_id_to_label = info.element_id_to_label
    self.taxonomy = info.taxonomy
    self.taxon_instances = info.taxon_instances
    self.inheritances_by_type = info.inheritances_by_type
end

function M:get_seed_elements(elements, conditions)
    -- this is applied BEFORE we build the taxonomy.


    --[[
    conditions grammar:
    
    1. "x"
        Relations.relation = "connection"
        Relations.type = startswith(x)
    2. "x: y"
        Relations.relation = "connection"
        Relations.type = x
        Relations.object = y

    3. "x: file.md"
        Relations.relation = "connection"
        Relations.type = "x"
        Relations.object = Elements.id for file.md
    4. ": file.md"
        Relations.relation = "connection"
        Relations.object = Elements.id for file.md

    5. "@x"
        Relations.relation = "tag"
        Relations.type = startswith(X)
    ]]
end

function M.get_urls(path)
    local url_id_to_url = Dict.from_list(
        DB.urls:get({where = {resource_type = "file"}}),
        function(u) return u.id, u end
    )
    
    local seeds = List()
    local element_id_to_element = Dict()
    DB.Elements:get():foreach(function(e)
        e.url = url_id_to_url[e.url]

        if e.url then
            e.label = e.url.label

            if not path or path and e.url.path and e.url.path:is_relative_to(path) then
                seeds:append(e.id)
            end
        end

        element_id_to_element[e.id] = e
    end)
    
    local label_to_relations = DefaultDict(List)
    DB.Relations:get({
        where = {relation = {"instance", "subset", "instances_are_also"}}
    }):foreach(function(r)
        label_to_relations[element_id_to_element[r.subject].label]:append(r)
    end)
    
    local taxonomy = Tree()
    local taxon_instances = DefaultDict(Set)
    local instances_are_also = List()
    
    while #seeds > 0 do
        local subject_id = seeds:pop()
        local subject = element_id_to_element[subject_id].label
        
        if subject then
            label_to_relations:pop(subject):foreach(function(r)
                local object_element = element_id_to_element[r.object]
                
                local object = object_element and object_element.label

                if r.relation == "instance" then
                    taxon_instances[object]:add(subject_id)
                elseif r.relation == "subset" then
                    taxonomy:add_edge(object, subject)
                else
                    instances_are_also:append({subject = subject, object = object})
                end
                
                seeds:append(r.object)
            end)
        end
    end
    
    -- apply inheritance
    local generations = taxonomy:generations()
    local descendants = taxonomy:descendants()
    local ancestors = taxonomy:ancestors()
    instances_are_also:sorted(function(a, b)
        return generations[a.object] < generations[b.object]
    end):foreach(function(r)
        local instances = Set(taxon_instances[r.subject])
        descendants[r.subject]:foreach(function(s) instances:add(taxon_instances[s]) end)

        taxon_instances[r.object]:add(instances)
        ancestors[r.object]:foreach(function(a) taxon_instances[a]:remove(instances) end)
    end)
    
    taxon_instances:transformv(function(instances)
        return Set(instances:vals():map(function(id) return element_id_to_element[id].label end))
    end)
    

    --[[
    Instances:
        url: url
        taxon: taxon label
        generation: 1 if parent, 2 if grandparent, etc
    ]]

    return {
        element_id_to_label = element_id_to_label,
        taxonomy = taxonomy,
        taxon_instances = taxon_instances,
        inheritances_by_type = inheritances_by_type,
    }
end

return M
