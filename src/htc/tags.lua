local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")
local Link = require("htl.text.Link")
local Project = require("htl.project")
local Snippet = require("htl.snippet")
local Config = require("htl.config")

local EXCLUSION_SUFFIX = "!"

local TAG_PREFIX = "@"
local TAG_SEPARATOR = "."

local FIELD_DELIMITER = ":"
local FIELDS_TO_EXCLUDE = Set({"date"})

function get_print_lines(dict)
    local lines = List()
    dict:transformk(tostring):keys():sorted():foreach(function(k)
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
function is_field(str) return str:match(FIELD_DELIMITER) end

function parse_field_string(field)
    local value

    if field:match(FIELD_DELIMITER) then
        field, value = unpack(field:split(FIELD_DELIMITER, 1):mapm("strip"))

        if Link.str_is_a(value) then
            value = Path(Link.from_str(value).location)
        end
    end

    if FIELDS_TO_EXCLUDE[field] then
        return List({})
    end

    return List({field, value})
end

--------------------------------------------------------------------------------
--                                                                            --
--                                    tags                                    --
--                                                                            --
--------------------------------------------------------------------------------
function is_tag(str) return str:startswith(TAG_PREFIX) end
function is_exclusion(str) return str:endswith(EXCLUSION_SUFFIX) end

function parse_tags_string(str)
    str = str:removeprefix(TAG_PREFIX)
    str = str:removesuffix(EXCLUSION_SUFFIX)
    return str:split(TAG_SEPARATOR)
end

function parse_file_tags(path)
    local tags = Dict()
    List(Yaml.read_raw_frontmatter(path)):filter(is_tag):foreach(function(str)
        tags:default_dict(unpack(parse_tags_string(str)))
    end)
            
    return tags
end

--------------------------------------------------------------------------------
--                                                                            --
--                               file metadata                                --
--                                                                            --
--------------------------------------------------------------------------------
function parse_metadata_string(str)
    if is_tag(str) then
        return parse_tags_string(str)
    end
    
    return parse_field_string(str)
end

function parse_metadata(path)
    local metadata = Dict()
    List(Yaml.read_raw_frontmatter(path)):transform(
        parse_metadata_string
    ):filter(function(m)
        return #m > 0
    end):foreach(function(m)
        metadata:default_dict(unpack(m))
    end)
            
    return metadata
end

function get_path_to_metadata(dir, conditions)
    local path_to_metadata = Dict()
    dir:glob("%.md$"):foreach(function(path)
        path_to_metadata[path] = parse_metadata(path)
    end)

    path_to_metadata:filterv(check_conditions, conditions)

    return path_to_metadata
end

--------------------------------------------------------------------------------
--                                                                            --
--                            checking conditions                             --
--                                                                            --
--------------------------------------------------------------------------------
function check_conditions(metadata, conditions)
    local match = true
    List(conditions):foreach(function(condition_string)
        if match then
            local tags = parse_metadata_string(condition_string)

            if is_exclusion(condition_string) then
                match = not metadata:has(unpack(tags))
            else
                match = metadata:has(unpack(tags))
            end
        end
    end)

    return match
end

--------------------------------------------------------------------------------
--                                                                            --
--                                x-of-the-day                                --
--                                                                            --
--------------------------------------------------------------------------------
function set_x_of_the_day()
    local config = Config.get("x-of-the-day")
    local data_dir = Config.data_dir:join(config.data_dir)

    List(config.commands):foreach(function(command)
        local output_path = data_dir:join(command.name, os.date("%Y%m%d"))

        if not output_path:exists() or 1 then
            local path = get_random_path(get_path_to_metadata(Path(command.dir), command.conditions))
            output_path:write(tostring(Snippet(path)))
        end
    end)
end

function get_random_path(path_to_metadata)
    local paths = path_to_metadata:keys()
    local index = math.random(1, #paths)
    return paths[index]
end

return {
    description = "list tags",
    {
        "conditions",
        args = "*",
        default = List(),
        description = "the conditions to meet (fields:value?/@tag.subtag/exclusion!)", 
        action="concat",
    },
    {"-d --dir", default = Path.cwd(), description = "directory", convert=Path.as_path},
    {"+f", target = "files", description = "list files", switch = "on"},
    {"+r", target = "random", description = "print random", switch = "on"},
    {"+x", target = "x_of_the_day", description = "run the x-of-the-day", switch = "on"},
    action = function(args)
        if args.x_of_the_day then
            return set_x_of_the_day()
        end
        
        local path_to_metadata = get_path_to_metadata(args.dir, args.conditions)

        if args.random then
            print(Snippet(get_random_path(path_to_metadata)))
        elseif args.files then
            path_to_metadata:keys():mapm("relative_to", args.dir):foreach(print)
        else
            get_print_lines(Dict.fromlist(path_to_metadata:values())):foreach(print)
        end
    end,
}
