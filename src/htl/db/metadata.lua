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
    return List(M:__get(q))
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 filtering                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:get_urls(args)
    local rows = M:get()

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

    if not args.include_references then
        rows = rows:filter(function(r) return r.datatype ~= "reference" end)
    end

    rows = rows:filter(function(r)
        return not M.config.excluded_fields:has(r.key)
    end)

    rows = rows:filter(function(r)
        local is_tag = r.key:startswith(M.config.tag_prefix)
        
        if is_tag then
            if not args.include_tags then
                return false
            end
        elseif not args.include_values then
            if r.key == M.root_key or r.key == M.config.is_a_key or r.datatype == "reference" then
                return true
            else
                return false
            end
        end
        
        return true
    end)

    return M.handle_is_a(rows)
end

function M.parse_condition(str)
    local condition = Dict({
        startswith = str:startswith(M.config.tag_prefix),
        is_exclusion = str:endswith(M.config.exclusion_suffix),
    })

    str = str:removesuffix(M.config.exclusion_suffix)

    condition.key, condition.vals = unpack(str:split(M.config.field_delimiter, 1):mapm("strip"))

    if condition.vals then
        condition.vals = condition.vals:split(M.config.or_delimiter)
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
--                                big printing                                --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.get_dict(args)
    M.set_taxonomy(args.dir)
    local rows = M:get_urls(args)
    local parent_ids = Set(rows:filter(function(r) return r.key == M.root_key end):col('id'))
    local id_to_keys = Dict()

    local d = Dict()
    local last_n = -1
    while #rows > 0 and #rows ~= last_n do
        last_n = #rows
        local child_rows = rows:filter(function(r) return parent_ids:has(r.parent) end)
        rows = rows:filter(function(r) return not parent_ids:has(r.id) end)
        parent_ids = Set(child_rows:col('id'))

        local keys_with_excluded_vals = M.get_keys_with_val_exclusions(
            child_rows,
            args.include_values,
            args.exclude_unique_values
        )

        child_rows:foreach(function(row)
            local keys = List(id_to_keys[tostring(row.parent)]) or List()
            keys:append(M.Printer:for_dict(row, "key"))
            id_to_keys[tostring(row.id)] = keys

            local row_d = d:get(unpack(keys)) or Dict()

            local url_keys = List()
            if not keys_with_excluded_vals:has(row.key) then
                url_keys:append(M.Printer:for_dict(row, "val"))
            end

            if args.include_files then
                url_keys:append(M.Printer:for_dict(row, "url"))
            end

            if #url_keys > 0 then
                row_d:set(url_keys)
            end
            
            d:set(keys, row_d)
        end)
    end

    d[M.Printer:for_dict({key = "lexis"}, "key")] = nil

    return M:dict_string(d)
end

