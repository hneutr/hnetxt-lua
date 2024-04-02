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

local M = tbl("metadata", Conf.db.metadata)

M.conf = Conf.metadata
M.conf.excluded_fields = Set(M.conf.excluded_fields)
M.conf.direct_fields = Set(M.conf.direct_fields)
M.metadata_dividers = List({"", tostring(Divider("large", "metadata"))})
M.root_key = "__root"

function M:get(q)
    return List(M:__get(q))
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  taxonomy                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.set_taxonomy(path)
    while path and not path:exists() do
        path = path:parent()
    end

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
                if not M.conf.direct_fields:has(key) or parents[key] == def then
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
        return not l:strip():startswith(M.conf.exclude_startswith)
    end)

    M.metadata_dividers:foreach(function(chop)
        local index = lines:index(chop)
        if index then 
            lines = lines:chop(index, #lines)
        end
    end)

    for i, line in ipairs(lines) do
        local is_tag = line:strip():startswith(M.conf.tag_prefix)
        local probably_field = line:strip():match(M.conf.field_delimiter) and #line < 120

        if not (is_tag or probably_field) then
            return lines:chop(i, #lines)
        end
    end

    return lines
end

function M:get_metadata_lines(path)
    local lines = M:separate_metadata(path:readlines())

    local metadata_path = mirrors:get_path(path, "metadata")
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
        return not l:match(M.conf.field_delimiter) and not l:strip():startswith(M.conf.tag_prefix)
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
        if not M:is_a_bare_link(line) then
            if line:startswith(M.conf.tag_prefix) then
                key = line
            else
                key, val = unpack(line:split(M.conf.field_delimiter, 1):mapm("strip"))

                parents_by_indent[indent .. M.conf.indent_size] = parents_by_indent[indent]:clone():append(key)
            end

            local m = metadata
            parents_by_indent[indent]:foreach(function(parent)
                m = m.metadata[parent]
            end)

            m.metadata[key] = Dict({val = val, metadata = Dict()})
        end
    end)

    return metadata.metadata
end

function M:is_a_bare_link(str)
    local link = Link:from_str(str)
    return link and #link.before == 0 and #link.after == 0
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

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 filtering                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:get_urls(args)
    local rows = M:get()

    if args.path then
        local _urls = Set(urls:get({
            where = {resource_type = "file"},
            contains = {path = string.format("%s*", args.path)},
        }):col('id'))

        rows = rows:filter(function(r) return _urls:has(r.url) end)

        if args.add_missing then
            local urls_missing_metadata = _urls:difference(rows:col('url')):vals()

            if #urls_missing_metadata > 0 then
                urls:get({where = {id = urls_missing_metadata}}):foreach(function(url)
                    M:save_file_metadata(url.path)
                end)
            end
        end
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

    List(args.conditions):map(M.parse_condition):foreach(function(condition)
        local _urls = Set(rows:filter(M.check_condition, condition):col('url'))

        rows = rows:filter(function(r)
            local result = _urls:has(r.url)
            if condition.is_exclusion then
                result = not result
            end

            return result
        end)
    end)

    if not args.include_links then
        rows = rows:filter(function(r) return r.datatype ~= "reference" end)
    end

    rows = rows:filter(function(r)
        return not M.conf.excluded_fields:has(r.key)
    end)

    rows = rows:filter(function(r)
        local is_tag = r.key:startswith(M.conf.tag_prefix)
        
        if is_tag then
            if not args.include_tags then
                return false
            end
        elseif not args.include_values then
            if r.key == M.root_key or r.key == M.conf.is_a_key or r.datatype == "reference" then
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
        startswith = str:startswith(M.conf.tag_prefix),
        is_exclusion = str:endswith(M.conf.exclusion_suffix),
    })

    str = str:removesuffix(M.conf.exclusion_suffix)

    condition.key, condition.vals = unpack(str:split(M.conf.field_delimiter, 1):mapm("strip"))

    if condition.vals then
        condition.vals = condition.vals:split(M.conf.or_delimiter)
    end

    if condition.key == M.conf.is_a_key then
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
    M.set_taxonomy(args.path)
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

        local unique_keys = M.get_unique_keys(child_rows)
        child_rows:foreach(function(row)
            local keys = List(id_to_keys[tostring(row.parent)]) or List()
            keys:append(M.Printer:for_dict(row, "key"))
            id_to_keys[tostring(row.id)] = keys

            local row_d = d:get(unpack(keys)) or Dict()
            M.add_subkeys(row_d, row, unique_keys, args)

            d:set(keys, row_d)
        end)
    end

    if args.is_a_only then
        local is_a = M.Printer:for_dict({key = M.conf.is_a_key}, "key")
        d = d[is_a]
    end

    return M:dict_string(d)
end

function M.get_unique_keys(rows)
    local counts = Dict()
    local keys = List({"url", "val"})
    rows:foreach(function(row)
        counts:default(row.key, Dict({url = Set(), val = Set()}))

        if row.val ~= "" and row.val ~= nil then
            keys:foreach(function(key)
                if row[key] and row[key] ~= "" then
                    counts[row.key][key]:add(row[key])
                end
            end)
        end
    end)

    return Set(counts:keys():filter(function(k)
        return counts[k].url:len() == counts[k].val:len()
    end))
end

