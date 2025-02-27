local Conditions = require("htl.Metadata.Conditions")
local Snippet = require("htl.Snippet")

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

function M:set(args)
    if args.rerun then
        M:remove({date = args.date})
    end

    Conf.samples:foreach(function(frame, cmd_args)
        if not M:where({date = args.date, frame = frame}) then
            local ids = Conditions:new(cmd_args).urls

            M:insert({
                date = args.date,
                url = ids[math.randint({max = #ids})],
                frame = frame,
            })
        end

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
