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

M.predicates = Conf.Metadata.taxonomy_predicates

--------------------------------------------------------------------------------
--                                  staleness                                 --
--------------------------------------------------------------------------------
function M.is_stale()
    return #M:__get({type = "stale"}) > 0
end

function M.set_staleness(rows_by_age)
    if M.is_stale() then
        return
    end

    local elements_by_age = Dict():set_default(Set)
    Dict(rows_by_age):set_default(List):foreach(function(age, rows)
        rows:foreach(function(row)
            if M.predicates:contains(row.predicate) then
                elements_by_age[age]:add(DB.Metadata.Row.tostring(row))
            end
        end)
    end)

    if elements_by_age.old ~= elements_by_age.new then
        M:insert({
            url = DB.urls.get_file(Conf.paths.global_taxonomy_file).id,
            lineage = {},
            type = "stale"
        })
    end
end

function M.refresh()
    if M.is_stale() then
        M:remove()
    end

    if not M:empty() then
        return
    end

    local rows = M.get_rows_from_metadata()

    if #rows > 0 then
        M:insert(rows)
    end
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

    local instances = List()
    local instance_subsets = Dict():set_default(List)

    DB.Metadata:get({
        where = {predicate = {"subset", "instance", "instances are a"}}
    }):foreach(function(row)
        local predicate = row.predicate

        if predicate == "subset" then
            tree:add_edge(row.object, row.subject)
        elseif predicate == "instance" then
            instances:append(row)
            tree:add_edge(row.object)
        elseif predicate == "instances are a" then
            instance_subsets[row.subject]:append(row.object)
        end
    end)

    -- TODO: implement recursive inclusion of `instances are a`
    tree:nodes():foreach(function(n) instance_subsets[n]:append(n) end)
    instance_subsets:transformv(function(v) return v:unique() end)

    local lineages = tree:lineages()

    local rows = lineages:keys():map(function(id)
        return {url = id, lineage = lineages[id], type = "subset"}
    end)

    instances:foreach(function(row)
        rows:extend(instance_subsets[row.object]:map(function(subset)
            return {url = row.subject, lineage = List(lineages[subset]):append(row.subject)}
        end))
    end)

    return rows
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
    return List(M:__get(q)):transform(function(row) row.lineage = List(row.lineage) end)
end

return M
