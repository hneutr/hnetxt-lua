local Link = require("htl.text.Link")
local MetadataParser = require("htl.metadata.Parser")

local M = {}
M.conf = Dict(Conf.Taxonomy)
M.conf.relations = Dict(M.conf.relations)
M.conf.indent_size = "  "
M.conf.to_skip = Set({"on page", "page"})

function M.is_taxonomy_file(path)
    return path:name() == tostring(Conf.paths.taxonomy_file) or path == Conf.paths.global_taxonomy_file
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

function Relation:parse(object, subject, type)
    return "", self:make(subject, object, type)
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
--------------------------------------------------------------------------------
--                           GiveInstancesRelation                            --
--------------------------------------------------------------------------------
local GiveInstancesRelation = class(Relation)
GiveInstancesRelation.name = "give_instances"
GiveInstancesRelation.symbol = M.conf.relations.give_instances.symbol

function GiveInstancesRelation:parse(l, subject)
    l, str = utils.parsekv(l, self.symbol)
    
    local type, object = utils.parsekv(str:removeprefix("("):removesuffix(")"), ",")
    
    M.conf.relations:foreach(function(key, info)
        if type == info.symbol then
            type = key
        end
    end)
    
    return l, self:make(subject, object, type)
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

--------------------------------------------------------------------------------
--                                                                            --
--                                   Parser                                   --
--                                                                            --
--------------------------------------------------------------------------------
M.Relations = List({
    ConnectionRelation,
    SubsetRelation,
    GiveInstancesRelation,
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
    local lines = MetadataParser:get_lines(url.path)

    if #lines > 0 and lines[1]:strip() == "is a: taxonomy" then
        return self:parse_taxonomy_lines(lines:slice(2))
    else
        return self:parse_file_lines(url, lines)
    end
end

function M:record(url)
    local relations
    if M.is_taxonomy_file(url.path) then
        relations = self:parse_taxonomy_lines(url.path:readlines())
    else
        relations = self:parse_file(url)
    end

    M:persist_relations(url, relations)
end

function M:persist_relations(url, relations)
    local elements = DB.Elements:get({where = {source = url.id}}):col('id')
    local old_ids = Set()
    
    if #elements > 0 then
        old_ids = Set(DB.Relations:get({
            where = {subject = elements, object = elements}
        }):col('id'))
    end

    local has_label = false
    local new_ids = Set()
    relations:filter(function(r)
        return r.relation ~= "connection" or not self.conf.to_skip:has(r.type)
    end):foreach(function(r)
        has_label = has_label or DB.Relations:is_label_relation(r)
        new_ids:add(DB.Relations:insert(r, url.id))
    end)

    if not has_label then
        DB.urls:set_label(url.id)
    end
    
    if old_ids ~= new_ids then
        local to_remove = old_ids:difference(new_ids):vals()
        
        if #to_remove > 0 then
            DB.Relations:remove({where = {id = to_remove}})
        end
        -- TODO: handle persisted taxonomy!
        -- ALSO: delete vacuous elements!
    end
end

M.SubsetRelation = SubsetRelation
M.ConnectionRelation = ConnectionRelation
M.GiveInstancesRelation = GiveInstancesRelation
M.InstanceRelation = InstanceRelation
M.TagRelation = TagRelation
M.Relation = Relation

return M
