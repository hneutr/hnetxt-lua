local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("hl.Set")

local urls = require("htl.db.urls")
local Link = require("htl.text.Link")
local Config = require("htl.Config")

local M = tbl("metadata", {
    id = true,
    key = {
        type = "text",
        required = true,
    },
    val = "text",
    url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    parent = {
        type = "integer",
        reference = "metadata.id",
        on_delete = "cascade",
    },
    datatype = "text",
})

M.config = Config.get("metadata")

-- should also deal with references/links
function M:parse(lines)
    local metadata = Dict({
        metadata = Dict(),
    })

    local parents_by_indent = Dict({[""] = List()})

    lines:foreach(function(line)
        local indent, line = line:match("(%s*)(.*)")

        local key, val
        if line:startswith(M.config.tag_prefix) then
            key = line
        else
            key, val = unpack(line:split(M.config.field_delimiter, 1):mapm("strip"))

            parents_by_indent[indent .. M.config.indent_size] = parents_by_indent[indent]:clone():append(key)
        end

        local m = metadata
        parents_by_indent[indent]:foreach(function(parent)
            m = m.metadata[parent]
        end)

        m.metadata[key] = Dict({
            val = val,
            metadata = Dict(),
        })
    end)

    return metadata.metadata
end

function M:insert_dict(dict, url, parent_field)
    Dict(dict):foreach(function(key, data)
        local val, datatype = M:parse_val(data.val)
        local row = {
            key = key,
            val = val,
            url = url,
            parent = parent_field,
            datatype = datatype,
        }

        M:insert(row)
        M:insert_dict(data.metadata, url, M:where(row).id)
    end)
end

function M:parse_val(val)
    if val then
        local link = Link:from_str(val)

        if link then
            return link.url, "reference"
        end
    end

    return val
end

function M:get_urls(args)
    local rows = List(M:get())

    if args.dir then
        local dir_urls = urls:get():filter(function(url)
            return url.path:is_relative_to(args.dir)
        end):transform(function(url)
            return url.id
        end)

        rows = rows:filter(function(row)
            return dir_urls:contains(row.url)
        end)
    end

    if args.reference then
        local reference_urls = List({args.reference})

        local reference_rows = rows:filter(function(row) return row.datatype == 'reference' end)
        local n_to_check = -1

        while n_to_check ~= #reference_rows do
            n_to_check = #reference_rows
            reference_rows = reference_rows:filter(function(row)
                if reference_urls:contains(row.val) then
                    reference_urls:append(row.url)
                    return false
                end

                return true
            end)
        end

        rows = rows:filter(function(row)
            return reference_urls:contains(row.url)
        end)
    end

    List(args.conditions):transform(M.parse_condition):foreach(function(condition)
        local passing = Set(rows:filter(M.check_condition, condition):transform(function(r) return r.url end))
        rows = rows:filter(function(row)
            return passing:has(row.url)
        end)
    end)

    return Set(rows:transform(function(row) return row.url end)):values()
end

function M:get(q)
    return List(M:map(function(m)
        if m.datatype == "reference" then
            m.val = tonumber(m.val)
        end
        return m
    end, q))
end

function M.check_condition(row, condition)
    local result = row.key == condition.key

    if condition.startswith then
        result = row.key:startswith(condition.key)
    end

    if condition.vals then
        result = result and condition.vals:contains(row.val)
    end

    if condition.is_exclusion then
        result = not result
    end

    return result
end

function M.parse_condition(str)
    local condition = Dict({
        startswith = str:startswith(M.config.tag_prefix),
        is_exclusion = str:endswith(M.config.exclusion_suffix),
    })

    str = str:removesuffix(M.config.exclusion_suffix)

    condition.key, condition.vals = unpack(str:split(M.config.field_delimiter, 1):mapm("strip"))

    if condition.vals then
        condition.vals = condition.vals:split(M.config.field_or_delimiter)
    end
    
    return condition
end

-- function M.get_print_lines(urls)
--     -- starting fields are fields that ever have no parent field
--     -- local starting_fields = 
--     -- local values = ""
--     return lines
-- end

-- function M.get_field_print_lines(urls, )

return M
