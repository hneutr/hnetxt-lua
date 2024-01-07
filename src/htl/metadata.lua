local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("hl.Set")
local Yaml = require("hl.yaml")

local class = require("pl.class")

local Link = require("htl.text.Link")
local Project = require("htl.project")
local Config = require("htl.config")
local MetadataConfig = Config.get("metadata")
local Divider = require("htl.text.divider")

--[[
so, we keep the parsing exactly the same
then, when it comes time to print:

only for fields do we do this; tags can be assigned in a context, but can't have their own context

when we are adding something to the context, we look at the field.key of the context

we loop over the file metadata lines:
- when we see a line, we parse that line and add it to the parent context
- we set the child context to the line


example:

document 1:
    is a: answer
        to: [abc](abc)
        @ego
    @remind
document 2:
    is a: quote
        of: [xyz](xyz)
        @humor
    @remind

should produce the following tagmap (showing references):
    is a:
        answer:
            to:
                [abc](abc)
            @ego
        quote:
            of: 
                [xyz](xyz)
            @humor
    @remind
--]]

--------------------------------------------------------------------------------
--                                   Field                                    --
--------------------------------------------------------------------------------
class.Field()
Field.metadata_key = "fields"
Field.delimiter = MetadataConfig.field_delimiter
Field.or_delimiter = MetadataConfig.field_or_delimiter
Field.exclusions = List(MetadataConfig.excluded_fields):extend({tostring(Divider("large", "metadata"))})
Field.indent = "    "
Field.indent_step = 2

function Field.is_a(str)
    return str:match(Field.delimiter) and not str:endswith(Field.delimiter) and not str:strip():startswith("-")
end
function Field:parse(str)
    local key, vals = unpack(str:split(self.delimiter, 1):mapm("strip"))
    return {key, List(vals:split(self.or_delimiter))}
end

function Field:_init(str)
    self.key, self.vals = unpack(self:parse(str))
end

function Field:add_to_metadata(metadata)
    if self:should_include() then
        self.vals:foreach(function(val)
            metadata:set({self.metadata_key, self.key, val})
        end)
    end
end

function Field:should_include()
    return not List({
        self.exclusions:contains(self.key),
        tonumber(self.key)
    }):any()
end

function Field:check_metadata(metadata)
    if metadata:has(self.metadata_key, self.key) then
        local shared = Set(self.vals) * Set(metadata:get(self.metadata_key, self.key):keys())
        return not shared:isempty()
    end

    return false
end

function Field.gather(existing, new)
    existing = existing or Dict()
    Dict(new):foreach(function(key, vals)
        existing:default(key, Set()):add(Dict(vals):keys())
    end)

    return existing
end

function Field.get_print_lines(gathered)
    local lines = List()

    gathered:keys():sorted():foreach(function(key)
        local sublines = gathered[key]:values():sorted():transform(function(v)
            return Field.indent .. tostring(v)
        end)

        if #sublines > 0 then
            lines:append(key .. ":")
            lines:extend(sublines)
        else
            lines:append(key)
        end
    end)

    return lines
end

-- TODO: this function is intended for use with detecting nested fields/tags
function Field.line_level(str)
    return #str - #str:lstrip()
end

-- TODO: this function is intended for use with detecting nested fields/tags
function Field.line_level_up(str)
    return math.max(0, Field.line_level(str) - Field.indent_step)
end

--------------------------------------------------------------------------------
--                                 BlankField                                 --
--------------------------------------------------------------------------------
class.BlankField(Field)

function BlankField.is_a(str) return true end
function BlankField:_init(str) 
    self.key = str
end

function BlankField:check_metadata(metadata)
    return metadata:has(self.metadata_key, self.key)
end

--------------------------------------------------------------------------------
--                                 MReference                                 --
--------------------------------------------------------------------------------
class.MReference(Field)
MReference.metadata_key = "references"
function MReference.is_a(str) return Field.is_a(str) and Link.str_is_a(str) end

function MReference:_init(str)
    self.key, self.vals = unpack(self:parse(str))
    self.vals:transform(function(val)
        return Link.from_str(val).location
    end)
end

--------------------------------------------------------------------------------
--                                    Tag                                     --
--------------------------------------------------------------------------------
class.Tag(Field)
Tag.metadata_key = "tags"
Tag.prefix = MetadataConfig.tag_prefix
Tag.delimiter = MetadataConfig.tag_delimiter

function Tag.is_a(str) return str:startswith(Tag.prefix) end

function Tag:_init(str)
    self.val = str:removeprefix(Tag.prefix):split(Tag.delimiter):mapm("strip")
end

function Tag:add_to_metadata(metadata)
    metadata:set(List({self.metadata_key}):extend(self.val))
end

function Tag:check_metadata(metadata)
    return metadata:has(unpack(List({self.metadata_key}):extend(self.val)))
end

function Tag.gather(existing, new)
    return existing:update(new)
end

function Tag.get_print_lines(gathered)
    local lines = List()

    Tag._get_print_lines(gathered):foreach(function(line)
        if not line:startswith(" ") then
            line = Tag.prefix .. line
        else
            line = " " .. line
        end

        return lines:append(line)
    end)

    return lines
end

