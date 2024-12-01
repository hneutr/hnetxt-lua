local Mirrors = require("htl.Mirrors")

local M = SqliteTable("Metadata", {
    id = true,
    subject = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    object = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
    },
    predicate = {
        type = "text",
        required = true,
    },
    source = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
})

M.conf = Conf.Metadata

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Reader                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.Reader = {}

function M.Reader.get_lines(path)
    local lines = M.Reader.separate_lines(M.Reader.read_lines(path))
    return lines:extend(M.Reader.read_lines(Mirrors:get_path(path, "metadata")))
end

function M.Reader.read_lines(path)
    if path and path:exists() then
        return path:readlines():map(function(l)
            if l:match(M.conf.comment_prefix) then
                l = l:gsub(M.conf.comment_prefix .. ".*", ""):rstrip()
                l = #l:strip() > 0 and l or nil
            end

            return l
        end):filter(function(l) return l end)
    end

    return List()
end

function M.Reader.separate_lines(lines)
    if #lines > 0 then
        local l1 = lines[1]
        if not l1:match(":") and not l1:startswith(M.conf.tag_prefix) then
            return List()
        end
    end

    for i, l in ipairs(lines) do
        if not M.Reader.keep_line(l) then
            return lines:chop(i, #lines)
        end
    end

    return lines
end

function M.Reader.keep_line(l)
    l = (l or ""):strip()
    return 0 < #l and #l <= M.conf.max_length
end
--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Parser                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.parse_vals(s)
    s = s or ""
    s = s:gsub(M.conf.tag_prefix, "")
    local vals = List()

    local quotes = List({'"', "'"})
    while #s > 0 do
        local first_char = s:sub(1, 1)
        local stop_char = quotes:contains(first_char) and first_char or ','
        s = s:removeprefix(stop_char)

        local val = s:sub(1, s:find(stop_char))
        s = s:sub(#val + 1):removeprefix(","):strip()
        vals:append(val:removesuffix(stop_char):strip())
    end

    return vals:filter(function(v) return #v > 0 end)
end

function M.parse_link(s)
    return type(s) == "string" and tonumber(s:match("%[.*%]%((%d*)%)")) or s
end

function M.elements_to_row(elements)
    local types = Dict():set_default(List)

    List(elements):map(M.parse_link):foreach(function(element)
        types[type(element)]:append(element)
    end)

    if #types.string == 0 then
        types.string:append(M.conf.default_predicate)
    end

    types.string:transform(function(s) return M.conf.predicate_remap[s] or s end)

    if #types.number > 1 then
        return
    end

    return Dict({
        predicate = types.string:join(M.conf.subpredicate_sep),
        object = #types.number > 0 and types.number[1] or nil
    })
end

function M.parse_elements(elements)
    local rows = List()

    local keys = List()
    List(elements):foreach(function(element)
        local vals = element

        if element:match(":") then
            local key
            key, vals = utils.parsekv(element)
            keys:append(key)
        end

        rows:extend(M.parse_vals(vals):map(function(v) return List(keys):append(v) end))
    end)

    if #rows == 0 then
        rows:append(List(keys))
    end

    return rows
end

function M.filter_duplicate_rows(rows)
    local duplicates = Dict():set_default(false)
    rows:foreach(function(row)
        if row and row.predicate and row.object then
            duplicates[row.predicate] = true
        end
    end)

    return rows:filter(function(row)
        local key = tostring(row)
        local duplicate = duplicates[key]
        duplicates[key] = true
        return row and not duplicate
    end)
end

function M.parse_lines(lines)
    local groups = List({{lines = List(lines), elements = List()}})

    local rows = List()
    while #groups > 0 do
        local group = groups:pop(1)

        if #group.lines == 0 then
            rows:extend(M.parse_elements(group.elements):map(M.elements_to_row))
        else
            group.lines:foreach(function(line)
                if line:startswith("  ") then
                    groups[#groups].lines:append(line:sub(3))
                else
                    groups:append({
                        lines = List(),
                        elements = List(group.elements):append(line),
                    })
                end
            end)
        end
    end

    return M.filter_duplicate_rows(rows)
end

function M.format_row(row, url)
    row.predicate = M.conf.predicate_remap[row.predicate] or row.predicate
    row.source = url.id
    row.subject = url.id

    if not row.object then
        local predicates = row.predicate:split(M.conf.subpredicate_sep)

        if #predicates == 2 and M.conf.taxonomy_predicates:contains(predicates[1]) then
            row.predicate = predicates[1]
            row.object = M.Taxonomy.get_url(predicates[2])
        end
    end
    return row
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 Taxonomies                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
--[[
how to extend to taxonomies:
- interpret "same line" as "instances are also"
- interpret rows differently, don't glom together keys, make "pseudofiles" for each and do subsets

thing
  artifact
    vehicle
      space ship
    space station
        instances are a: settlement ← element
        big space station

--]]
M.Taxonomy = {}

function M.Taxonomy.path_is_a(path)
    return path:name() == tostring(Conf.paths.taxonomy_file) or path == Conf.paths.global_taxonomy_file
end

function M.Taxonomy.group_to_rows(group)
    local rows = List()

    if group.object then
        rows:append({subject = group.subject, object = group.object, predicate = "subset"})
    end

    group.elements:foreach(function(element)
        local key, vals = utils.parsekv(element)

        M.parse_vals(vals):foreach(function(val)
            rows:append({subject = group.subject, object = M.parse_link(val), predicate = key})
        end)
    end)

    return rows
end

function M.Taxonomy.parse_lines(lines)
    local groups = List({{lines = List(lines), elements = List()}})

    local rows = List()
    while #groups > 0 do
        local group = groups:pop(1)

        group.lines:foreach(function(line)
            if line:startswith("  ") then
                line = line:sub(3)
                local key = line:match(":") and not line:startswith("  ") and "elements" or "lines"
                groups[#groups][key]:append(line)
            else
                groups:append({
                    lines = List(),
                    elements = List(),
                    subject = line,
                    object = group.subject,
                })
            end
        end)

        if group.subject then
            rows:extend(M.Taxonomy.group_to_rows(group))
        end
    end

    return rows
end

function M.Taxonomy.format_row(row, url)
    row.source = url.id
    row.subject = M.Taxonomy.get_url(row.subject)
    row.object = M.Taxonomy.get_url(row.object)
    return row
end


-- TODO: this is where we'd want to make nonglobal taxonomies
function M.Taxonomy.get_url(taxon, args)
    args = args or {}
    args.path = args.path or Conf.paths.global_taxonomy_file
    args.insert = args.insert == nil and true or false

    if type(taxon) == "number" then
        return taxon
    end

    local q = {
        path = args.path,
        label = taxon,
        type = "taxonomy_entry",
    }

    local row = DB.urls:where(q)

    if not row and args.insert then
        row = {id = DB.urls:insert(q)}
    end

    return row.id
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   record                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.Row = {
    cols = List({'subject', 'object', 'predicate'}),
    nil_val = "__NONE__",
    sep = ":",
}

function M.Row.tostring(row, cols)
    cols = not cols and M.Row.cols or List.as_list(cols)

    return cols:map(function(c)
        local val = row[c]
        val = type(val) == "table" and val.label or val
        return val or M.Row.nil_val
    end):join(M.Row.sep)
end

function M.Row.compare(a, b)
    if a == b then
        return false
    end

    local a_parts = a:split(M.Row.sep)
    local b_parts = b:split(M.Row.sep)

    for i, _a in ipairs(a_parts) do
        local _b = #b_parts >= i and b_parts[i] or M.Row.nil_val

        if _a ~= _b then
            if _a == M.Row.nil_val then
                return false
            elseif _b == M.Row.nil_val then
                return true
            elseif _a > _b then
                return false
            end
        end
    end

    return true
end

function M.get_rows(url)
    local parser = M
    local lines

    if M.Taxonomy.path_is_a(url.path) then
        parser = M.Taxonomy
        lines = url.path:readlines()
    else
        lines = M.Reader.get_lines(url.path)

        if #lines > 0 and lines[1]:strip() == "is a: taxonomy" then
            parser = M.Taxonomy
            lines = lines:slice(2)
        end
    end

    return parser.parse_lines(lines):transform(parser.format_row, url)
end

function M.record(url)
    if not url then
        return
    end

    if M:exists() then
        M:remove({source = url.id})
    end

    local rows = M.get_rows(url)

    if #rows > 0 then
        M:insert(rows)
        -- pass rows to `htl.db.Taxonomy.staleness.set`
    end

    M.set_quote_label(url)
end

function M.set_quote_label(url)
    local is_quote =  DB.Metadata:where({
        subject = url.id,
        object = M.Taxonomy.get_url("quote"),
        predicate = "instance",
    })

    if is_quote and DB.urls.has_default_label(url) and tonumber(url.label) then
        local source_row = DB.Metadata:where({subject = url.id, predicate = "source"})
        local source = source_row and DB.urls:where({id = source_row.object})

        if source then
            DB.urls:update({
                where = {id = url.id},
                set = {label = ("%s quote %s"):format(source.label, url.label)}
            })
        end
    end
end

function M.persist()
    DB.Metadata:drop()

    local urls = DB.urls:get({where = {type = "file"}}):sorted(function(a, b)
        return tostring(a.path) < tostring(b.path)
    end):foreach(function(u)
        print(u.path)
        M.record(u)
    end)
end

function M:get(q)
    return List(M:__get(q))
end

return M
