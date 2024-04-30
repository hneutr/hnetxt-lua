--[[
what to do first:
- get all urls for the project
- assign them to either instance or subset

]]

local M = class()
M.conf = Dict(Conf.Taxonomy)

function M:_init(project)
    self.project = project
    local info = M.get_urls(project)
    
    self.element_id_to_label = info.element_id_to_label
    self.taxonomy = info.taxonomy
    self.taxon_instances = info.taxon_instances
    self.inheritances_by_type = info.inheritances_by_type
end

function M.get_urls(project)
    local url_id_to_label = Dict.from_list(
        DB.urls:get({where = {resource_type = "file"}}),
        function(u) return u.id, DB.urls:get_label(u) end
    )
    
    local element_id_to_label = Dict()
    local seeds = List()

    DB.Elements:get():foreach(function(e)
        local label = e.label
        if e.url then
            label = url_id_to_label[e.url]
            if e.project == project then
                -- seeds:append(label)
                seeds:append(e.id)
            end
        end

        element_id_to_label[e.id] = label
    end)
    
    local label_to_relations = DefaultDict(List)
    DB.Relations:get({
        where = {relation = {"instance", "subset", "give_instances"}}
    }):foreach(function(r)
        label_to_relations[element_id_to_label[r.subject]]:append(r)
    end)
    
    local taxonomy = Tree()
    local taxon_instances = DefaultDict(Set)
    local inheritances_by_type = DefaultDict(List)
    
    local to_check = seeds:clone()
    while #to_check > 0 do
        local subject_id = to_check:pop()
        local subject = element_id_to_label[subject_id]
        
        if subject then
            label_to_relations:pop(subject):foreach(function(r)
                local object = element_id_to_label[r.object]

                if r.relation == "instance" then
                    if object then
                        taxon_instances[object]:add(subject_id)
                    end
                elseif r.relation == "subset" then
                    taxonomy:add_edge(object, subject)
                else
                    inheritances_by_type[r.type]:append({subject = subject, object = object})
                end
                
                to_check:append(r.object)
            end)
        end
    end
    
    -- apply inheritance
    local generations = taxonomy:generations()
    local descendants = taxonomy:descendants()
    local ancestors = taxonomy:ancestors()
    inheritances_by_type:pop("instance"):sorted(function(a, b)
        return generations[a.object] < generations[b.object]
    end):foreach(function(r)
        local instances = Set(taxon_instances[r.subject])
        descendants[r.subject]:foreach(function(s) instances:add(taxon_instances[s]) end)

        taxon_instances[r.object]:add(instances)
        ancestors[r.object]:foreach(function(a) taxon_instances[a]:remove(instances) end)
    end)
    
    --[[
    all that's left to do at this point is:
    - set up:
        - db.Taxa
        - db.Instances

        - db.References
        - db.Attributes
        - db.Tags

    ]]
    

    --[[
    TaxonomySeeds:
        url: url
        taxon: taxon label
        generation: 1 if parent, 2 if grandparent, etc
        type: instance|taxon
        project:

    We're going to use the Taxonomy tree thing for the printer. It's just simpler that way.
    
    The Seed table described above is for Snippet/dashboard/x_of_the_day.

    ]]

    -- `References`:
    --   subject: url.id (referencing url)
    --   object: url.id (referenced url)
    --   type: `Relation.type`
    --   project:
    -- `Attributes`: attributes
    --   url: url.id
    --   type: `Relation.type`
    --   val: string
    --   project:
    -- `Tags`:
    --   url: url.id
    --   val: string
    --   project:

    -- print(taxon_instances)
    -- print(taxonomy)

    return {
        element_id_to_label = element_id_to_label,
        taxonomy = taxonomy,
        taxon_instances = taxon_instances,
        inheritances_by_type = inheritances_by_type,
    }
end

return M
