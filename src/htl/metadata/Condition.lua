local Set = require("hl.Set")
local Config = require("htl.Config")
local Parser = require("htl.metadata.Parser")

local M = require("pl.class")()
M.conf = Conf.metadata

function M.filter(rows, conditions, taxonomy)
    M.taxonomy = taxonomy
    List(conditions):map(M.parse):foreach(function(condition)
        local _urls = Set(rows:filter(M.eval, condition):col('url'))

        rows = rows:filter(function(r)
            local result = _urls:has(r.url)
            if condition.is_exclusion then
                result = not result
            end

            return result
        end)
    end)

    return rows
end

function M.parse(str)
    local condition = Dict({
        startswith = Parser:is_tag(str),
        is_exclusion = Parser:is_exclusion(str),
    })

    str = Parser:clean_exclusion(str)

    condition.key, condition.vals = unpack(Parser:parse_field(str))

    if condition.vals then
        condition.vals = condition.vals:split(M.conf.or_delimiter)
    end

    if condition.key == M.conf.is_a_key then
        condition.vals = M.add_taxonomy_vals(condition.vals)
    end
    
    return condition
end

function M.eval(row, condition)
    local result = row.key == condition.key

    if condition.startswith then
        result = row.key:startswith(condition.key)
    end

    if condition.vals then
        result = result and condition.vals:contains(row.val)
    end

    return result
end

function M.add_taxonomy_vals(vals)
    vals = Set(vals)
    local descendants = M.taxonomy:descendants()
    local taxonomy_vals = List()
    vals:foreach(function(val)
        taxonomy_vals:extend(descendants[val] or {})
    end)
    
    return vals:union(taxonomy_vals):vals()
end

return M
