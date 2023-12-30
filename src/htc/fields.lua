local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")

local fields_to_exclude = List({"date"})

function get_print_lines(dict)
    local lines = List()
    dict:keys():sorted():foreach(function(k)
        local v = dict[k]
        local sublines = List()
        
        if v:is_a(List) then
            sublines = Set.values(Set(v)):sorted()
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

function is_field(line) return line:match(":") end

function parse_field_and_value(line)
    local field, value
    if line:match(":") then
        field, value = unpack(line:split(":", 1))
        field = field:strip()
        value = value:strip()
    else
        field = line
    end

    return field, value
end

function parse_fields(raw)
    local fields = Dict()

    List(raw):foreach(function(line)
        local field, value = parse_field_and_value(line)

        fields:default(field, Set())

        if value ~= nil then
            fields[field] = fields[field] + value
        end
    end)

    return fields
end

return {
    description = "list fields",
    {"fields", args = "*", default = Dict(), description = "the field to look for", action="concat"},
    {"-d --dir", default = Path.cwd(), description = "directory", convert=Path.as_path},
    {"+f", target = "files", description = "list files", switch = "on"},
    action = function(args)
        local fields = parse_fields(args.fields)
        local has_fields = #fields:keys() > 0

        local path_to_metadata = Dict()
        args.dir:glob("%.md$"):foreach(function(path)
            local metadata = Dict()
            List(Yaml.read_raw_frontmatter(path)):foreach(function(line)
                if is_field(line) then
                    local field, value = parse_field_and_value(line)

                    if not fields_to_exclude:contains(field) then
                        metadata[field] = value
                    end
                end
            end)

            path_to_metadata[tostring(path:relative_to(args.dir))] = metadata
        end)

        fields:foreach(function(field, values)
            path_to_metadata:foreach(function(path, metadata)
                if metadata[field] == nil then
                    path_to_metadata[path] = nil
                elseif #Set.values(values) > 0 and not values[metadata[field]] then
                    path_to_metadata[path] = nil
                end
            end)
        end)

        local data = Dict()
        path_to_metadata:foreach(function(path, metadata)
            metadata:foreach(function(field, value)
                if has_fields then
                    if fields:keys():contains(field) then
                        local values = fields[field]

                        if #Set.values(values) == 0 then
                            data:default(field, List())

                            if args.files then
                                value = path
                            end

                            data[field]:append(value)
                        elseif values[value] then
                            data:default(field, Dict())
                            data[field]:default(value, List())
                            data[field][value]:append(path)
                        end
                    end
                else
                    data:default(field, List())

                    if args.files then
                        value = path
                    end

                    data[field]:append(value)
                end
            end)
        end)

        get_print_lines(data):foreach(print)
    end,
}
