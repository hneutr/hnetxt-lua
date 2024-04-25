local Link = require("htl.text.Link")
local MetadataParser = require("htl.metadata.Parser")

local M = {}
M.conf = Dict(Conf.Taxonomy)
M.conf.relations = Dict(M.conf.relations)
M.conf.indent_size = "  "

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

function Relation:line_is_a(l) return l and l:startswith(self.symbol) or false end

function Relation.parse_link(s)
    if type(s) == "string" then
        s = s:strip()

        local link = Link:from_str(s)

        if link then
            s = link.url
        end
    end

    return tonumber(s, 10) or s
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
--                               SubsetRelation                               --
--------------------------------------------------------------------------------
local SubsetRelation = class(Relation)
SubsetRelation.name = "subset"
SubsetRelation.symbol = M.conf.relations.subset.symbol

function SubsetRelation:parse(l, subject)
    local object = l:split(self.symbol, 1):mapm("strip")[2]
    return "", self:make(subject, object)
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
--                              InstanceRelation                              --
--------------------------------------------------------------------------------
local InstanceRelation = class(Relation)
InstanceRelation.name = "instance"
InstanceRelation.symbol = M.conf.relations.instance.symbol

function InstanceRelation:clean(l) return l:removeprefix("is a:"):strip() end
function InstanceRelation:line_is_a(l) return l and l:strip():startswith("is a:") or false end

--------------------------------------------------------------------------------
--                                TagRelation                                 --
--------------------------------------------------------------------------------
local TagRelation = class(Relation)
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

function M:get_relations(url, line)
    local relations = List()
    self.Relations:foreach(function(Relation)
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

            relations:extend(M:get_relations(subject, relation_str))
            relations:append(SubsetRelation:make(subject, indent_to_parent[indent]))
        else
            relations:extend(M:get_relations(subject, indent_to_parent[indent]))
        end
    end)
    
    return relations
end

function M:record_taxonomy(url, lines)
    lines = lines or url.path:readlines()

    self:parse_taxonomy_lines(lines):foreach(function(r)
        r.subject_label = r:pop('subject')
        r.subject_url = url.id
        DB.Relations:insert(r)
    end)
end

function M:parse_file_lines(lines, url)
    local last_type
    local relations = List()
    
    lines:foreach(function(l)
        l = l:strip()
        if InstanceRelation:line_is_a(l) or TagRelation:line_is_a(l) then
            relations:extend(M:get_relations(url.id, l))
            last_type = nil
        else
            if l:match(":") then
                if l:endswith(":") then
                    last_type = l:removesuffix(":")
                else
                    local type, object = utils.parsekv(l)
                    relations:append(ConnectionRelation:make(url.id, object, type))
                    last_type = nil
                end
            elseif last_type then
                relations:append(ConnectionRelation:make(url.id, l:strip(), last_type))
            end
        end
    end)
    
    return relations
end

function M:record_file(url)
    local lines = MetadataParser:get_lines(url.path)

    if #lines > 0 and lines[1]:strip() == "is a: taxonomy" then
        self:record_taxonomy(urls, lines:slice(2))
    else
        self:parse_file_lines(lines, url):foreach(function(r)
            r.subject_url = r:pop('subject')
            DB.Relations:insert(r)
        end)
    end
end

function M:record(url)
    DB.Relations:remove({subject_url = url.id})
    
    if M.is_taxonomy_file(url.path) then
        self:record_taxonomy(url)
    else
        self:record_file(url)
    end
end

M.SubsetRelation = SubsetRelation
M.ConnectionRelation = ConnectionRelation
M.GiveInstancesRelation = GiveInstancesRelation
M.InstanceRelation = InstanceRelation
M.TagRelation = TagRelation
M.Relation = Relation

return M
