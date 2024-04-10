local Taxa = require("htl.db.Taxa")

local M = require("sqlite.tbl")("Relations", {
    id = true,
    subject = {
        type = "integer",
        reference = "Taxa.id",
        on_delete = "cascade",
        required = true,
    },
    object = {
        type = "integer",
        reference = "Taxa.id",
        on_delete = "cascade",
        required = true,
    },
    relation = {
        type = "text",
        required = true,
    },
})

function M:insert(r, project)
    local row = {relation = r.relation}
    List({"subject", "object"}):foreach(function(col)
        local col_taxa = Taxa:find(r[col], project) or {}
        row[col] = col_taxa.id
    end)
    
    M:__insert(row)
end
      
return M
