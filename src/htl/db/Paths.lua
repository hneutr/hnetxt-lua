local M = require("sqlite.tbl")("Paths", {
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

function M:ingest()
    M:drop()
    
    local rows = Conf.paths:keys():map(function(key)
        return {key = key, val = tostring(Conf.paths[key])}
    end)

    M:insert(rows)
end

return M
