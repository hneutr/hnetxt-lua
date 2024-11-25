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
            print = function(args)
                local conditions = Conditions:new(args.conditions, args.path)
                return ""
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
