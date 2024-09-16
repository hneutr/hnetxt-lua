local Parser = require("htl.Taxonomy.Parser")

local M = class()
M.conf = Dict(Conf.Taxonomy)

function M:_init(args)
    self:read_args(args)

    self.urls_by_id, self.seeds = self:get_urls(self.path, self.conditions)
    
    self.taxonomy, self.taxon_instances = M:get_taxonomy(self.seeds)

    self.taxonomy, self.taxon_instances = self:filter_taxa(
        self.taxonomy,
        self.taxon_instances,
        self.urls_by_id,
        self.conditions
    )
    
    self.rows = M:get_rows(self.urls_by_id, self.taxonomy, self.taxon_instances)

    if self.should_persist then
        DB.Instances:replace(self.rows)
    end
end

function M:read_args(args)
    args = Dict(args or {})

    if args.path then
        self.path = Path.from_commandline(args.path)
    end

    self.conditions = M:transform_conditions(List(args.conditions))
    
    self.should_persist = not self.path and #self.conditions == 0
end

function M:get_rows(urls_by_id, taxonomy, taxon_instances)
    local ancestors = taxonomy:ancestors()
    local rows = List()
    taxon_instances:foreach(function(taxon_id, urls)
        local taxa = ancestors[taxon_id]:put(taxon_id):map(function(id) return urls_by_id[id].label end)

        for generation, taxon in ipairs(taxa) do
            urls:foreach(function(url)
                rows:append({
                    url = url,
                    taxon = taxon,
                    generation = generation,
                })
            end)
        end
    end)

    return rows
end

function M:get_urls(path, conditions)
    local urls_by_id = Dict()
    local seeds = Set()
    
    DB.urls:get({where = {type = {"file", "taxonomy_entry"}}}):foreach(function(u)
        if u.type == "file" then
            if not path or u.path:is_relative_to(path) then
                seeds:add(u.id)
            end
        end
        
        urls_by_id[u.id] = u
    end)

    return urls_by_id, self:apply_conditions(seeds, conditions):vals()
end

function M:get_taxonomy(seeds)
    local relations_by_subject = DefaultDict(List)

    DB.Relations:get({
        where = {relation = {"instance", "subset", "instances_are_also"}}
    }):foreach(function(r)
        relations_by_subject[r.subject]:append(r)
    end)
    
    local taxonomy = Tree()
    local taxon_instances = DefaultDict(Set)
    local instances_are_also = List()

    seeds = seeds:clone()
    while #seeds > 0 do
        local subject = seeds:pop()

        relations_by_subject:pop(subject):foreach(function(r)
            local object = r.object

            if r.relation == "instance" then
                taxon_instances[object]:add(subject)
            elseif r.relation == "subset" then
                taxonomy:add_edge(object, subject)
            else
                instances_are_also:append({subject = subject, object = object})
            end

            seeds:append(object)
        end)
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

    Set(taxon_instances:keys()):difference(Set(taxonomy:nodes())):foreach(function(t)
        taxonomy:add_edge(nil, t)
    end)

    return taxonomy, taxon_instances
end

function M.taxa_object_to_url_id(object, taxa, urls_by_id)
    if type(object) == "number" then
        return object
    end
    
    for id in taxa:iter() do
        if urls_by_id[id].label == object then
            return id
        end
    end
    
    return
end

function M:filter_taxa(taxonomy, taxon_instances, urls_by_id, conditions)
    local nodes = taxonomy:nodes()

    local taxa = List()
    conditions:foreach(function(condition)
        if condition.relation == "subset" then
            condition.object:foreach(function(object)
                local taxon = M.taxa_object_to_url_id(object, nodes, urls_by_id)

                if condition.is_exclusion then
                    taxonomy:pop(taxon)
                elseif taxon then
                    taxa:append(taxon)
                end
            end)
        end
    end)
    
    if #taxa == 0 then
        return taxonomy, taxon_instances
    end

    local generations = taxonomy:generations()

    local clean_taxonomy = Tree()
    taxa:sorted(function(a, b)
        return generations[a] < generations[b]
    end):foreach(function(t)
        if not clean_taxonomy:get(t) then
            clean_taxonomy[t] = taxonomy:get(t)
        end
    end)
    
    taxonomy = clean_taxonomy

    local nodes = Set(taxonomy:nodes())
    taxon_instances:filterk(function(t) return nodes:has(t) end)

    return taxonomy, taxon_instances
