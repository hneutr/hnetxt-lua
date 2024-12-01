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

function M:get(q)
    return List(M:__get(q))
end

return M
