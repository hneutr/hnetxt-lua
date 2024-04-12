local List = require("hl.List")

local Config = require("htl.Config")

local M = require("sqlite.tbl")("Taxa", {
    id = true,
    url = "integer",
    key = "text",
    project = {
        type = "text",
        reference = "projects.title",
        on_delete = "cascade",
    },
})

function M:get(q)
    return List(M:__get(q))
end

function M:where(q)
    q = q or {}
    
    if q.url then
        if not q.project or DB.urls:where({id = q.url, project = q.project}) then
            return M:__where({url = q.url})
        end
    elseif q.key then
        local r
        if q.project then
            r = M:__where({key = q.key, project = q.project})

            if not r then
                local rs = M:get({where = {key = q.key}}):filter(function(r) return r.project == nil end)
                
                if #rs > 0 then
                    r = rs[1]
                end
            end
        else
            local rs = M:get({where = {key = q.key}})

            rs = rs:filter(function(r) return r.project == nil end)

            if #rs > 0 then
                r = rs[1]
            end
        end
    
        return r
    end
end

function M:find(element, project)
    local _type = type(element)

    local q
    if _type == "number" then
        q = {url = element}
    elseif _type == "string" then
        q = {key = element, project = project}
    end

    local taxon

    if q then
        taxon = M:where(q)
        if not taxon then
            M:insert(q)
            taxon = M:where(q)
        end
    end
        
    return taxon
end

return M