function M.add_subkeys(dict, row, unique_keys, args)
    local include = Dict({
        val = args.include_values,
        url = args.include_urls,
    })

    local unique = unique_keys:has(row.key)
    
    if unique and args.exclude_unique_values then
        include.val = false
    end

    local keys = List()
    M.Printer.line_order:foreach(function(key)
        if include[key] and row[key] ~= nil and row[key] ~= "" then
            keys:append(key)
        end
    end)

    local dict_keys = keys:map(function(ks)
        return M.Printer:for_dict(row, ks)
    end):filter(function(k)
        return k and #k > 0
    end)

    if #dict_keys > 0 then
        dict:set(dict_keys)
    end
end

function M.handle_is_a(rows)
    local is_a_rows = rows:filter(function(r) return r.key == M.conf.is_a_key end)

    local is_a_to_ids = M:get_is_a_to_ids(rows, is_a_rows)

    local id_to_row = Dict()
    rows:foreach(function(r) id_to_row[r.id] = r end)
    
    local parents = M.get_taxonomy():parents()
    local new_val_rows_by_val = Dict()
    is_a_to_ids:foreach(function(val, ids)
        new_val_rows_by_val[val] = Dict({
            id = val,
            key = val,
            parent = parents[val] or M.conf.is_a_key,
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
    
        r.id = M.conf.is_a_key
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

    return tostring(M.squish_dict(dict)):split("\n"):transform(function(l)
        l = l:sub(#M.conf.indent_size + 1)

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

function M.squish_dict(d)
    local _d = Dict()
    Dict(d):foreach(function(k, v)
        local v_keys = v:keys()
        if #v_keys == 1 and #v[v_keys[1]]:keys() == 0 then
            k = M.Printer:merge_dict_keys(k, v_keys[1])
            v = Dict()
        end

        _d[k] = M.squish_dict(v)
    end)
    
    return _d
end

--------------------------------------------------------------------------------
--                                key strings                                 --
--------------------------------------------------------------------------------
class.KeyPrinter()
KeyPrinter.color_key = "key"

function KeyPrinter:colors() return M.conf.colors[self.color_key] end
function KeyPrinter:is_a() return true end
function KeyPrinter:for_terminal(s)
    return Colorize(s, self:colors())
end

--------------------------------------------------------------------------------
--                                 TagPrinter                                 --
--------------------------------------------------------------------------------
class.TagPrinter(KeyPrinter)
TagPrinter.color_key = "tag"

function TagPrinter:is_a(s) return s:match(M.conf.tag_prefix) end

--------------------------------------------------------------------------------
--                                 IsAPrinter                                 --
--------------------------------------------------------------------------------
class.IsAPrinter(KeyPrinter)
IsAPrinter.color_key = "is_a"

function IsAPrinter:is_a(s, row) return row.datatype == "IsA" end

--------------------------------------------------------------------------------
--                                 ValPrinter                                 --
--------------------------------------------------------------------------------
class.ValPrinter(KeyPrinter)
ValPrinter.color_key = "val"

function ValPrinter:is_a() return true end
function ValPrinter:for_terminal(s, is_first)
    if is_first then
        s = Colorize("- ", self:colors()) .. s
    end
    return s
end

--------------------------------------------------------------------------------
--                                LinkPrinter                                 --
--------------------------------------------------------------------------------
class.LinkPrinter(KeyPrinter)
LinkPrinter.color_key = "link"

function LinkPrinter:is_a(s, row) return row.datatype == "reference" end
function LinkPrinter:for_terminal(s)
    local url = urls:where({id = tonumber(s)})

    if url then
        return urls:get_reference(url):terminal_string(self:colors())
    end
end

--------------------------------------------------------------------------------
--                                 URLPrinter                                 --
--------------------------------------------------------------------------------
class.URLPrinter(LinkPrinter)
function URLPrinter:is_a() return true end

--------------------------------------------------------------------------------
--                                  Printer                                   --
--------------------------------------------------------------------------------
M.Printer = {
    line_order = List({"key", "val", "url"}),
    cols = List({"url", "key", "val"}),
    types = Dict({
        key = List({
            TagPrinter,
            IsAPrinter,
            KeyPrinter,
        }),
        url = List({
            URLPrinter,
        }),
        val = List({
            LinkPrinter,
            ValPrinter,
        }),
    }),
    format_string = "%s:%s %s",
    regex = "(%d):(%d) (.*)",
    delimiter = " | ",
    terminal_delimiter = ": "
}

function M.Printer:merge_dict_keys(k1, k2)
    return List({k1, k2}):join(self.delimiter)
end

function M.Printer:for_dict(row, cols)
    if type(cols) == "string" then
        cols = {cols}
    end

    return List(cols):transform(function(col)
        local val = row[col]
        if val == nil or #tostring(val) == 0 then
            return
        end
        for i, Printer in ipairs(M.Printer.types[col]) do
            if Printer:is_a(row[col], row) then
                return string.format(self.format_string, self.cols:index(col), i, val)
            end
        end
    end):filter(function(s)
        return s ~= nil and #s > 0
    end):join(self.delimiter)
end

function M.Printer:for_terminal(str, post_string)
    post_string = post_string or ""

    local indent, str = str:match("(%s*)(.*)")

    local parts = List()
    for i, s in ipairs(str:split(self.delimiter)) do
        s = self:_for_terminal(s, i == 1)

        if s and #s > 0 then
            parts:append(s)
        end
    end

    if #parts > 0 then
        return indent .. parts:join(self.terminal_delimiter) .. post_string
    end

    return ""
end

function M.Printer:_for_terminal(s, is_first)
    local col_index, type_index, val = s:match(self.regex)
    if col_index and type_index and val then
        local col = self.cols[tonumber(col_index)]
        local Printer = self.types[col][tonumber(type_index)]
        return Printer:for_terminal(val, is_first)
    end
end

return M