end
--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 Conditions                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.TagRelation = Parser.TagRelation

function M:apply_conditions(seeds, conditions)
    conditions:foreach(function(condition)
        if condition.relation ~= "subset" then
            seeds = self.apply_condition(seeds, condition)
        end
    end)

    return seeds
end

function M.apply_condition(seeds, c)
    local Operation = c.is_exclusion and Set.difference or Set.intersection
    return Operation(seeds, Set(M.get_condition_rows(c):col('subject')))
end

function M.get_condition_rows(c)
    local q = M.get_condition_query(c)

    local objects = List()
    objects:append(c.object or {})

    local rows = List()
    while #objects > 0 do
        local object = objects:pop()
        q.where.object = #object > 0 and object or nil
        
        local subrows = DB.Relations:get(q)
        rows:extend(subrows)

        if c.is_recursive then
            local object = subrows:col('subject')
            
            if #object > 0 then
                objects:append(object)
            end
        end
    end

    return rows
end

function M.get_condition_query(c)
    local relation = c.relation
    local key = c.key or ""

    local q = {
        where = {
            relation = relation,
        }
    }
    
    local relations = List({"tag", "connection"})
    
    if relations:contains(relation) then
        -- TODO: this is janky; we should probably get rid of the `connection` type entirely
        -- but...
        -- what this does is make it so that if there's no key, we'll look for both tags and connections
        if key == "" then
            q.where.relation = relations
        elseif relation == "tag" and key then
            q.contains = {key = key:map(function(v) return string.format("%s*", v) end)}
        elseif relation == "connection" and #key > 0 then
            local contains = false

            if key:startswith("+") then
                contains = true
                key = string.format("*%s", key:removeprefix("+"))
            end

            if c.type and c.type:endswith("+") then
                contains = true
                key = string.format("%s*", key:removesuffix("+"))
            end

            if contains then
                q.contains = {key = key}
            else
                q.where.key = key
            end
        end

    end

    if c.val and #c.val > 0 then
        q.where.val = c.val
    end
    
    return q
end

function M:transform_conditions(conditions)
    conditions:transform(M.clean_condition)
    conditions = M.merge_conditions(conditions)
    conditions:transform(Parser.parse_condition)
    
    return conditions
end

function M.merge_conditions(conditions)
    local start_chars = List({":", ",", "-"})
    local end_chars = List({":", ",", "#", "@"})
    local cant_start_chars = Set({",", "-"})

    local startswith = function(c) return start_chars:map(function(s) return c:startswith(s) end):any() end
    local endswith = function(c) return end_chars:map(function(e) return c:endswith(e) end):any() end

    local merged = List()
    while #conditions > 0 do
        local c = conditions:pop(1)
        while startswith(c) and #merged > 0 do
            c = merged:pop() .. c
        end

        while endswith(c) and #conditions > 0 do
            c = c .. conditions:pop(1)
        end

        merged:append(c)
    end

    merged:transform(string.rstrip, end_chars)

    return merged:filter(function(c) return not cant_start_chars:has(c:sub(1, 1)) end)
end

function M.clean_condition(c)
    c = c:gsub("  ", " ")
    c = c:gsub("%s*:%s*", ":")
    c = c:gsub("%s*,%s*", ",")
    c = c:gsub("%s*#%s*", "#")
    c = c:gsub("%s*%-", "%-")
    return c:strip()
end

return M
