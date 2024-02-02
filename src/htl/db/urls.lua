local Dict = require("hl.Dict")
local List = require("hl.List")
local sqlite = require("sqlite.db")
local projects = require("htl.db.projects")
local tbl = require("sqlite.tbl")

local M = tbl("urls", {
    id = true,
    label = "text",
    project = {
        type = "text",
        reference = "projects.title",
        on_delete = "cascade", --- delete if project gets deleted
    },
    path = {"text", required = true},
})

M.uuid = uuid

function M:insert(row)
    row = Dict.from({}, row)

    if row.path ~= nil then
        row.path = tostring(row.path)
    end

    if not row.project then
        row.project = projects.get_title(row.path)
    end

    M:__insert(row)
end

function M:where(q)
    if q.path then
        q.path = tostring(q.path)
    end

    return M:__where(q)
end

function M:move(source, target)
    M:update({
        where = {path = source},
        set = {path = tostring(target)},
    })
end

function M:get(q)
    return List(M:map(function(url)
        url.path = Path(url.path)

        if url.label == nil then
            url.label = url.path:stem():gsub("-", " ")
        end

        return url
    end, q))
end

function M:add_if_missing(path)
    if not M:where({path = path}) then
        M:insert({path = path})
    end
end

function M:clean()
    local ids_to_delete =  M:get():filter(function(url)
        return not url.path:exists()
    end):transform(function(url)
        return url.id
    end)

    if #ids_to_delete > 0 then
        M:remove({id = ids_to_delete})
    end
end

return M
