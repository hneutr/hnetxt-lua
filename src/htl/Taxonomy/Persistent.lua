--[[
what to do first:
- get all urls for the project
- assign them to either instance or subset

]]

local M = class()
M.conf = Dict(Conf.Taxonomy)

function M:_init(project)
    self.project = project
end

function M.get_urls(project)
    local urls_by_id = Dict.from_list(
        DB.urls:get({where = {project = project, resource_type = "file"}}),
        function(u) return u.id, Dict(u) end
    )

    local subset_labels = Set()

    local instance_rows = List()
    local subset_rows = List()

    DB.Relations:get({
        where = {relation = {"instance", "subset"}}
    }):filter(function(r)
        return urls_by_id[r.subject_url]
    end):foreach(function(r)
        local object = r.object_url or r.object_label
        local url = r.subject_url

        if r.relation == "instance" then
            instance_rows:append({url = url, parent = object})
        elseif r.relation == "subset" then
            local subset = Dict({parent = object})

            if r.subject_label then
                subset.label = r.subject_label
                subset_labels:add(r.subject_label)
            else
                subset.url = url
            end

            subset_rows:append(subset)
        end

        if r.object_label then
            subset_labels:add(r.object_label)
        end
    end)
        
    local subset_rows = DB.Relations:get({where = {relation = "subset"}}):filter(function(r)
        return urls_by_id[r.subject_url]
    end)
    
    --[[
    what is the situation?
    
    We have a bunch of instances.
    Each instance has a subset.
    This subset is either a string or a url.
    
    We want to get subset information for both of them.
    
    So, when we're looking at instances, we want to make a list of strings and urls we want to see
    
    PAUSE here
    
    Whenever we see a string, we want to find all Relation rows related to:
    - this project
    - the root project

    ]]
        
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


return M
