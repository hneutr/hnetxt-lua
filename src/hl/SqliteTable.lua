local Set = require("hl.Set")
local List = require("hl.List")
local Dict = require("hl.Dict")

local M = require("sqlite.tbl")

function M.group_rows_by_operation(rows_by_age, row_string_fn)
    rows_by_age = rows_by_age or {}

    local age_keys = Dict():set_default(List)
    for age in List({"old", "new"}):iter() do
        age_keys[age] = List(rows_by_age[age]):map(row_string_fn)
    end

    return Dict({
        keep = {"new", "old", operation = Set.intersection},
        remove = {"old", "new", operation = Set.difference},
        insert = {"new", "old", operation = Set.difference},
    }):transformv(function(d)
        return d.operation(
            Set(age_keys[d[1]]),
            Set(age_keys[d[2]])
        ):vals():map(function(key)
            return age_keys[d[1]]:index(key)
        end):sort():map(function(index)
            return rows_by_age[d[1]][index]
        end)
    end):filterv(function(rows) return #rows > 0 end)
end

function M.apply(tbl, rows_by_age, row_string_fn)
    local rows_by_operation = M.group_rows_by_operation(rows_by_age, row_string_fn)

    if rows_by_operation.remove then
        tbl:remove({id = rows_by_operation.remove:col('id')})
    end

    if rows_by_operation.insert then
        tbl:insert(rows_by_operation.insert)
    end
end

return M