function M.get_keys_with_val_exclusions(rows, include_values, exclude_unique_values)
    if not include_values then
        return Set(rows:col('key'))
    end

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

    local id_to_row = Dict()
    rows:foreach(function(r) id_to_row[r.id] = r end)
    
    local parents = M.get_taxonomy():parents()
    local new_val_rows_by_val = Dict()
    is_a_to_ids:foreach(function(val, ids)
        new_val_rows_by_val[val] = Dict({
            id = val,
            key = val,
            parent = parents[val] or M.config.is_a_key,
            datatype = 'IsA',
        })

        ids:foreach(function(id)
            id_to_row[id].parent = val
        end)
    end)

    is_a_rows:foreach(function(r)
        local v = new_val_rows_by_val[r.val]
        rows:append({
            id = v.id,
            key = v.key,
            parent = v.parent,
            url = r.url,
            datatype = "IsA",
        })
    
        r.id = M.config.is_a_key
        r.val = nil
        r.url = nil
    end)

    rows:extend(new_val_rows_by_val:values())
    
    return rows
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  printing                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:dict_string(dict)
    local field_ends = List({" = {}", " = {", "}"})

    return tostring(dict):split("\n"):transform(function(l)
        l = l:sub(#M.config.indent_size + 1)

        local post_string = l:endswith(" = {") and ":" or ""

        field_ends:foreach(function(e) l = l:removesuffix(e) end)

        return M.Printer:for_terminal(l, post_string)
    end):filter(function(l)
        return l ~= nil and not List({
            #l == 0,
            l:endswith("}"),
            l:endswith("{"),
        }):any()
    end):join("\n")
end

--------------------------------------------------------------------------------
--                                key strings                                 --
--------------------------------------------------------------------------------
M.KeyPrinter = {
    color = "blue",
}

function M.KeyPrinter:is_a() return true end
function M.KeyPrinter:for_terminal(s)
    return Colorize(s, self.color)
end

--------------------------------------------------------------------------------
--                                 TagPrinter                                 --
--------------------------------------------------------------------------------
M.TagPrinter = {
    color = "magenta",
}

function M.TagPrinter:is_a(s) return s:match(M.config.tag_prefix) end
function M.TagPrinter:for_terminal(s)
    return Colorize(s, self.color)
end

--------------------------------------------------------------------------------
--                                 ValPrinter                                 --
--------------------------------------------------------------------------------
M.ValPrinter = {
    color = "blue",
}

function M.ValPrinter:is_a() return true end
function M.ValPrinter:for_terminal(s)
    return Colorize("- ", self.color) .. s
end

--------------------------------------------------------------------------------
--                                 IsAPrinter                                 --
--------------------------------------------------------------------------------
M.IsAPrinter = {
    color = "yellow",
}

function M.IsAPrinter:is_a(s, row) return row.datatype == "IsA" end
function M.IsAPrinter:for_terminal(s)
    return Colorize(s, self.color)
end

--------------------------------------------------------------------------------
--                                LinkPrinter                                 --
--------------------------------------------------------------------------------
M.LinkPrinter = {
    colors = {
        bracket = "black",
        label = {"cyan", "underline"},
        url = "black",
    }
}

function M.LinkPrinter:is_a(s, row) return row.datatype == "reference" end
function M.LinkPrinter:for_terminal(s)
    local url = urls:where({id = tonumber(s)})

    if url then
        local link = urls:get_reference(url)
        return List({
            Colorize("[", self.colors.bracket),
            Colorize(link.label, self.colors.label),
            Colorize("]", self.colors.bracket),
            Colorize(string.format("(%s)", link.url), self.colors.url),
            ""
        }):join("")
    end
end

--------------------------------------------------------------------------------
--                                 URLPrinter                                 --
--------------------------------------------------------------------------------
M.URLPrinter = {
    color = "yellow",
}

function M.URLPrinter:is_a() return true end
function M.URLPrinter:for_terminal(s)
    return M.LinkPrinter:for_terminal(s)
end

M.Printer = {
    cols = List({"url", "key", "val"}),
    types = Dict({
        key = List({
            M.TagPrinter,
            M.IsAPrinter,
            M.KeyPrinter,
        }),
        val = List({
            M.LinkPrinter,
            M.ValPrinter,
        }),
        url = List({
            M.URLPrinter,
        }),
    }),
    format_string = "%s:%s %s",
    regex = "(%s*)(%d):(%d) (.*)",
}

function M.Printer:for_dict(row, col)
    local val = row[col]
    if val == nil or #tostring(val) == 0 then
        return
    end
    for i, Printer in ipairs(M.Printer.types[col]) do
        if Printer:is_a(row[col], row) then
            return string.format(self.format_string, self.cols:index(col), i, val)
        end
    end
end

function M.Printer:for_terminal(s, post_string)
    local indent, col_index, type_index, val = s:match(self.regex)
    if indent and col_index and type_index and val then
        local col = self.cols[tonumber(col_index)]
        local Printer = self.types[col][tonumber(type_index)]

        local s = Printer:for_terminal(val)

        if s and #s > 0 then
            return indent .. s .. post_string
        end
    end

    return ""
end

return M
