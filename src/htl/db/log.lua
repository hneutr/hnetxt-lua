local Date = require("pl.Date")

local M = SqliteTable("Log", {
    id = true,
    key = {
        "text",
        required = true,
    },
    val = {
        "text",
        required = true,
    },
    date = {
        type = "date",
        default = [[strftime('%Y%m%d')]],
        required = true,
    },
})

M.conf = Conf.Log
M.conf.entry_dir = Conf.paths.track_dir
M.conf.date_fmt = Date.Format("yyyymmdd")

function M:get(q)
    return List(M:__get(q))
end

function M:should_delete(date_str)
    local today = M.conf.date_fmt:parse(os.date("%Y%m%d"))
    local date = M.conf.date_fmt:parse(date_str)

    return today:add({day = -1 * M.conf.days_before_delete}) > date
end

function M:parse_lines(lines, date)
    return lines:transform(M.parse_line, date):filter(function(r)
        return r.key and r.val
    end)
end

function M.parse_line(l, date)
    local row = {date = date}

    if #l > 0 then
        row.key, row.val = utils.parsekv(l)
    end

    return row
end

function M.get_lines(date)
    local key_to_val = Dict.from_list(
        DB.Log:get({where = {date = date}}),
        function(r) return r.key, string.format("%s: %s", r.key, r.val) end
    )

    return Conf.paths.to_track_file:readlines():transform(function(l)
        local k, _ = utils.parsekv(l)
        return key_to_val[k] or l
    end)
end

function M.record(path)
    local date = path:stem()
    M:remove({date = date})

    local rows = M:parse_lines(path:readlines(), date)

    if #rows > 0 then
        M:insert(rows)
    end
end

function M.clean(path)
    if M:should_delete(path:stem()) then
        path:unlink()
    end
end

function M:persist()
    Conf.paths.track_dir:iterdir({dirs = false, recursive = false}):foreach(function(path)
        M.record(path)
        M.clean(path)
    end)
end

--------------------------------------------------------------------------------
--                                UI functions                                --
--------------------------------------------------------------------------------
function M.touch(args)
    M:persist()
    args = Dict(args or {}, {date = os.date("%Y%m%d")})
    local path = Conf.paths.track_dir / string.format("%s.md", args.date)

    if not path:exists() then
        path:write(M.get_lines(args.date))
    end

    return path
end

M.ui = {
    cli = function(args) print(M.touch(args)) end,
    cmd = function() M.touch():open() end,
}

return M
