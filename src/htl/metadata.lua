local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")

local class = require("pl.class")

local Link = require("htl.text.Link")
local Project = require("htl.project")
local Snippet = require("htl.snippet")
local Config = require("htl.config")
local MetadataConfig = Config.get("metadata")
local Divider = require("htl.text.divider")

local FIELDS_TO_EXCLUDE = Set({
    "date",
    "on page",
    tostring(Divider("large", "metadata")),
})

--------------------------------------------------------------------------------
--                                   Field                                    --
--------------------------------------------------------------------------------
class.Field()
Field.metadata_key = "fields"
Field.delimiter = MetadataConfig.field_delimiter
Field.exclusions = List(MetadataConfig.excluded_fields):extend({tostring(Divider("large", "metadata"))})
Field.indent = "    "

function Field.is_a(str)
    return str:match(Field.delimiter) and not str:endswith(Field.delimiter)
end
function Field:parse(str) return str:split(self.delimiter, 1):mapm("strip") end

function Field:_init(str)
    self.key, self.val = unpack(self:parse(str))
end

function Field:add_to_metadata(metadata)
    metadata:default_dict(self.metadata_key)
    if not self:should_exclude() then
        metadata[self.metadata_key][self.key] = self.val
    end
end

function Field:should_exclude()
    if self.exclusions:contains(self.key) then
        return true
    end

    if tonumber(self.key) then
        return true
    end

    return false
end

function Field:check_metadata(metadata)
    metadata:default_dict(self.metadata_key)
    return metadata:get(self.metadata_key)[self.key] == self.val
end

function Field.gather(existing, new)
    new = new or Dict()
    new:foreach(function(key, val)
        existing:default(key, Set())
        existing[key] = existing[key] + val
    end)

    return existing
end

function Field.get_print_lines(gathered)
    local lines = List()

    gathered:foreach(function(key, vals)
        vals = Set.values(vals)

        if #vals > 0 then
            lines:append(Field.indent .. key .. ":")
            vals:sorted():foreach(function(val)
                lines:append(string.rep(Field.indent, 2) .. tostring(val))
            end)
        else
            lines:append(Field.indent .. key)
        end
    end)

    return lines
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
    self.key, self.val = unpack(self:parse(str))
    self.val = Link.from_str(str).location
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
    metadata:default_dict(unpack(List({self.metadata_key}):extend(self.val)))
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

        return lines:append(Tag.indent .. line)
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
function File:_init(path, project_root)
    self.path = path
    self.project_root = project_root
    self.metadata = Dict()
    List(Yaml.read_raw_frontmatter(path)):foreach(function(line)
        self:parse_line(line)
    end)

    self.references = self:set_references_list(self.metadata.references or Dict())
end

function File:parse_line(line)
    local parser
    self.LineParsers:foreach(function(LineParser)
        if not parser and LineParser.is_a(line) then
            parser = LineParser
        end
    end)

    if parser then
        parser(line):add_to_metadata(self.metadata)
    end
end

function File:set_references_list(references_dict)
    return Set(references_dict:values():transform(function(reference)
        return tostring(self.project_root:join(reference))
    end))
end

function File:check_conditions(conditions)
    local result = true
    if #conditions >= 0 then
        List(conditions):foreach(function(condition)
            if result then
                result = condition:check(self.metadata)
            end
        end)
    end

    return result
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
        return file.references[tostring(reference)]
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
        Set.values(path_references[path]):foreach(function(reference)
            if path_references[reference] then
                file.references = file.references + path_references[reference]
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
            lines:append(key .. ":")
            lines:extend(parser_lines)
        end
    end)

    return lines
end

function Files:get_files(args)
    return self.path_to_file:keys():transform(Path):mapm("relative_to", self.dir):transform(tostring)
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
