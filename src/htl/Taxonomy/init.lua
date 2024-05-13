local Parser = require("htl.Taxonomy.Parser")

local M = class()
M.conf = Dict(Conf.Taxonomy)

function M:_init(args)
    self:read_args(args)

    self.elements_by_id, self.seeds = self:get_elements(self.path, self.conditions)

    self.taxonomy, self.taxon_instances = M:get_taxonomy(self.seeds)

    self.taxonomy, self.taxon_instances = self:filter_taxa(
        self.elements_by_id,
        self.taxonomy,
        self.taxon_instances,
        self.conditions
    )

    self.rows = M:get_rows(self.elements_by_id, self.taxonomy, self.taxon_instances)

    if self.should_persist then
        DB.Instances:replace(self.rows)
    end
end

function M:read_args(args)
    args = Dict(args or {})
    self.conditions = M:transform_conditions(List(args.conditions))

    if args.path then
        self.path = Path.from_commandline(args.path)
    end

    self.should_persist = not List({
        self.path,
        #self.conditions > 0,
    }):any()
end

function M:get_rows(elements_by_id, taxonomy, taxon_instances)
    local ancestors = taxonomy:ancestors()
    local rows = List()
    taxon_instances:foreach(function(taxon_id, instance_ids)
        local urls = instance_ids:vals():transform(function(id) return elements_by_id[id].url.id end)
        local taxa = ancestors[taxon_id]:put(taxon_id):map(function(id) return elements_by_id[id].label end)

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

function M:get_printable_taxon_instances()
    local taxon_instances = DefaultDict(Set)
    self.taxon_instances:foreach(function(taxon_id, instance_ids)
        local taxon = self.elements_by_id[taxon_id].label
        instance_ids:foreach(function(instance_id)
            taxon_instances[taxon]:add(self.elements_by_id[instance_id].label)
        end)
    end)

    return taxon_instances
end

function M:get_elements(path, conditions)
    local urls_by_id = Dict.from_list(
        DB.urls:get({where = {resource_type = "file"}}),
        function(u) return u.id, u end
    )

    local seeds = Set()
    local elements_by_id = Dict()
    DB.Elements:get():foreach(function(e)
        e.url = urls_by_id[e.url]

        if e.url then
            e.label = e.url.label

            if not path or path and e.url.path and e.url.path:is_relative_to(path) then
                seeds:add(e.id)
            end
        end

        elements_by_id[e.id] = e
    end)

    return elements_by_id, self:apply_conditions(seeds, conditions):vals()
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

function M:filter_taxa(elements_by_id, taxonomy, taxon_instances, conditions)
    local taxon_strings = Set()

    conditions:foreach(function(condition)
        if condition.relation == "subset" then
            taxon_strings:add(condition.type)
        end
    end)

    if #taxon_strings:vals() == 0 then
        return taxonomy, taxon_instances
    end

    local taxa = List()
    local nodes = taxonomy:nodes()

    local descendants = taxonomy:descendants()
    local generations = taxonomy:generations()

    local clean_taxonomy = Tree()

    nodes:sorted(function(a, b)
        return (generations[a] or 0) < (generations[b] or 0)
    end):foreach(function(taxon)
        if taxon_strings:has(elements_by_id[taxon].label) then
            taxa:append(taxon)
            taxa:extend(descendants[taxon])
        end
    end)

    taxa:foreach(function(t)
        if not clean_taxonomy:get(t) then
            clean_taxonomy[t] = taxonomy:get(t)
        end
    end)

    taxa = Set(taxa)

    Set(nodes):difference(taxa):foreach(function(t)
        taxon_instances:pop(t)
        clean_taxonomy:pop(t)
    end)

    return clean_taxonomy, taxon_instances
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
    local q = {
        where = {
            relation = c.relation,
        },
    }

    if c.type and #c.type > 0 then
        q = M.add_condition_type_to_query(c, q)
    end

    local objects = List()
    objects:append(c.object or {})

    local rows = List()
    while #objects > 0 do
        local object = objects:pop()
        q.where.object = #object > 0 and object or nil

        local subrows = DB.Relations:get(q)
        rows:extend(subrows)

        if c.is_recursive then
            objects:append(subrows:col('subject'))
        end
    end

    return rows
end

function M.add_condition_type_to_query(c, q)
    local type = c.type

    if c.relation == "tag" then
        type = string.format("%s*", type)
    else
        if type:startswith("+") then
            type = string.format("*%s", type:removeprefix("+"))
        end

        if type:endswith("+") then
            type = string.format("%s*", type:removesuffix("+"))
        end
    end

    if type:match("%*") then
        q.contains = q.contains or {}
        q.contains.type = type
    else
        q.where = q.where or {}
        q.where.type = type
    end

    return q
end

function M:transform_conditions(conditions)
    conditions:transform(M.clean_condition)
    conditions = M.merge_conditions(conditions)
    conditions:transform(M.parse_condition)
    conditions:foreach(function(c)
        if c.object then
            c.object = c.object:transform(M.parse_condition_value_into_element)
        end
    end)

    return conditions
end

function M.parse_condition(s)
    local c = Dict({relation = "connection"})

    s, c.is_exclusion = s:removesuffix(M.conf.grammar.exclusion_suffix)

    if s:startswith(M.conf.grammar.taxon_prefix) then
        c.relation = "subset"
        c.type = s:removeprefix(M.conf.grammar.taxon_prefix)
        return c
    end

    local n_replaced
    s, n_replaced = s:gsub(M.conf.grammar.recursive, ":")

    c.is_recursive = n_replaced > 0

    c.type, c.object = utils.parsekv(s)

    if c.object then
        c.object = c.object:split(",")
    end

    if M.TagRelation:line_is_a(c.type) then
        c.type = M.TagRelation:clean(c.type)
        c.relation = "tag"
    end

    return c
end

function M.merge_conditions(conditions)
    local start_chars = List({":", ",", "-"})
    local end_chars = List({":", ","})
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
    c = c:gsub("%s*%-", "%-")
    return c:strip()
end

function M.parse_condition_value_into_element(c)
    local path = Path.from_commandline(c)

    if path:exists() then
        local url = DB.urls:get_file(path)
        c = url and url.id or tostring(path)
    end

    local q = {}
    if type(c) == "number" then
        q.url = c
    elseif type(c) == "string" then
        q.label = c
    end

    local element = DB.Elements:where(q)
    return element and element.id
end


return M
