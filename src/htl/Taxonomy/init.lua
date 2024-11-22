local M = class()

function M:_init(args)
    args = args or {}
    local path = args.path and Path.from_cli(args.path) or nil
    local conditions = M.Condition.parse(args.conditions)
    local persist = not path and #conditions == 0

    local urls_by_id, seeds = M.get_urls(path, conditions)

    local taxonomy, taxon_instances = M.get_taxonomy(seeds)

    taxonomy, taxon_instances = M.filter_taxa(
        taxonomy,
        taxon_instances,
        urls_by_id,
        conditions
    )

    local rows = M.get_rows(urls_by_id, taxonomy, taxon_instances)

    if persist then
        DB.Instances:replace(rows)
    end

    return {
        taxonomy = taxonomy,
        taxon_instances = taxon_instances,
        seeds = seeds,
        conditions = conditions,
        urls_by_id = urls_by_id,
    }
end

function M.get_rows(urls_by_id, taxonomy, taxon_instances)
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

function M.get_urls(path, conditions)
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

    conditions:foreach(function(c) seeds = M.Condition.apply(c, seeds) end)

    return urls_by_id, seeds:vals()
end

function M.get_taxonomy(seeds)
    local subject_to_rows = Dict():set_default(List)

    DB.Metadata:get({
        where = {predicate = {"instance", "subset", "instances are a"}}
    }):foreach(function(r) subject_to_rows[r.subject]:append(r) end)

    local taxonomy = Tree()
    local taxon_instances = Dict():set_default(Set)
    local instances_are_a = List()

    seeds = seeds:clone()
    while #seeds > 0 do
        local subject = seeds:pop()

        subject_to_rows:pop(subject):foreach(function(r)
            local object = r.object

            if r.predicate == "instance" then
                taxon_instances[object]:add(subject)
            elseif r.predicate == "subset" then
                taxonomy:add_edge(object, subject)
            else
                instances_are_a:append({subject = subject, object = object})
            end

            seeds:append(object)
        end)
    end

    -- apply inheritance
    local generations = taxonomy:generations()
    local descendants = taxonomy:descendants()
    local ancestors = taxonomy:ancestors()
    instances_are_a:sorted(function(a, b)
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

function M.filter_taxa(taxonomy, taxon_instances, urls_by_id, conditions)
    local nodes = taxonomy:nodes()

    local taxa = List()
    conditions:foreach(function(condition)
        if condition.predicate == "subset" then
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
--                                  Condition                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.Condition = {}
M.Condition.symbols = List({
    {char = "#", name = "taxonomy"},
    {char = ":", name = "keyval"},
    {char = ",", name = "comma"},
    {char = "!", name = "exclude"},
    {char = "~", name = "recurse"},
})

function M.Condition.parse(raw)
    local conditions = List()
    raw:map(M.Condition.split):reduce(List.extend):foreach(M.Condition.add, conditions)
    return conditions
end

function M.Condition.get_symbol(str)
    for symbol in M.Condition.symbols:iter() do
        if str == symbol.char then
            return symbol
        end
    end
end

-- might want to filter this to avoid commas/colons after # and etc
-- but leaving it for now
function M.Condition.split(str)
    local pattern = ("[%s]"):format(M.Condition.symbols:col('char'):mapm("escape"))
    local parts = List()
    while #str > 0 do
        local index = str:find(pattern)
        parts:append(str:sub(1, index and math.max(index - 1, 1)))
        str = str:sub(#parts[#parts] + 1)
    end

    return parts
end

function M.Condition.parse_element(element)
    local path = Path.from_cli(element)
    local url = path:exists() and DB.urls:get_file(path)
    return url and url.id or element
end

function M.Condition.new()
    return Dict({
        predicate = List(),
        object = List(),
        predicate_object = List(),
        list_key = "predicate",
        behavior = "append",
    })
end

function M.Condition.add(part, conditions)
    local symbol = M.Condition.get_symbol(part)

    if symbol then
        M.Condition.add_symbol(symbol.name, conditions)
    else
        part = M.Condition.parse_element(part)
        local taxonomy_context = #conditions > 0 and conditions[#conditions].context == "taxonomy"

        if type(part) == "string" and taxonomy_context then
            part = DB.Metadata.Taxonomy.get_url(part)
        end

        M.Condition.add_element(part, conditions)
    end

    return conditions
end

function M.Condition.add_symbol(name, conditions)
    local fields

    if name == "taxonomy" then
        conditions:append(M.Condition.new())
        fields = {list_key = "object", predicate = List({"instance", "subset"}), context = "taxonomy"}
    elseif name == "recurse" or name == "exclude" then
        fields = {[name] = true, behavior = "new"}
    elseif name == "keyval" then
        fields = {list_key = "object", behavior = "append"}
    elseif name == "comma" then
        fields = {behavior = "append"}
    end

    local condition = #conditions > 0 and conditions[#conditions]
    if condition then
        Dict.foreach(fields, function(k, v) condition[k] = v end)
    end

    return conditions
end

function M.Condition.add_element(element, conditions)
    local is_url = type(element) == "number"
    local c = #conditions > 0 and conditions[#conditions]

    if not c or c.behavior ~= "append" or (is_url and c.list_key == "predicate") then
        c = M.Condition.new()
        conditions:append(c)
    end

    c.behavior = "new"

    if is_url then
        c.list_key = "object"
        c[c.list_key]:append(element)
    elseif c.list_key == "predicate" then
        c[c.list_key]:append(element)
    else
        local parts = #c.predicate == 0 and {element} or c.predicate:map(function(p)
            return p .. DB.Metadata.conf.subpredicate_sep .. element
        end)

        c.predicate_object:extend(parts)
    end

    return conditions
end

function M.Condition.query(c)
    local object = c.object or {}

    -- things get weird when we have both objects and predicate objects...
    -- for now we're just going to do one or the other
    local predicate_object = #object == 0 and c.predicate_object or {}
    local predicate = #predicate_object > 0 and predicate_object or c.predicate or {}

    local q = {}

    if #object > 0 then
        q.where = {object = object}
    end

    if #predicate > 0 then
        q.contains = {predicate = predicate:map(function(p) return p:gsub("%++", "*") end)}
    end

    return q
end

function M.Condition.get(c)
    local queries = List({M.Condition.query(c)})

    local rows = List()
    while #queries > 0 do
        local query = queries:pop()
        local subrows = DB.Metadata:get(query)

        if #subrows > 0 then
            rows:extend(subrows)

            if c.recurse then
                queries:append({where = {object = subrows:col('subject')}})
            end
        end
    end

    return rows
end

function M.Condition.apply(c, seeds)
    local Operation = c.exclude and Set.difference or Set.intersection
    return Operation(seeds, Set(M.Condition.get(c):col('subject')))
end

return M
