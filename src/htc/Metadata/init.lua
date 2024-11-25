local Conditions = require("htl.Metadata.Conditions")
local TerminalLink = require("htl.text.TerminalLink")

return {
    name = "metadata",
    commands = {
        query = {
            alias = "q",
            Conditions.cli,
            {"-p --path", default = Path.cwd(), convert = Path.from_cli},
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
        predicates = require("htc.Metadata.Predicates"),
        ontology = {
            alias = "on",
            Conditions.cli,
            {"+i", target = "include_instances", description = "include instances", switch = "on"},
            print = require("htc.Metadata.Ontology"),
        }
    },
}
