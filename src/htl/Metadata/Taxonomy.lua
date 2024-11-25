local M = class()

function M:_init(args)
    local urls_by_id = Dict()

    DB.urls:get({where = {type = {"file", "taxonomy_entry"}}}):foreach(function(u)
        urls_by_id[u.id] = u
    end)

    local taxonomy, taxon_instances = M.get_taxonomy(seeds)

    taxonomy, taxon_instances = M.filter_taxa(
        taxonomy,
        taxon_instances,
        urls_by_id
    )

    return {
        taxonomy = taxonomy,
        taxon_instances = taxon_instances,
        urls_by_id = urls_by_id,
    }
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

return M
