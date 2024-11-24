return {
    name = "metadata",
    alias = "on",
    {
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
    },
    {"-p --path", default = Path.cwd(), convert = Path.from_cli},
    {"+i", target = "include_instances", description = "include instances", switch = "on"},
    {"+I", target = "instances_only", description = "only print instances", switch = "on"},
    {"+a", target = "by_attribute", description = "by attribute", switch = "on"},
    {"+V", target = "include_attribute_values", description = "exclude attribute values", switch = "off"},
    -- print = require("htc.Metadata.Ontology"),
    action = function(args)
        args.conditions = require("htl.Metadata.Conditions"):new(args.conditions, args.path)
        args.conditions.conditions:foreach(Dict.print)
        print(args.conditions.urls)
    end,
}
