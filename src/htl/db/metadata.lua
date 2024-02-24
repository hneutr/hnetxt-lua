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
local Divider = require("htl.text.divider")

local Taxonomy = require("htl.metadata").Taxonomy

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
    datatype = {
        type = "text",
        default = "primitive",
    },
})

--[[
`The Solity`:
is a: space station
    governed by: Luc Acastor
    radial distance: .05x
    built by: Luc Acastor

`Marand`:
is a: planet
    governed by: The Marandine Umbrae
    radial distance: .1x

----------------------------------------

is a:
    place >
        governed by:
            Luc Acastor
            The Marandine Umbrae
        radial distance:
            .05x
            .1x
        = space station
            built by:
                Luc Acastor
        = planet

----------------------------------------

take the list of `is a` values:

make a dictionary:
    is_a_key_to_fields['key'] = Set(fields)

for each key in the is_a taxonomy:
    add the intersection of all of the subtypes to the key
        remove the intersected keys from the subtypes

eg:
    at start:
        is_a_dict = {
            space station = Set({"governed by", "radial distance", "built by"}),
            planet = Set({"governed by", "radial distance"})
        }

    then set `place`:
        is_a_dict = {
            space station = Set({"built by"}),
            planet = Set()
            place = Set({"governed by", "radial distance"})
        }

- we're only going to do this for the is_a field
- all other fields will be handled as is: no more "agnostic" bullshit

]]

M.config = Config.get("metadata")
M.config.excluded_fields = Set(M.config.excluded_fields)
M.agnostic_val = '__agnostic'
M.metadata_dividers = List({"", tostring(Divider("large", "metadata"))})
M.exclude_startswith = "-"

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  taxonomy                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
-- TODO: modify for different projects
function M.get_taxonomy()
    if not M.taxonomy then
        M.taxonomy = Taxonomy()
    end

    return M.taxonomy
end

function M.add_taxonomy_vals(vals)
    vals = Set(vals)
    local taxonomy = M.get_taxonomy()
    local taxonomy_vals = List()
    vals:foreach(function(val)
        taxonomy_vals:extend(taxonomy.children[val] or {})
    end)
    
    return vals:union(taxonomy_vals):vals()
end

--[[
TODO:
- tag handing: group tags by @level1.level2.etc
- handle taxonomization:
    - construct the definition_keys map:
        - for each IsA value:
            - set definition_keys[IsA] = all the fields under the row
                ******************
                - save the ids of those fields, so that you can print their children with it
                ******************
        - define each IsA's definition_keys as the intersection of its childrens' keys
            - don't over specify!
                - if a definition doesn't show up and there's only 1 child, don't define it
]]
function M:get_is_a_dict(query)
    query.where.key = M.config.is_a_key
    local is_a_rows = M:get(query)
    local rows = M.annotate_parent_vals(M:get({where = {parent = is_a_rows:col('id')}}), is_a_rows)
    
    local def_to_keys = Dict()
    local key_to_ids = Dict()

    rows:foreach(function(row)
        def_to_keys:default(row.parent_val, Set()):add(row.key)
        key_to_ids:default(row.key, List()):append(row.id)
    end)

    def_to_keys = M:construct_taxonomy_key_map(def_to_keys)
end

