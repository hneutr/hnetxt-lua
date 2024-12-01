local M = Class()

M.conf = Conf.Metadata
M.source_path = Conf.paths.lineage_file

--------------------------------------------------------------------------------
--                                   caching                                  --
--------------------------------------------------------------------------------
function M.get_source()
    M.source = M.source or DB.urls.get_file(M.source_path)
    return M.source
end

function M.get_tree()
    if not M.tree then
        M.tree = Tree()
        DB.Metadata:get({
            where = {predicate = "subset"}
        }):foreach(function(r)
            M.tree:add_edge(r.object, r.subject)
        end)
    end

    return M.tree
end

M.stale = {}

function M.stale.get_query()
    if not M.stale.query then
        local id = M.get_source().id
        M.stale.query = {
            subject = id,
            predicate = "stale",
            source = id,
        }
    end

    return M.stale.query
end

function M.stale.set(rows_by_operation)
    rows_by_operation = rows_by_operation or {}
    M.stale.clear()

    local rows = List(rows_by_operation.remove):extend(rows_by_operation.insert)
    local predicates = Set(rows:map(function(r) return r.predicate end))

    local overlaps = predicates * Set(M.conf.taxonomy_predicate)

    local q = M.stale.get_query()
    if #overlaps > 0 or not DB.Metadata:where({source = q.source}) then
        DB.Metadata:insert(q)
    end
end

function M.stale.clear()
    DB.Metadata:remove(M.stale.get_query())
end

function M.stale.get()
    return DB.Metadata:where(M.stale.get_query())
end

--------------------------------------------------------------------------------
--                                 predicates                                 --
--------------------------------------------------------------------------------
M.predicate = {}
function M.predicate.format(ids, for_query)
    local str = for_query and "*.%s.*" or ".%s."
    return str:format(List.as_list(ids):map(tostring):join("."))
end

function M.predicate.parse(str)
    return str:split("."):filter(function(s) return #s > 0 end):map(tonumber)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  business                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.set(rows_by_operation)
    M.stale.set(rows_by_operation)

    local stale = M.stale.get()

    if stale then
        local rows = M.get_rows()
        rows:foreach(function(r) r.source = stale.source end)

        DB.Metadata.apply({
            new = rows,
            old = DB.Metadata:get({where = {source = stale.source}}):filter(function(r)
                return r.id ~= stale.id
            end),
        })

        M.stale.clear()
    end
end

function M.get_rows()
    local tree = M.get_tree()

    local lineages = tree:lineages()

    local rows = lineages:keys():map(function(id)
        return {
            subject = id,
            predicate = M.predicate.format(lineages[id]),
        }
    end)

    local instance_subsets = M.get_subset_to_instance_subsets()

    DB.Metadata:get({
        where = {predicate = "instance"}
    }):foreach(function(row)
        rows:extend(instance_subsets[row.object]:map(function(subset)
            return {
                subject = row.subject,
                predicate = M.predicate.format(lineages[subset]) .. row.subject,
            }
        end))
    end)

    return rows
end

function M.get_subset_to_instance_subsets()
    local map = Dict():set_default(List)

    DB.Metadata:get({
        where = {predicate = "instances are a"}
    }):foreach(function(row)
        map[row.subject]:append(row.object)
    end)

    -- maybe we do this later for recursive `instances are a`
    -- local checklist = map:keys()
    -- while #checklist > 0 do
    --     local subject = checklist:pop()
    --
    --     map[subject]:foreach(function(other)
    --         if not map[subject] < map[other] then
    --             map[other] = map[other] + map[subject]
    --             checklist:append(other)
    --         end
    --     end)
    -- end

    M.get_tree():nodes():foreach(function(n) map[n]:append(n) end)
    return map:transformv(function(v) return v:unique() end)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                     OLD                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local _M = class()

function _M:_init(args)
    local urls_by_id = Dict()

    DB.urls:get({where = {type = {"file", "taxonomy_entry"}}}):foreach(function(u)
        urls_by_id[u.id] = u
    end)

    local taxonomy, taxon_instances = _M.get_taxonomy(seeds)

    taxonomy, taxon_instances = _M.filter_taxa(
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

function _M.get_taxonomy(seeds)
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

function _M.filter_taxa(taxonomy, taxon_instances, urls_by_id, conditions)
    local nodes = taxonomy:nodes()

    local taxa = List()
    conditions:foreach(function(condition)
        if condition.predicate == "subset" then
            condition.object:foreach(function(object)
                local taxon = _M.taxa_object_to_url_id(object, nodes, urls_by_id)

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

function _M.taxa_object_to_url_id(object, taxa, urls_by_id)
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

-- return _M
return M
