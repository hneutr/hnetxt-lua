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
