local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("hl.Set")

local db = require("htl.db")
local urls = require("htl.db.urls")
local mirrors = require("htl.db.mirrors")
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
M.agnostic_val = '__agnostic'

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
        local urls = Set(urls:get({contains = {path = string.format("%s*", args.dir)}}):col('id'))
        rows = rows:filter(function(r) return urls:has(r.url) end)
    end

    if args.reference then
        local urls = Set({args.reference})

        local references = rows:filter(function(r) return r.datatype == 'reference' end)
        local n_references = -1

        while n_references ~= #references do
            n_references = #references
            references = references:filter(function(row)
                if urls:has(row.val) then
                    urls:add(row.url)
                else
                    return true
                end
            end)
        end

        rows = rows:filter(function(r) return urls:has(r.url) end)
    end

    List(args.conditions):transform(M.parse_condition):foreach(function(condition)
        local urls = Set(rows:filter(M.check_condition, condition):col('url'))
        rows = rows:filter(function(r) return urls:has(r.url) end)
    end)

    return Set(rows:col('url')):vals()
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

function M:get_metadata_lines(path)
    local s = path:read():split(M.config.frontmatter_delimiter, 1)[1]

    local metadata_path = mirrors:get_mirror_path(path, "metadata")
    if metadata_path:exists() then
        s = string.format("%s\n%s", s, metadata_path:read())
    end

    return s:split("\n")
end

function M:save_file_metadata(path)
    local url = urls:where({path = path, resource_type = "file"})

    if url then
        M:remove({url = url.id})
        M:insert_dict(M:parse(M:get_metadata_lines(path)), url.id)
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  printing                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:dict_to_string(dict)
    local lines = tostring(dict):split("\n")
    lines:pop(1)
    lines:pop()

    lines:transform(function(l)
        l = l:sub(#M.config.indent_size + 1)
        l = l:removesuffix(" = {}")

        if l:endswith(" = {") then
            l = l:removesuffix(" = {")

            if l:match("%*") then
                l = l:gsub("%*", "") .. ":"
            end
        end

        if l:endswith("}") then
            l = ""
        end
        
        return l
    end)

    return lines:filter(function(l)
        return #l > 0
    end):join("\n")
end

function M.get_dict(urls, include_references)
    local rows = M:get({where = {url = urls}})

    if not include_references then
        rows = rows:filter(function(row) return row.datatype ~= 'reference' end)
    end

    local ids = rows:col('id')

    local starting_keys = Set(rows:filter(function(r) return r.parent == nil end):col('key'))

    local d = Dict()
    starting_keys:difference(Set(M.config.excluded_fields)):foreach(function(key)
        d[M:key_string(key)] = M.get_key_subdict(M:get({where = {key = key, id = ids}}))
    end)
    
    return M:dict_to_string(d)
end

function M:key_string(key)
    if not key:startswith(M.config.tag_prefix) then
        key = string.format("*%s", key)
    end
    return key
end

function M:val_string(val)
    return string.format("=%s", val)
end

function M.get_key_subdict(rows)
    local subrows = M.annotate_parent_vals(M:get({where = {parent = rows:col('id')}}), rows)

    local subkeys_by_val = M:get_subkeys_by_val(subrows)

    local lines_by_val = Dict()
    subkeys_by_val:foreach(function(val, subkeys)
        local val_rows = subrows
        local set_keys = List()

        if val ~= M.agnostic_val then
            val_rows = val_rows:filter(function(r) return r.parent_val == val end)
            set_keys:append(M:val_string(val))
        end
        
        subkeys:foreach(function(subkey)
            local subkey_rows = M:get({where = {key = subkey, id = val_rows:col('id')}})
            local subkey_setkeys = set_keys:clone():append(M:key_string(subkey))
            lines_by_val:set(subkey_setkeys, M.get_key_subdict(subkey_rows))
        end)
    end)

    local subrowless_vals = Set(rows:col('val')):remove(false) - Set(subrows:col('parent_val'))
    subrowless_vals:vals():foreach(function(v)
        lines_by_val[string.format(M:val_string(v))] = Dict()
    end)

    return lines_by_val
end

-- TODO: actually call this
function M:should_print_val_lines(rows)
    local n_urls = Set(rows:col('url')):len()

    local n_vals = Set(rows:col('val')):len()
    
    local has_nil_val = false
    rows:foreach(function(r)
        if r.val == nil then
            has_nil_val = true
        end
    end)

    if has_nil_val then
        n_vals = n_vals + 1
    end

    return n_vals ~= 1 and n_vals ~= n_urls
end

function M.annotate_parent_vals(rows, parents)
    local id_to_parent_val = Dict()
    List(parents):foreach(function(row)
        id_to_parent_val[row.id] = row.val
    end)

    List(rows):foreach(function(row)
        row.parent_val = id_to_parent_val[row.parent]
    end)

    return rows
end

--[[
a subkey is value-agnostic if it appears under either:
- val = nil
- > 1 val
]]
function M:get_subkeys_by_val(rows)
    local subkey_to_val = Dict()
    List(rows):foreach(function(row)
        local val = row.parent_val or M.agnostic_val
        if val == nil or subkey_to_val:default(row.key, val) ~= val then
            subkey_to_val[row.key] = M.agnostic_val
        end
    end)

    List(M.config.excluded_fields):foreach(function(e)
        subkey_to_val[e] = nil
    end)

    local val_to_subkeys = Dict()
    subkey_to_val:foreach(function(subkey, val)
        val_to_subkeys:default(val, List()):append(subkey):sort()
    end)

    return val_to_subkeys
end

return M
