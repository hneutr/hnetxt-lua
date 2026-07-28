local M = SqliteTable("Paths", {
    key = {
        type = "text",
        required = true,
        primary = true,
    },
    val = {
        type = "text",
        required = true,
    },
})

function M:get(q)
    return List(M:__get(q))
end

function M:persist()
    M:replace(Conf.paths:keys():map(function(key)
        return {
            key = key,
            val = tostring(Conf.paths[key])
        }
    end))
end

return M
