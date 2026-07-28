local Conditions = require("htl.Metadata.Conditions")
local TerminalLink = require("htl.text.TerminalLink")

local M = {
    sep = Conf.Metadata.subpredicate_sep,
    urls_by_id = {},
}

function M.get_url(id)
    M.urls_by_id[id] = M.urls_by_id[id] or DB.urls:where({id = id})
    return M.urls_by_id[id]
end

function M.get_url_string(id, as_predicate)
    id = type(id) == "string" and tonumber(id) or id
    local url = M.get_url(id)
    local post = as_predicate and ":" or ""
    return tostring(TerminalLink({url = url.id, label = url.label .. post}))
end

M.key = {}

function M.key.from_row(row)
    return ("%s#%d"):format(
        List({
            row.predicate,
            row.object and M.get_url(row.object).label or nil,
        }):join(M.sep),
        row.object or 0
    )
end

function M.key.is_object(key)
    return not key:endswith("#0")
end

function M.key.indent(key)
    if key:find(M.sep, 1, true) then
        local pre, key = unpack(key:rsplit(M.sep, 1))
        return (" "):rep(#pre + 1) .. key
    end
    return key
end

function M.key.display_key(key)
    local id
    key, id = unpack(key:rsplit("#", 1))
    local pre = key:rsplit(M.sep, 1)[1]
    return (" "):rep(#pre) .. M.get_url_string(id, true)
end

function M.filter(predicate_to_rows, args)
    if not args.include_objects then
        predicate_to_rows:filterk(function(key) return not M.key.is_object(key) end)
    end

    if args.min then
        predicate_to_rows:filterv(function(rows) return #rows >= args.min end)
    end

    if args.max then
        predicate_to_rows:filterv(function(rows) return #rows <= args.max end)
    end

    return predicate_to_rows
end

return {
    alias = "p",
    Conditions.cli,
    {"+a", target = "all_predicates", switch = "on", description = "print all predicates of found instances"},
    {"+i", target = "include_instances", switch = "off", description = "print instances"},
    {"+o", target = "include_objects", switch = "off", description = "print objects"},
    {"-n --min", convert = tonumber, description = "min instances"},
    {"-m --max", convert = tonumber, description = "max instances"},
    {"-p --path", convert = Path.from_cli, default = Path.cwd()},
    print = function(args)
        local conditions = Conditions:new(args.conditions, args.path)

        -- TODO: all_predicates
        local rows = conditions.rows

        local key_to_rows = Dict():set_default(List)
        rows:foreach(function(row) key_to_rows[M.key.from_row(row)]:append(row) end)

        key_to_rows = M.filter(key_to_rows, args)

        local lines = List()
        local printed_keys = Dict()
        key_to_rows:keys():sort():foreach(function(key)
            local parts = key:split(M.sep)

            for i = 1, #parts do
                local subkey = parts:slice(1, i):join(M.sep)

                if not printed_keys[subkey] then
                    printed_keys[subkey] = true

                    if subkey == key and M.key.is_object(key) then
                        subkey = M.key.display_key(key)
                    else
                        subkey = M.key.indent(subkey:removesuffix("#0")) .. ":"
                    end

                    lines:append(subkey)
                end
            end

            if args.include_instances then
                local _rows = key_to_rows[key]
                if #_rows == 1 and not M.key.is_object(key) then
                    lines[#lines] = lines[#lines] .. " " .. M.get_url_string(_rows[1].subject)
                else
                    local indent = (" "):rep(#key:rsplit("#", 1)[1])
                    lines:extend(_rows:map(function(row)
                        return indent .. M.get_url_string(row.subject)
                    end):sorted())
                end
            end
        end)

        return lines:join("\n")
    end,
}
