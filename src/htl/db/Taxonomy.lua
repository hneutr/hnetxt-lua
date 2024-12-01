local M = SqliteTable("Taxonomy", {
    id = true,
    url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    lineage = {
        type = "luatable",
        required = true,
    },
    type = {
        type = "text",
        required = true,
        default = "instance",
    },
})

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                     Row                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.Row = {}

function M.Row.tostring(row)
    row.lineage = List(row.lineage)
    return List({"url", "lineage", "type"}):map(function(c)
        return tostring(row[c])
    end):join(":")
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  staleness                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.staleness = {}

function M.staleness.get_query()
    if not M.staleness.query then
        local id = DB.urls.get_file(Conf.paths.global_taxonomy_file).id
        M.staleness.query = {
            subject = id,
            predicate = "stale",
            source = id,
        }
    end

    return M.staleness.query
end

function M.staleness.set(rows_by_operation)
    rows_by_operation = rows_by_operation or {}
    M.staleness.clear()

    local rows = List(rows_by_operation.remove):extend(rows_by_operation.insert)
    local predicates = Set(rows:map(function(r) return r.predicate end))

    local overlaps = predicates * Set(Conf.Metadata.taxonomy_predicate)

    if #overlaps > 0 then
        DB.Metadata:insert(M.staleness.get_query())
    end
end

function M.staleness.clear()
    DB.Metadata:remove(M.staleness.get_query())
end

function M.staleness.get()
    return DB.Metadata:where(M.staleness.get_query())
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                            metadata to taxonomy                            --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.get_rows_from_metadata()
    local tree = Tree()

    DB.Metadata:get({
        where = {predicate = "subset"}
    }):foreach(function(row)
        tree:add_edge(row.object, row.subject)
    end)

    local lineages = tree:lineages()

    local rows = lineages:keys():map(function(id)
        return {url = id, lineage = lineages[id], type = "subset"}
    end)

    local instance_subsets = Dict():set_default(List)

    DB.Metadata:get({
        where = {predicate = "instances are a"}
    }):foreach(function(row)
        instance_subsets[row.subject]:append(row.object)
    end)

    -- should implement recursive inclusion of `instances are a`
    tree:nodes():foreach(function(n) instance_subsets[n]:append(n) end)
    instance_subsets:transformv(function(v) return v:unique() end)

    DB.Metadata:get({
        where = {predicate = "instance"}
    }):foreach(function(row)
        rows:extend(instance_subsets[row.object]:map(function(subset)
            return {url = row.subject, lineage = List(lineages[subset]):append(row.subject)}
        end))
    end)

    return rows
end

function M.refresh()
    if M.staleness.get() then
        M:remove()
        M.staleness.clear()
    end

    if M:empty() then
        local rows = M.get_rows_from_metadata()

        if #rows > 0 then
            M:insert(rows)
        end
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                     db                                     --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:get(q)
    M.refresh()

    return List(M:__get(q))
end

return M
