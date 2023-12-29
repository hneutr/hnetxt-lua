local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")
local Snippet = require("htl.snippet")

local TAG_PREFIX = "@"
local TAG_SEPARATOR = "."
local FIELD_DELIMITER = ":"
local EXCLUSION_SUFFIX = "!"

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

--------------------------------------------------------------------------------
--                                                                            --
--                                   fields                                   --
--                                                                            --
--------------------------------------------------------------------------------
function filter_fields(str) return str:match(FIELD_DELIMITER) end

function parse_fields_string(str)
    local field, value

    if str:match(":") then
        field, value = unpack(str:split(":", 1))
        field = field:strip()
        value = value:strip()
    else
        field = str
    end

    return field, value
end


--------------------------------------------------------------------------------
--                                                                            --
--                                    tags                                    --
--                                                                            --
--------------------------------------------------------------------------------
function filter_tags(str) return str:startswith(TAG_PREFIX) end

function parse_tags_string(str)
    str = str:removeprefix(TAG_PREFIX)
    str = str:removesuffix(EXCLUSION_SUFFIX)
    return List(str:split(TAG_SEPARATOR))
end

function parse_file_tags(path)
    local tags = Dict()
    List(Yaml.read_raw_frontmatter(path)):filter(filter_tags):foreach(function(str)
        tags:default_dict(unpack(parse_tags_string(str)))
    end)
            
    return tags
end

function parse_tag_filters(raw, exclude)
    return List(raw):filter(function(str)
        return (exclude and str:endswith(EXCLUSION_SUFFIX)) or (not exclude and not str:endswith(EXCLUSION_SUFFIX))
    end):transform(parse_tags_string)
end

function check_tag_match(actual, expected, exclude)
    local match = true
    expected:foreach(function(tags)
        if match then
            if exclude then
                match = not actual:has(unpack(tags))
            else
                match = actual:has(unpack(tags))
            end
        end
    end)

    return match
end

return {
    description = "list tags",
    {"tags", args = "*", default = List(), description = "the tag to look for", action="concat"},
    {"-d --dir", default = Path.cwd(), description = "directory", convert=Path.as_path},
    {"+f", target = "files", description = "list files", switch = "on"},
    {"+r", target = "random", description = "print random", switch = "on"},
    action = function(args)
        local path_to_tags = Dict()
        args.dir:glob("%.md$"):foreach(function(path)
            path_to_tags[path:relative_to(args.dir)] = parse_file_tags(path)
        end)

        path_to_tags:filterv(check_tag_match, parse_tag_filters(args.tags))
        path_to_tags:filterv(check_tag_match, parse_tag_filters(args.tags, true), true)

        if args.random then
            local paths = path_to_tags:keys()
            local index = math.random(1, #paths)
            local path = paths[index]

            print(Snippet(args.dir:join(path)))
        elseif args.files then
            path_to_tags:keys():foreach(print)
        else
            local tags_map = Dict.fromlist(path_to_tags:values())
            get_print_lines(tags_map):foreach(print)
        end
    end,
}
