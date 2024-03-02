local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("hl.Set")
local class = require("pl.class")

local db = require("htl.db")
local urls = require("htl.db.urls")
local mirrors = require("htl.db.mirrors")
local Link = require("htl.text.Link")
local Config = require("htl.Config")
local Divider = require("htl.text.divider")

local Colorize = require("htc.Colorize")
local Taxonomy = require("htl.taxonomy")

--[[
TODO:
- tag handing: group tags by @level1.level2.etc
]]

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
    },
})

M.config = Config.get("metadata")
M.config.excluded_fields = Set(M.config.excluded_fields)
M.config.direct_fields = Set(M.config.direct_fields)
M.metadata_dividers = List({"", tostring(Divider("large", "metadata"))})
M.root_key = "__root"
M.max_width = 118

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  taxonomy                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.set_taxonomy(path)
    M.taxonomy = Taxonomy(path)
end

function M.get_taxonomy()
    if not M.taxonomy then
        M.set_taxonomy()
    end

    return M.taxonomy
end

function M.add_taxonomy_vals(vals)
    vals = Set(vals)
    local descendants = M.get_taxonomy():descendants()
    local taxonomy_vals = List()
    vals:foreach(function(val)
        taxonomy_vals:extend(descendants[val] or {})
    end)
    
    return vals:union(taxonomy_vals):vals()
end

function M:get_is_a_to_ids(all_rows, is_a_rows)
    local rows = db.map_row_to_col(all_rows, is_a_rows, "parent", "_parent")

    local def_keys = Dict()
    local key_to_ids = Dict()

    Set(is_a_rows:col('val')):foreach(function(def)
        def_keys[def] = Set()
    end)

    rows:foreach(function(row)
        def_keys[row._parent.val]:add(row.key)
        key_to_ids:default(row.key, List()):append(row.id)
    end)

    def_keys = M:construct_taxonomy_key_map(def_keys)

    local parents = M.get_taxonomy():parents()

    local def_ids = Dict()
    def_keys:foreach(function(def)
        def_ids[def] = List()
    end)

    rows:foreach(function(row)
        local def = row._parent.val
        while not def_keys[def]:contains(row.key) do
            def = parents[def]
        end

        def_ids[def]:append(row.id)
    end)
    
    return def_ids
end

function M:construct_taxonomy_key_map(def_keys)
    def_keys = Dict(def_keys)

    local generations = M.get_taxonomy():generations()
    local parents = M.get_taxonomy():parents()
    local descendants = M.get_taxonomy():descendants()
    local children = M.get_taxonomy():children()

    local defs_at_start = Set(def_keys:keys())
    local defs = defs_at_start:union(parents:keys(), children:keys()):vals()

    defs:foreach(function(def)
        def_keys[def] = def_keys[def] or Set()
        generations[def] = generations[def] or 1
        children[def] = children[def] or List()
        descendants[def] = descendants[def] or List()
    end)

    defs:sorted(function(a, b)
        return generations[a] < generations[b]
    end):foreach(function(def)
        local observed_keys = Set()
        descendants[def]:foreach(function(descendant)
            def_keys[descendant]:foreach(function(key)
                if not M.config.direct_fields:has(key) or parents[key] == def then
                    if observed_keys:has(key) then
                        def_keys[def]:add(key)
                    end
                    observed_keys:add(key)
                end
            end)
        end)

        descendants[def]:foreach(function(descendant)
            def_keys[descendant] = def_keys[descendant] - def_keys[def]
        end)
    end)

    def_keys:transformv(function(keys) return keys:vals():sorted() end)

    defs:sorted(function(a, b)
        return generations[a] > generations[b]
    end):foreach(function(def)
        local included_children = Set(children[def]) * Set(def_keys:keys())

        local include_def = defs_at_start:has(def) or #def_keys[def] > 0 or included_children:len() > 0

        if not include_def then
            def_keys[def] = nil
        end
    end)

    return def_keys
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
        return not l:strip():startswith(M.config.exclude_startswith)
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

function M:line_is_non_metadata(l)
    if l then
        return not l:match(M.config.field_delimiter) and not l:strip():startswith(M.config.tag_prefix)
    else
        return true
    end
end

function M:parse(lines)
    local metadata = Dict({metadata = Dict()})

    local parents_by_indent = Dict({[""] = List()})

    if M:line_is_non_metadata(lines[1]) then
        return Dict()
    end

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

        m.metadata[key] = Dict({val = val, metadata = Dict()})
    end)

    return metadata.metadata
end