function Tag._get_print_lines(dict)
    local lines = List()
    dict:transformk(tostring):keys():sorted():foreach(function(k)
        local v = Dict(dict[k])
        local sublines = List()
        
        if #v:values() then
            sublines = Tag._get_print_lines(v)
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
--                                    File                                    --
--------------------------------------------------------------------------------
class.File()
File.LineParsers = List({Tag, MReference, Field})
File.metadata_divider = tostring(Divider("large", "metadata"))
function File:_init(path, project_root)
    self.path = path
    self.project_root = project_root
    self.metadata = Dict()
    self:read(self.path):foreach(function(line)
        self:parse_line(line)
    end)

    self.references = self:set_references_list(self.metadata.references or Dict())
end

function File:read(path)
    local lines = Yaml.read_raw_frontmatter(path)
    local divider_index = lines:index(File.metadata_divider)

    if divider_index then
        lines:chop(divider_index, #lines)
    end

    return lines
end

function File:parse_line(line)
    for LineParser in self.LineParsers:iter() do
        if LineParser.is_a(line) then
            LineParser(line):add_to_metadata(self.metadata)
            return
        end
    end
end

function File:set_references_list(references_dict)
    local references_list = Set()
    references_dict:values():foreach(function(references_d)
        references_list:add(references_d:keys():transform(function(r)
            return tostring(self.project_root:join(r))
        end))
    end)

    return references_list
end

function File:check_conditions(conditions)
    if #conditions >= 0 then
        for condition in List(conditions):iter() do
            if not condition:check(self.metadata) then
                return false
            end
        end
    end

    return true
end

--------------------------------------------------------------------------------
--                                 condition                                  --
--------------------------------------------------------------------------------
class.Condition()
Condition.Parsers = List({Tag, Field, BlankField})
Condition.exclusion_suffix = MetadataConfig.exclusion_suffix

function Condition:_init(str)
    str, self.is_exclusion = self:parse_exclusion(str)
    self:parse(str)
end

function Condition:parse_exclusion(str)
    return str:removesuffix(self.exclusion_suffix), str:endswith(self.exclusion_suffix)
end

function Condition:parse(str)
    self.Parsers:foreach(function(Parser)
        if not self.parser and Parser.is_a(str) then
            self.parser = Parser(str)
        end
    end)
end

function Condition:check(file)
    local result = self.parser:check_metadata(file)

    if self.is_exclusion then
        result = not result
    end

    return result
end

--------------------------------------------------------------------------------
--                                   Files                                    --
--------------------------------------------------------------------------------
class.Files()
Files.Parsers = List({Field, MReference, Tag})

function Files:_init(args)
    self.dir = Path(args.dir)
    self.project_root = Project.root_from_path(self.dir)
    self.path_to_file = self.read_files(self.dir, self.project_root)
    self:filter(args)
end

function Files.read_files(dir, project_root)
    local path_to_file = Dict()
    dir:glob("%.md$"):foreach(function(path)
        path_to_file[tostring(path)] = File(path, project_root)
    end)
    return path_to_file
end

function Files:filter(args)
    if args.conditions then
        self:filter_by_conditions(args.conditions)
    end

    if args.reference then
        self:filter_by_reference(args.reference)
    end
end

function Files:filter_by_conditions(conditions)
    List(conditions):transform(Condition)

    self.path_to_file:filterv(function(file)
        return file:check_conditions(conditions)
    end)
end

function Files:filter_by_reference(reference)
    if not reference:is_relative_to(self.project_root) then
        reference = reference:relative_to(self.project_root)
    end

    self:follow_references()
    self.path_to_file:filterv(function(file)
        return file.references:has(tostring(reference))
    end)
end

function Files:follow_references()
    local path_references = Dict()

    self.project_root:glob("%.md$"):foreach(function(path)
        local path_str = tostring(path)
        local file = self.path_to_file[path_str] or File(path, self.project_root)
        path_references[path_str] = file.references or Set()
    end)

    self.path_to_file:foreach(function(path, file)
        path_references[path]:foreach(function(reference)
            if path_references[reference] then
                file.references:add(path_references[reference])
            end
        end)
    end)
end

function Files:get_map(args)
    args = Dict.update(args or {}, {tags = true, fields = true, references = false})

    local Parsers = self.Parsers:clone():filter(function(Parser)
        return args[Parser.metadata_key]
    end)

    local map = Dict()
    Parsers:foreach(function(Parser)
        map[Parser.metadata_key] = Dict()
    end)

    self.path_to_file:values():foreach(function(file)
        Parsers:foreach(function(Parser)
            local key = Parser.metadata_key
            map[key] = Parser.gather(map[key], file.metadata[key])
        end)
    end)

    local lines = List()
    Parsers:foreach(function(Parser)
        local key = Parser.metadata_key
        local parser_lines = Parser.get_print_lines(map[key])
        if #parser_lines > 0 then
            lines:extend(parser_lines)
        end
    end)

    return lines
end

function Files:get_files(args)
    return self.path_to_file:keys():sorted():transform(Path):mapm("relative_to", self.dir):transform(tostring)
end

function Files:get_random_file()
    math.randomseed(os.time())
    local paths = self.path_to_file:keys()
    local v = math.random()
    local index = math.random(1, #paths)
    return Path(paths[index])
end

return {
    Field = Field,
    BlankField = BlankField,
    Tag = Tag,
    MReference = MReference,
    Condition = Condition,
    File = File,
    Files = Files,
}
