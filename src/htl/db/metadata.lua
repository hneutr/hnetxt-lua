local class = require("pl.class")

local Config = require("htl.Config")
local db_util = require("htl.db.util")

local Colorize = require("htc.Colorize")

local Parser = require("htl.metadata.Parser")
local Condition = require("htl.metadata.Condition")
local Taxonomy = require("htl.metadata.Taxonomy")

--[[
Currently, I am doing super weird shit with the taxonomy — I am parsing the rows into the taxonomy form

What if instead, I operated on things from the `taxonomy` perspective? What would that look like?
1. get the taxonomy
2. add in `is a` that _aren't_ in the taxonomy
3. for each value in the taxonomy, find the associated rows
4. percolate fields up the taxonomy chain via `get_is_a_to_ids`/`construct_taxonomy_key_map`
    - probably change this to only look at direct children of the `is_a` row
5. when printing:
    - print in taxonomy order:
        - if the taxonomy value has children, print it
        - if the taxonomy value has fields, print those

this involves the following:
- adding missing `is_a` values to the taxonomy
- basically removing `handle_is_a`
- modify `get_dict` behavior heavily:
    - should take a list of _value_ rows to be printed
        - maybe invert the parsing process?
            - store:
                key1: {
                    val1: {file1, file2, ...}
                    val2: {...},
                    ...
                },
                ...
]]


--[[
TODO:
- tag handing: group tags by @level1.level2.etc
]]

local M = require("sqlite.tbl")("metadata", {
    id = true,
    key = {
        type = "text",
        required = true,
    },
    val = {
        type = "text",
        required = false,
    },
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
        required = false,
    },
    datatype = {
        type = "text",
        required = false,
    },
})

M.conf = Conf.metadata
M.conf.excluded_fields = Set(M.conf.excluded_fields)
M.conf.direct_fields = Set(M.conf.direct_fields)
M.root_key = "__root"

function M:get(q)
    return List(M:__get(q))
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  reading                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.record(path)
    local url = DB.urls:get_file(path)

    if url then
        M:remove({url = url.id})
        M:insert_dict(Parser:get(path), url.id)
    end
end

function M:insert_dict(dict, url, parent)
    if not parent then
        local root = {key = M.root_key, url = url, datatype = 'root'}

        if not M:where(root) then
            M:insert(root)
        end
        
        parent = M:where(root).id
    end

    Dict(dict):foreach(function(key, raw)
        local row = {
            key = key,
            val = raw.val,
            url = url,
            parent = parent,
            datatype = raw.datatype,
        }

        M:insert(row)
        M:insert_dict(raw.metadata, url, M:where(row).id)
    end)
end

function M.record_missing(url_ids)
    url_ids = url_ids or DB.urls:get({where = {resource_type = "file"}}):col('id')
    url_ids = Set(url_ids):difference(M:get():col('url')):vals()
    
    if #url_ids == 0 then
        return
    end

    DB.urls:get({where = {id = url_ids}}):foreach(function(url)
        M.record(url.path)
    end)
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
        local urls = Set(DB.urls:get({
            where = {resource_type = "file"},
            contains = {path = string.format("%s*", args.path)},
        }):col('id'))

        rows = rows:filter(function(r) return urls:has(r.url) end)

        if args.record_missing then
            M.record_missing(urls:difference(rows:col('url')):vals())
        end
    end

    if args.reference then
        local urls = Set({args.reference})

        local references = rows:filter(function(r) return r.datatype == 'reference' end)
        local n_references = -1

        while n_references ~= #references do
            n_references = #references
            references = references:filter(function(row)
                if urls:has(tonumber(row.val)) then
                    urls:add(row.url)
                else
                    return true
                end
            end)
        end

        rows = rows:filter(function(r) return urls:has(r.url) end)
    end

    local taxonomy = Taxonomy(args.path)

    rows = Condition.filter(rows, args.conditions, taxonomy)

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

    if args.apply_taxonomy then
        rows = M.handle_is_a(rows, taxonomy)
    end

    return rows
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                big printing                                --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.get_dict(args)
    local rows = M:get_urls(args)
    local parent_ids = Set(rows:filter(function(r) return r.key == M.root_key end):col('id'))
    local id_to_keys = Dict()

    local d = Dict()
    local last_n = -1
    while #rows > 0 and #rows ~= last_n do
        last_n = #rows

        rows = rows:filter(function(r) return not parent_ids:has(r.id) end)

        local child_rows = rows:filter(function(r) return parent_ids:has(r.parent) end)
        parent_ids = Set(child_rows:col('id'))

        local included_vals_by_key = M.get_included_vals_by_key(
            child_rows,
            args.exclude_unique_values
        )

        child_rows:foreach(function(row)
            local keys = List(id_to_keys[tostring(row.parent)])
            keys:append(M.Printer:for_dict(row, "key"))
            id_to_keys[tostring(row.id)] = keys

            local row_d = d:get(unpack(keys)) or Dict()
            M.add_subkeys(row_d, row, included_vals_by_key, args)

            d:set(keys, row_d)
        end)
    end

    if args.is_a_only then
        local is_a = M.Printer:for_dict({key = M.conf.is_a_key}, "key")
        d = d[is_a]
    end

    return M:dict_string(d)
