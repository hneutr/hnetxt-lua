local Divider = require("htl.text.divider")
local Link = require("htl.text.Link")

local mirrors = require("htl.db.mirrors")

local M = class()

local function get_conf()
    local c = Dict(Conf.metadata)
    c.metadata_dividers = List({
        "",
        tostring(Divider("large", "metadata"))
    })

    return c
end

M.conf = get_conf()

function M:get(path)
    return M:parse(M:get_metadata_lines(path))
end

function M:get_metadata_lines(source)
    local lines = M:separate_metadata(source:readlines())
    local metadata_path = mirrors:get_path(source, "metadata")

    if metadata_path:exists() then
        lines:extend(metadata_path:readlines())
    end

    return lines:filter(function(line) return #line > 0 end)
end

function M:is_tag(l) return l and l:strip():startswith(M.conf.tag_prefix) and true or false end
function M:is_field(l) return l and l:match(M.conf.field_delimiter) and true or false end
function M:is_exclusion(l) return l and l:strip():endswith(M.conf.exclusion_suffix) and true or false end

function M:clean_exclusion(l) return l and l:removesuffix(M.conf.exclusion_suffix) or "" end
function M:parse_field(l) return l and l:split(M.conf.field_delimiter, 1):mapm("strip") end

function M:parse_datatype(val)
    if val then
        local link = Link:from_str(val)

        if link then
            return link.url, "reference"
        end
    end

    return val, "primitive"
end


function M:separate_metadata(lines)
    lines = lines:filter(function(l)
        return not l:strip():startswith(M.conf.exclude_startswith)
    end)
    M.conf.metadata_dividers:foreach(function(chop)
        local index = lines:index(chop)
        if index then 
            lines = lines:chop(index, #lines)
        end
    end)

    for i, l in ipairs(lines) do
        local has_metadata = M:is_tag(l) or M:is_field(l)

        if i == 1 and not has_metadata then
            return List()
        end

        if not has_metadata or #l > 120 then
            return lines:chop(i, #lines)
        end
    end

    return lines
end

function M:parse(lines)
    local metadata = Dict({metadata = Dict()})

    local parents_by_indent = Dict({[""] = List()})

    lines:foreach(function(line)
        local indent, line = line:match("(%s*)(.*)")

        local key, val, datatype
        if not M:is_a_bare_link(line) then
            if line:startswith(M.conf.tag_prefix) then
                key = line
            else
                key, val = unpack(M:parse_field(line))

                parents_by_indent[indent .. M.conf.indent_size] = parents_by_indent[indent]:clone():append(key)
            end

            if key ~= M.conf.is_a_key then
                val, datatype = M:parse_datatype(val)
            end

            local m = metadata
            parents_by_indent[indent]:foreach(function(parent)
                m = m.metadata[parent]
            end)

            m.metadata[key] = Dict({
                val = val,
                datatype = datatype,
                metadata = Dict(),
            })
        end
    end)

    return metadata.metadata
end

function M:is_a_bare_link(str)
    local link = Link:from_str(str)
    return link and #link.before == 0 and #link.after == 0
end

return M
