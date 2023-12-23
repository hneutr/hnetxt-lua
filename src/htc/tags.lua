local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")

local TAG_PREFIX = "@"
local TAG_SEPARATOR = "."

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

        sublines:transform(function(subline)
            local pad = string.rep(" ", #k)
            if subline:match("%.") then
                pad = pad .. " "
            else
                pad = pad .. "."
            end
            return pad .. subline
        end)

        if #sublines > 0 then
            lines:append(k)
            lines:extend(sublines)
        else
            lines:append(k)
        end
    end)

    return lines
end

function parse_tags_from_path(path)
    local tags_map = Dict()
    List(Yaml.read_raw_frontmatter(path)):filter(function(line)
        return line:startswith(TAG_PREFIX)
    end):transform(function(line)
        return line:removeprefix(TAG_PREFIX)
    end):filter(function(tags_string)
        return #tags_string > 0
    end):foreach(function(tags_string)
        tags_map:default_dict(unpack(tags_string:split(TAG_SEPARATOR)))
    end)
            
    return tags_map
end

function parse_tags(raw)
    local tags_map = Dict()

    List(raw):foreach(function(tags_string)
        tags_map:default_dict(unpack(tags_string:split(TAG_SEPARATOR)))
    end)

    return tags_map
end

function check_tag_match(tags_to_match, tags)
    local match = true
    tags_to_match:foreach(function(tag, subtags_to_match)
        if tags:keys():contains(tag) and match then
            match = check_tag_match(subtags_to_match, tags[tag])
        else
            match = false
        end
    end)

    return match
end

return {
    description = "list tags",
    {"tags", args = "*", default = List(), description = "the tag to look for", action="concat"},
    {"-d --dir", default = Path.cwd(), description = "directory", convert=Path.as_path},
    {"+f", target = "files", description = "list files", switch = "on"},
    action = function(args)
        local tags = parse_tags(args.tags)

        local path_to_tags = Dict()
        args.dir:glob("%.md$"):foreach(function(path)
            path_to_tags[path:relative_to(args.dir)] = parse_tags_from_path(path)
        end)

        if #tags:keys() > 0 then
            path_to_tags:filterv(function(path_tags)
                return check_tag_match(tags, path_tags)
            end)
        end

        if args.files then
            path_to_tags:keys():foreach(print)
        else
            local tags_map = Dict.fromlist(path_to_tags:values())
            get_print_lines(tags_map):foreach(print)
        end
    end,
}
