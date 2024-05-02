local Taxonomy = require("htl.Taxonomy.Persistent")
local Snippet = require("htl.snippet")

local M = SqliteTable("samples", {
    id = true,
    date = {
        type = "text",
        default = [[strftime('%Y%m%d')]],
    },
    url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    frame = {
        type = "text",
        required = true,
    },
})

M.conf = Dict(Conf.samples)

function M:set(args)
    M.conf:foreach(function(frame, args)
        local ids = Set(Taxonomy(args).rows:col('url')):vals()

        M:insert({
            date = args.date,
            url = ids[utils.randint({max = #ids})],
            frame = frame,
        })
    end)
end

function M:get(...)
    return List(M:__get(...))
end

function M:save(args)
    local dir = Conf.paths.x_of_the_day_dir
    M:get({where = {date = args.date}}):foreach(function(sample)
        local path = dir / sample.frame / args.date
        local url = DB.urls:where({id = sample.url})
        path:write(tostring(Snippet(url.path)))
    end)
end

function M.run(args)
    M:set(args)
    M:save(args)
end

return M
