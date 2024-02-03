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
        on_delete = "cascade", -- delete if project gets deleted
    },
    path = {"text", required = true},
    created = {"date", required = true},
    resource_type = {"text", required = true},
})

M.uuid = uuid

function M:insert(row)
    local resource_type = row.resource_type

    if not resource_type then
        if row.label then
            resource_type = "link"
        else
            resource_type = "file"
        end
    end

    M:__insert({
        path = tostring(row.path),
        project = row.project or projects.get_title(row.path),
        created = sqlite.lib.strftime("%s", "now"),
        label = row.label,
        resource_type = resource_type,
    })
end

function M:add_if_missing(path)
    if not M:where({path = path, resource_type = 'file'}) then
        M:insert({path = path, resource_type = 'file'})
    end
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