function M:construct_taxonomy_key_map(def_to_keys)
    def_to_keys = Dict(def_to_keys)

    local taxonomy = M.get_taxonomy()

    local order = Dict()
    taxonomy.children:keys():foreach(function(def)
        order[def] = taxonomy:get_precedence(def)
    end)

    local unchecked = def_to_keys:keys()

    while #unchecked > 0 do
        local to_check = unchecked:sort(function(a, b) return order[a] < order[b] end):pop()
        local parent = taxonomy.parents[to_check]
        local children = taxonomy.children[parent]:filter(function(c) return def_to_keys[c] end)

        local child_keys = Set()
        children:foreach(function(child)
            def_to_keys[child]:foreach(function(key)
                if child_keys:has(key) then
                    def_to_keys:default(parent, Set()):add(key)
                end
                
                child_keys:add(key)
            end)
        end)

        if def_to_keys[parent] then
            children:foreach(function(child)
                def_to_keys[child] = def_to_keys[child] - def_to_keys[parent]
            end)
        end

        unchecked = unchecked:filter(function(u) return not children:contains(u) end)
    end

    def_to_keys:transformv(function(keys) return keys:vals():sorted() end)

    return def_to_keys
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  reading                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:separate_metadata(lines)
    lines = lines:filter(function(l)
        return not l:strip():startswith(M.exclude_startswith)
    end)

    M.metadata_dividers:foreach(function(chop)
        local index = lines:index(chop)
        if index then 
            lines = lines:chop(index, #lines)
        end
    end)

    for i, line in ipairs(lines) do
        local is_tag = line:strip():startswith(M.config.tag_prefix)
        local probably_field = line:strip():match(M.config.field_delimiter) and #line < 120

        if not (is_tag or probably_field) then
            return lines:chop(i, #lines)
        end
    end

    return lines
end

function M:get_metadata_lines(path)
    local lines = M:separate_metadata(path:readlines())

    local metadata_path = mirrors:get_mirror_path(path, "metadata")
    if metadata_path:exists() then
        lines:extend(metadata_path:readlines())
    end

    return lines:filter(function(line) return #line > 0 end)
end

function M:save_file_metadata(path)
    local url = urls:where({path = path, resource_type = "file"})

    if url then
        M:remove({url = url.id})
        local lines = M:get_metadata_lines(path)
        M:insert_dict(M:parse(lines), url.id)
    end
end

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

    return val, "primitive"
end

function M:get(q)
    return List(M:map(function(m)
        if m.datatype == "reference" then
            m.val = tonumber(m.val)
        end
        return m
    end, q))
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 filtering                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
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

    if condition.key == M.config.is_a_key then
        condition.vals = M.add_taxonomy_vals(condition.vals)
    end
    
    return condition
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

        -- if l:endswith(" = {") then
        --     l = l:removesuffix(" = {")

        --     if l:match("%*") then
        --         l = l:gsub("%*", "") .. ":"
        --     end
        -- end

        -- if l:endswith("}") then
        --     l = ""
        -- end
        
        return l
    end)

    return lines:filter(function(l)
        return #l > 0
    end):join("\n")
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

function M.get_dict(urls, include_references)
    local query = {where = {url = urls}}
    
    if not include_references then
        query.where.datatype = "primitive"
    end
    
    local rows = M:get(query)

    local starting_keys = Set(rows:filter(function(row)
        return row.parent == nil and not M.config.excluded_fields:has(row.key)
    end):col('key'))

    local d = Dict()
    starting_keys:foreach(function(key)
        d[M:key_string(key)] = M.get_subdict(key, query)
    end)
    
    return M:dict_to_string(d)
end

function M.get_subdict(key, query)
    query.where.key = key
    local rows = M:get(query)
    local subrows = List()
    local subkeys_by_val = Dict()
    local subrowless_vals = Set(rows:col('val')):remove(false)

    if #rows > 0 then
        subrows = M.annotate_parent_vals(M:get({where = {parent = rows:col('id')}}), rows)
        subkeys_by_val = M:get_subkeys_by_val(subrows)
        subrowless_vals = subrowless_vals - Set(subrows:col('parent_val'))
    end

    local lines_by_val = Dict()
    subkeys_by_val:foreach(function(val, subkeys)
        local val_rows = subrows
        local set_keys = List()

        if val ~= M.agnostic_val then
            val_rows = val_rows:filter(function(r) return r.parent_val == val end)
            set_keys:append(M:val_string(val))
        end
        
        query.where.id = val_rows:col('id')

        subkeys:foreach(function(subkey)
            lines_by_val:set(set_keys:from({M:key_string(subkey)}), M.get_subdict(key, query))
        end)
    end)

    subrowless_vals:vals():foreach(function(v) lines_by_val[M:val_string(v)] = Dict() end)

    return lines_by_val
end

-- -- TODO: actually call this
-- function M:should_print_val_lines(rows)
--     local n_urls = Set(rows:col('url')):len()

--     local n_vals = Set(rows:col('val')):len()
    
--     local has_nil_val = false
--     rows:foreach(function(r)
--         if r.val == nil then
--             has_nil_val = true
--         end
--     end)

--     if has_nil_val then
--         n_vals = n_vals + 1
--     end

--     return n_vals ~= 1 and n_vals ~= n_urls
-- end

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
