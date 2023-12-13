local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")

function get_print_lines(dict)
    local lines = List()
    dict:keys():sorted():foreach(function(k)
        local v = dict[k]
        local sublines = List()
        
        if v:is_a(List) then
            sublines = v:sorted()
        elseif v:is_a(Dict) then
            sublines = get_print_lines(v)
        end

        sublines:transform(function(subline) return "    " .. subline end)

        if #sublines > 0 then
            lines:append(k .. ":")
            lines:extend(sublines)
        else
            lines:append(k)
        end
    end)

    return lines
end

return {
    description = "list fields",
    {"field", args = "?", description = "the field to look for"},
    {"-d --dir", default = Path.cwd(), description = "directory", convert=Path.as_path},
    {"-v --value", description = "restrict to this value"},
    {"+f", target = "files", description = "list files", switch = "on"},
    {"+l", target = "values", description = "list values", switch = "on"},
    action = function(args)
        local paths = args.dir:glob("%.md$")

        if args.value ~= nil then
            args.values = true
        end

        local data = Dict()
        paths:foreach(function(path)
            local path_str = tostring(path:relative_to(args.dir))

            List(Yaml.read_raw_frontmatter(path)):foreach(function(line)
                if line:match(":") then
                    local field, value = unpack(line:split(":", 1))
                    field = field:strip()
                    value = value:strip()

                    if not data[field] then
                        data[field] = Dict()
                    end

                    if not data[field][value] then
                        data[field][value] = List()
                    end

                    data[field][value]:append(path_str)
                end
            end)
        end)

        if args.field then
            data = data:filterk(function(field) return field == args.field end)
        end

        if args.value then
            data:foreachv(function(values_d)
                values_d:filterk(function(value) return value == args.value end)
            end)
        end

        if args.values and not args.files then
            data:transformv(function(values_d) return values_d:keys() end)
        elseif not args.values and args.files then
            data:transformv(function(values_d)
                local files = List()
                values_d:values():foreach(function(files_sublist)
                    files_sublist:foreach(function(file)
                        if not files:contains(file) then
                            files:append(file)
                        end
                    end)
                end)

                return files
            end)
        elseif not args.values and not args.files then
            data = data:transformv(function(_) return Dict() end)
        end

        get_print_lines(data):foreach(print)
    end,
}
