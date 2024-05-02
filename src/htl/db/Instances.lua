local M = SqliteTable("Instances", {
    id = true,
    url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    taxon = {
        type = "string",
        required = true,
    },
    generation = {
        type = "integer",
        required = true,
    },
})

function M:get(q)
    return List(M:__get(q))
end

return M
