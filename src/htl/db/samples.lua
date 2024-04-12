local Config = require("htl.Config")

local Snippet = require("htl.snippet")

local M = require("sqlite.tbl")("samples", {
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

M.conf = Dict(Conf['x-of-the-day'])

function M:set(args)
    if args.rerun then
        M:remove({date = args.date})
    end
    
    M.conf:foreach(function(frame, cmd)
        if not M:where({date = args.date, frame = frame}) then
            cmd.path = Path(cmd.path)
            local ids = Set(DB.metadata:get_urls(cmd):filter(function(u) return u.url end):col('url')):vals()
            local url = DB.urls:where({id = ids[utils.randint({max = #ids})]})
            M:insert({
                date = args.date,
                url = url.id,
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