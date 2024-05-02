local Divider = require("htl.text.divider")
local mirrors = require("htl.db.mirrors")
local Link = require("htl.text.Link")

local M = {}
M.conf = Dict(Conf.Taxonomy)
M.conf.relations = Dict(M.conf.relations)
M.conf.indent_size = "  "
M.conf.to_skip = Set({"on page", "page"})
M.conf.metadata = Dict(M.conf.metadata)
M.conf.metadata.divider = tostring(Divider("large", "metadata"))

function M.is_taxonomy_file(path)
    return path:name() == tostring(Conf.paths.taxonomy_file) or path == Conf.paths.global_taxonomy_file
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Metadata                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.get_metadata_lines(path)
    local lines = M.separate_metadata(path:readlines())
    local metadata_path = mirrors:get_path(path, "metadata")

    if metadata_path:exists() then
        lines:extend(metadata_path:readlines())
    end

    return lines
end

function M.separate_metadata(lines)
    if #lines > 0 and not lines[1]:match(":") then
        return List()
    end

    for i, l in ipairs(lines) do
        if not M.is_metadata_line(l) then
            return lines:chop(i, #lines)
        end
    end
    
    return lines
end

function M.is_metadata_line(l)
    l = l or ""
    l = l:strip()

    local result = true

    result = result and #l > 0
    result = result and #l <= M.conf.metadata.max_length
    result = result and l ~= divider
    
    return result or false
end


--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 Relations                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Relation = class()
Relation.contexts = Dict({
    file = true,
    taxonomy = true,
})

function Relation:line_is_a(l) return l and l:startswith(self.symbol) or false end

function Relation.parse_link(s)
    if type(s) == "string" then
        s = s:strip()

        local link = Link:from_str(s)

        if link then
            s = link.url
            s = tonumber(s, 10) or s
        end
    end

    return s
end

function Relation:make(subject, object, type)
    return Dict({
        subject = self.parse_link(subject),
        object = self.parse_link(object),
        relation = self.name,
        type = type,
    })
end

function Relation:clean(line) return line end

function Relation:parse(object, subject)
    return "", self:make(subject, object)
end

function Relation:syntax()
    local conf = M.conf.relations[self.name]
    return {[self.name .. "TaxonomySymbol"] = {string = conf.symbol, color = conf.color.syntax}}
end

--------------------------------------------------------------------------------
--                             ConnectionRelation                             --
--------------------------------------------------------------------------------
local ConnectionRelation = class(Relation)
ConnectionRelation.name = "connection"
ConnectionRelation.symbol = M.conf.relations.connection.symbol

function ConnectionRelation:clean(l) return l:removesuffix(self.symbol):strip() end
function ConnectionRelation:line_is_a(l) return l and l:match(self.symbol) and true or false end

function ConnectionRelation:parse(l, subject)
    local l, str = utils.parsekv(l, self.symbol)
    
    if str:startswith("(") then
        str = str:removeprefix("("):removesuffix(")")
    end
    
    local object, type
    if str:match(",") then
        type, object = utils.parsekv(str, ",")
    else
        object = str
    end
    
    return l, self:make(subject, object, type)
end


--------------------------------------------------------------------------------
--                          InstancesAreAlsoRelation                          --
--------------------------------------------------------------------------------
local InstancesAreAlsoRelation = class(Relation)
InstancesAreAlsoRelation.name = "instances_are_also"
InstancesAreAlsoRelation.symbol = M.conf.relations.instances_are_also.symbol

function InstancesAreAlsoRelation:parse(l, subject)
    l, object = utils.parsekv(l, self.symbol)
    object = object:removeprefix("("):removesuffix(")")
    
    return l, self:make(subject, object)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                FileRelation                                --
--                                                                            --
--------------------------------------------------------------------------------
local FileRelation = class(Relation)
FileRelation.contexts = Dict({file = true})

--------------------------------------------------------------------------------
--                               SubsetRelation                               --
--------------------------------------------------------------------------------
local SubsetRelation = class(FileRelation)
SubsetRelation.name = "subset"
SubsetRelation.symbol = M.conf.relations.subset.symbol

function SubsetRelation:line_is_a(l) return l and l:match(self.symbol) or false end

function SubsetRelation:parse(l, subject)
    local object = l:split(self.symbol, 1):mapm("strip")[2]
    return "", self:make(subject, object)
end

--------------------------------------------------------------------------------
--                              InstanceRelation                              --
--------------------------------------------------------------------------------
local InstanceRelation = class(FileRelation)
InstanceRelation.name = "instance"
InstanceRelation.symbol = M.conf.relations.instance.symbol

function InstanceRelation:clean(l) return l:removeprefix("is a:"):strip() end
function InstanceRelation:line_is_a(l) return l and l:strip():startswith("is a:") or false end

--------------------------------------------------------------------------------
--                                TagRelation                                 --
--------------------------------------------------------------------------------
local TagRelation = class(FileRelation)
TagRelation.name = "tag"
TagRelation.symbol = M.conf.relations.tag.symbol

function TagRelation:clean(l) return l:strip():removeprefix(self.symbol) end
function TagRelation:line_is_a(l) return l and l:strip():startswith(self.symbol) or false end
function TagRelation:parse(tag, subject)
    return "", self:make(subject, nil, tag)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                   Parser                                   --
--                                                                            --
--------------------------------------------------------------------------------
M.Relations = List({
    ConnectionRelation,
    SubsetRelation,
    InstancesAreAlsoRelation,
    TagRelation,
    InstanceRelation,
})

function M:get_relations(url, line, context)
    local relations = List()
    self.Relations:filter(function(Relation)
        return Relation.contexts[context]
    end):foreach(function(Relation)
        if line and #line > 0 and Relation:line_is_a(line) then
            line = Relation:clean(line)
            local relation

            line, relation = Relation:parse(line, url)
            
            if relation then
                relations:append(relation)
            end
        end
    end)
    
    return relations
end

function M:parse_taxonomy_lines(lines)
    local indent_to_parent = Dict()

    local relations = List()
    lines:foreach(function(subject)
        local indent, subject = subject:match("(%s*)(.*)")
        
        if subject:match(":") then
            subject, relation_str = utils.parsekv(subject)

            indent_to_parent[indent .. M.conf.indent_size] = subject

            relations:extend(M:get_relations(subject, relation_str, "taxonomy"))
            relations:append(SubsetRelation:make(subject, indent_to_parent[indent]))
        else
            relations:extend(M:get_relations(subject, indent_to_parent[indent], "taxonomy"))
        end
    end)
    
    return relations
end

function M:parse_file_lines(url, lines)
    local indent_to_type = Dict()
    local relations = List()
    
    lines:foreach(function(l)
        local indent, l = l:match("(%s*)(.*)")
        indent_to_type:filterk(function(_indent) return #_indent <= #indent end)

        if InstanceRelation:line_is_a(l) or TagRelation:line_is_a(l) then
            relations:extend(M:get_relations(url.id, l, "file"))
        else
            local type, object
            if l:match(":") then
                type, object = utils.parsekv(l)
                type = self.get_nested_type(type, indent, indent_to_type, not object)
            else
                type = indent_to_type[indent]
                object = l:strip()
            end

            if object and type then
                relations:append(ConnectionRelation:make(url.id, object, type))
            end
        end
    end)
    
    return relations
end

function M.get_nested_type(type, indent, indent_to_type, add)
    if indent_to_type[indent] then
        type = string.format("%s.%s", indent_to_type[indent], type)
    end

    if add then
        indent_to_type[indent .. M.conf.indent_size] = type
    end
    
    return type
end

function M:parse_file(url)
    local lines = M.get_metadata_lines(url.path)

    if #lines > 0 and lines[1]:strip() == "is a: taxonomy" then
        return self:parse_taxonomy_lines(lines:slice(2))
    else
        return self:parse_file_lines(url, lines)
    end
end

function M:record(url)
    if not url then
        return
    end

    local relations
    if M.is_taxonomy_file(url.path) then
        relations = self:parse_taxonomy_lines(url.path:readlines())
    else
        relations = self:parse_file(url)
    end

    if #DB.Relations:get() > 0 then
        DB.Relations:remove({source = url.id})
    end

    relations:foreach(function(r)
        DB.Relations:insert(r, url.id)
    end)
end

M.SubsetRelation = SubsetRelation
M.ConnectionRelation = ConnectionRelation
M.InstancesAreAlsoRelation = InstancesAreAlsoRelation
M.InstanceRelation = InstanceRelation
M.TagRelation = TagRelation
M.Relation = Relation

return M