function M:insert_dict(dict, url, parent_field)
    if not parent_field then
        local root = {key = M.root_key, url = url, datatype = 'root'}

        if not M:where(root) then
            M:insert(root)
        end
        
        parent_field = M:where(root).id
    end

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
    q = q or {}

    local long_cols = List({"url", "id", "parent"})
    local long_vals = Dict()

    if q.where then
        long_cols:foreach(function(col)
            local vals = q.where[col]
            if vals and type(vals) == 'table' then
                long_vals[col] = Set(vals)
                q.where[col] = nil
            end
        end)
    end

    if #Dict(q.where):keys() == 0 then
        q.where = nil
    end

    local rows = List(M:__get(q))

    long_vals:foreach(function(col, vals)
        rows = rows:filter(function(r) return vals:has(r[col]) end)
    end)

    if #long_vals:keys() > 0 then
        q.where = q.where or {}
        long_vals:foreach(function(col, vals)
            q.where[col] = vals:vals()
        end)
    end

    return rows
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
        local _urls = Set(urls:get({contains = {path = string.format("%s*", args.dir)}}):col('id'))
        rows = rows:filter(function(r) return _urls:has(r.url) end)
    end

    if args.reference then
        local _urls = Set({args.reference})

        local references = rows:filter(function(r) return r.datatype == 'reference' end)
        local n_references = -1

        while n_references ~= #references do
            n_references = #references
            references = references:filter(function(row)
                if _urls:has(tonumber(row.val)) then
                    _urls:add(row.url)
                else
                    return true
                end
            end)
        end

        rows = rows:filter(function(r) return _urls:has(r.url) end)
    end

    List(args.conditions):transform(M.parse_condition):foreach(function(condition)
        local _urls = Set(rows:filter(M.check_condition, condition):col('url'))

        rows = rows:filter(function(r)
            local result = _urls:has(r.url)
            if condition.is_exclusion then
                result = not result
            end

            return result
        end)
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

    return result
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  printing                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:dict_string(dict)
    local field_ends = List({" = {}", " = {"})
    local line_types = List({M.is_a_string, M.link_string, M.key_string, M.val_string})

    return tostring(dict):split("\n"):transform(function(l)
        l = l:sub(#M.config.indent_size + 1)

        local has_vals = M.has_vals(l)
        field_ends:foreach(function(field_end)
            if l:endswith(field_end) then
                l = l:removesuffix(field_end)
            end
        end)

        local post_string = ""
        if has_vals then
            post_string = ":"
        end

        for line_type in line_types:iter() do
            if line_type:is_a(l) then
                return line_type:for_terminal(l) .. post_string
            end
        end

        return l
    end):filter(function(l)
        return not List({
            l == nil,
            #l == 0,
            l:endswith("}"),
            l:endswith("{"),
        }):any()
    end):join("\n")
end

function M.has_vals(s)
    return s:endswith(" = {")
end

--------------------------------------------------------------------------------
--                                key strings                                 --
--------------------------------------------------------------------------------
M.key_string = {
    match = "%=",
    color = "blue",
}

function M.key_string:is_a(s) return s:match(self.match) end
function M.key_string:for_terminal(s)
    s = s:gsub(self.match, "")
    return Colorize(s, self.color)
end

function M.key_string:for_dict(s)
    if not s:startswith(M.config.tag_prefix) then
        s = string.format("=%s", s)
    end
    return s
end

--------------------------------------------------------------------------------
--                                val strings                                 --
--------------------------------------------------------------------------------
M.val_string = {
    match = "%*",
    color = "blue",
}

function M.val_string:is_a(s) return s:match(self.match) end
function M.val_string:for_terminal(s)
    local indent, s = s:match("(%s*)(.*)")
    return indent .. Colorize("- ", self.color) .. s:gsub(self.match, "")
end

function M.val_string:for_dict(s)
    if s and #s > 0 then
        return string.format("*%s", s)
    end
end

--------------------------------------------------------------------------------
--                                is a string                                 --
--------------------------------------------------------------------------------
M.is_a_string = {
    match = "%*%=",
    color = "yellow",
}

function M.is_a_string:is_a(s) return s:match(self.match) end
function M.is_a_string:for_terminal(s)
    s = s:gsub(self.match, "")
    return Colorize(s, self.color)
end

function M.is_a_string:for_dict(s)
    if s and #s > 0 then
        return string.format("*=%s", s)
    end
end

--------------------------------------------------------------------------------
--                                link_string                                 --
--------------------------------------------------------------------------------
M.link_string = {
    match = "%*@",
    color = "magenta",
    colors = {
        list = "blue",
        bracket = "black",
        label = {"cyan", "underline"},
        url = "black",
    }
}

function M.link_string:is_a(s) return s:strip():startswith("*@") end
function M.link_string:for_terminal(s)
    local indent, s = s:match("(%s*)(.*)")
    local s = s:gsub(self.match, "")
    local url = urls:where({id = tonumber(s)})

    if url then
        local link = urls:get_reference(url)
        local l = List({
            Colorize("- ", self.colors.list),
            Colorize("[", self.colors.bracket),
            Colorize(link.label, self.colors.label),
            Colorize("]", self.colors.bracket),
            Colorize(string.format("(%s)", link.url), self.colors.url),
            ""
        })

        return indent .. l:join("")
    end
end

function M.link_string:for_dict(s)
    if urls:where({id = tonumber(s)}) then
        return string.format("*@%s", s) 
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                big printing                                --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.get_dict(urls, include_references, exclude_unique_values)
    local query = {where = {url = urls}}

    local rows = M:get({where = {url = urls}})

    if not include_references then
        rows = rows:filter(function(r) return r.datatype ~= "reference" end)
    end

    rows = rows:filter(function(r)
        return not M.config.excluded_fields:has(r.key)
    end)

    local d = M.get_subdict(M.handle_is_a(rows), exclude_unique_values)
    return M:dict_string(d)
end

function M.get_subdict(rows, exclude_unique_values)
    local parent_ids = Set(rows:filter(function(r) return r.key == M.root_key end):col('id'))
    local id_to_parents = Dict()

    local d = Dict()
    while #rows > 0 do
        local child_rows = rows:filter(function(r) return parent_ids:has(r.parent) end)
        rows = rows:filter(function(r) return not parent_ids:has(r.id) end)
        parent_ids = Set(child_rows:col('id'))

        local keys_with_excluded_vals = M.get_keys_with_val_exclusions(child_rows, exclude_unique_values)

        child_rows:foreach(function(row)
            local parents = id_to_parents[tostring(row.parent)] or List()
            parents = parents:clone()

            local key = M.key_string:for_dict(row.key)

            if row.datatype == 'IsA' then
                key = M.is_a_string:for_dict(row.key)
            end
            
            parents:append(key)
            id_to_parents[tostring(row.id)] = parents

            local row_d = d:get(unpack(parents)) or Dict()

            if not keys_with_excluded_vals:has(row.key) then
                local val = M.val_string:for_dict(row.val)

                if row.datatype == "reference" then
                    val = M.link_string:for_dict(row.val)
                end

                if val then
                    row_d[val] = Dict()
                end
            end
            
            d:set(parents, row_d)
        end)
    end

    return d
end

function M.get_keys_with_val_exclusions(rows, exclude_unique_values)
    local keys = Set()
    if exclude_unique_values then
        local counts = Dict()
        rows:foreach(function(row)
            counts:default(row.key, Dict({urls = Set(), vals = Set()}))
            counts[row.key].urls:add(row.url)
            counts[row.key].vals:add(row.val)
        end)

        counts:foreach(function(key, c)
            if c.urls:len() == c.vals:len() then
                keys:add(key)
            end
        end)
    end

    return keys
end

function M.handle_is_a(rows)
    local is_a_rows = rows:filter(function(r) return r.key == M.config.is_a_key end)

    local is_a_to_ids = M:get_is_a_to_ids(rows, is_a_rows)
    
    local is_a_vals = is_a_to_ids:keys():sorted()

    local _, max_id = rows:col('id'):minmax()
    local is_a_id = max_id + 1

    local new_val_rows_by_val = Dict()
    is_a_vals:foreach(function(val)
        new_val_rows_by_val[val] = Dict({
            id = is_a_id + is_a_vals:index(val),
            key = val,
            parent = is_a_id,
            datatype = 'IsA',
        })
    end)

    local parents = M.get_taxonomy():parents()
    new_val_rows_by_val:foreach(function(val, row)
        local parent = parents[val]
        if parent and new_val_rows_by_val[parent] then
            row.parent = new_val_rows_by_val[parent].id
        end
    end)

    local id_remap = Dict()
    is_a_to_ids:foreach(function(val, ids)
        ids:foreach(function(id)
            id_remap[id] = new_val_rows_by_val[val].id
        end)
    end)

    is_a_rows:foreach(function(r)
        r.val = nil
        r.id = is_a_id
    end)

    rows:foreach(function(r)
        r.parent = id_remap[r.id] or r.parent
    end)

    rows:extend(new_val_rows_by_val:values())
    return rows
end

return M
