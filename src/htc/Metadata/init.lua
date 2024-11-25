local Conditions = require("htl.Metadata.Conditions")
local TerminalLink = require("htl.text.TerminalLink")

local conditions_arg = {
    "conditions",
    args = "*",
    default = List(),
    action = "concat",
    description = List({
        "filter conditions:",
        "    x      [x = str]        →   predicate: x",
        "    x      [x = path]       →   object: x",
        "   +x      [x = str]        →   predicate: *x",
        "    x+     [x = str]        →   predicate: x*",
        "   :x      [x = str]        →   predicate: *.x",
        "   #x      [x = str|path]   →   predicate: subset|instance, object: x",
        "    x!     [x = query]      →   exclude x",
        "    x~     [x = query]      →   recursively match x",
        "    x, y                    →   x|y",
    }):join("\n"),
}

return {
    name = "metadata",
    {"-p --path", default = Path.cwd(), convert = Path.from_cli},
    commands = {
        query = {
            alias = "q",
            conditions_arg,
            {"+f", target = "as_file", description = "print as files", switch = "on"},
            print = function(args)
                args.conditions = Conditions:new(args.conditions, args.path)

                local urls = DB.urls:get({where = {id = args.conditions.urls}}):sorted(function(a, b)
                    return a.path < b.path
                end)

                local format_fn
                if args.as_file then
                    format_fn = function(url) return args.path and url.path:relative_to(args.path) or url.path end
                else
                    format_fn = function(url) return TerminalLink({url = url.id, label = url.label}) end
                end

                return urls:map(format_fn):join("\n")
            end,
        },
        predicates = {
            alias = "pred",
            conditions_arg,
            {"+a", target = "all_predicates", description = "print all predicates", switch = "on"},
            {"+i", target = "print_instances", description = "print instances", switch = "off"},
            {"+o", target = "print_objects", description = "print objects", switch = "off"},
            {"-n --min", convert = tonumber},
            {"-m --max", convert = tonumber},
            print = function(args)
                local conditions = Conditions:new(args.conditions, args.path)
                local rows = conditions.rows

                local urls_by_id = {}

                local function get_url(id)
                    urls_by_id[id] = urls_by_id[id] or DB.urls:where({id = id})
                    return urls_by_id[id]
                end

                local predicate_to_rows = Dict():set_default(List)
                rows:foreach(function(row)
                    local key = row.predicate

                    if row.object then
                        if args.print_objects then
                            key = key .. Conf.Metadata.subpredicate_sep .. tostring(row.object)
                        else
                            return
                        end
                    end

                    predicate_to_rows[key]:append(row)
                end)

                if args.min then
                    predicate_to_rows:filterv(function(_rows) return #_rows >= args.min end)
                end

                if args.max then
                    predicate_to_rows:filterv(function(_rows) return #_rows <= args.max end)
                end

                local lines = List()
                local printed_keys = Dict()
                predicate_to_rows:keys():sort():foreach(function(key)
                    local parts = key:split(Conf.Metadata.subpredicate_sep)

                    local is_object
                    local indent
                    local line
                    local sublines = List()
                    for i = 1, #parts do
                        local subpart = parts[i]
                        local subkey = parts:slice(1, i):join(Conf.Metadata.subpredicate_sep)

                        if not printed_keys[subkey] then
                            local subindent = (" "):rep(#subkey - #subpart)
                            line = subindent .. subpart .. ":"
                            indent = #line

                            if subpart:match("^%d*$") then
                                local url = get_url(tonumber(subpart))
                                line = subindent .. tostring(TerminalLink({url = url.id, label = url.label .. ":"}))
                                indent = #subindent + #url.label + 2
                                is_object = true
                            end

                            sublines:append(line)
                        end

                        printed_keys[subkey] = true
                    end

                    if args.print_instances then
                        local instances = predicate_to_rows[key]:map(function(row)
                            local url = get_url(row.subject)
                            return tostring(TerminalLink({url = url.id, label = url.label}))
                        end)

                        if #instances == 1 and not is_object then
                            sublines[#sublines] = line .. " " .. instances[1]
                        else
                            sublines:extend(instances:map(function(i) return (" "):rep(indent) .. i end))
                        end
                    end

                    lines:extend(sublines)
                end)

                return lines:join("\n")
            end,
        },
        ontology = {
            alias = "on",
            conditions_arg,
            {"+i", target = "include_instances", description = "include instances", switch = "on"},
            print = require("htc.Metadata.Ontology"),
        }
    },
}