end

function M.get_included_vals_by_key(rows, exclude_unique_values)
    local to_include = Dict()
    rows:foreach(function(row)
        to_include:set({row.key, row.val or "", row.url})
    end)

    local threshold = exclude_unique_values and 1 or 0

    to_include:foreach(function(key, urls_by_val)
        urls_by_val:transformv(function(_urls)
            return #_urls:keys() > threshold
        end)
    end)

    return to_include
end

function M.add_subkeys(dict, row, included_vals_by_key, args)
    local include = Dict({
        val = args.include_values and included_vals_by_key[row.key][row.val or ""],
        url = args.include_urls,
    })

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

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    is a                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.handle_is_a(rows, taxonomy)
    local is_a_rows = rows:filter(function(r) return r.key == M.conf.is_a_key end)

    local is_a_to_ids = M:get_is_a_to_ids(rows, is_a_rows, taxonomy)

    local id_to_row = Dict()
    rows:foreach(function(r) id_to_row[r.id] = r end)
    
    local new_val_rows_by_val = Dict()
    is_a_to_ids:foreach(function(val, ids)
        new_val_rows_by_val[val] = Dict({
            id = val,
            key = val,
            parent = taxonomy.parents[val] or M.conf.is_a_key,
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

function M:get_is_a_to_ids(all_rows, is_a_rows, taxonomy)
    local rows = db_util.map_row_to_col(all_rows, is_a_rows, "parent", "_parent")

    local def_keys = Dict()
    local key_to_ids = Dict()

    Set(is_a_rows:col('val')):foreach(function(def)
        def_keys[def] = Set()
    end)

    -- probably should only do the DIRECT children of the `is_a` row
    -- (and then print the rest normally)
    rows:foreach(function(row)
        def_keys[row._parent.val]:add(row.key)
        key_to_ids:default(row.key, List()):append(row.id)
    end)

    def_keys = M:construct_taxonomy_key_map(def_keys, taxonomy)

    local def_ids = Dict()
    def_keys:foreach(function(def)
        def_ids[def] = List()
    end)

    rows:foreach(function(row)
        local def = row._parent.val
        while not def_keys[def]:contains(row.key) do
            def = taxonomy.parents[def]
        end

        def_ids[def]:append(row.id)
    end)
    
    return def_ids
end

function M:construct_taxonomy_key_map(def_keys, taxonomy)
    def_keys = Dict(def_keys)

    local generations = taxonomy.generations
    local parents = taxonomy.parents
    local descendants = taxonomy.descendants
    local children = taxonomy.children

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
        return l and not List({
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
    local url = DB.urls:where({id = tonumber(s)})

    if url then
        return DB.urls:get_reference(url):terminal_string(self:colors())
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
