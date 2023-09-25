local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")

local exclusions = List({'.project'})

return {
    description = "list fields",
    {"field", args = "?", description = "the field to look for"},
    {"-d --dir", default = Path.cwd(), description = "directory"},
    action = function(args)
        local paths = Path.iterdir(args.dir, {dirs = false}):filter(function(p)
            return not exclusions:contains(p:name())
        end)

        local field_values = Dict()
        paths:foreach(function(path)
            List(Yaml.read_raw_frontmatter(tostring(path))):foreach(function(line)
                if line:match(":") then
                    local field, value = unpack(line:split(":", 1))
                    field = field:strip()
                    value = value:strip()

                    if field_values[field] == nil then
                        field_values[field] = Set()
                    end
                    
                    field_values[field] = field_values[field] + value
                end
            end)
        end)

        local to_print

        if args.field then
            print(args.field .. ":")
            to_print = Set.values(field_values[args.field]):map(function(v) return "    " .. v end)
        else
            to_print = field_values:keys()
        end

        to_print:sorted():foreach(print)
    end,
}
