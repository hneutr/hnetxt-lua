local Link = require("htl.text.Link")

local M = {}
M.conf = Dict(Conf.Taxonomy)
M.conf.relations = Dict(M.conf.relations)
M.conf.indent_size = "  "

function M:parse_taxonomy_lines(lines)
    local indent_to_parent = Dict()

    local relations = List()
    lines:foreach(function(l)
        local indent, l = l:match("(%s*)(.*)")
        local parse = M:parse_line(l)
        indent_to_parent[indent .. M.conf.indent_size] = parse.subject_label
        
        relations:append({
            subject_label = parse.subject_label,
            object = indent_to_parent[indent],
            relation = "subset",
        })
        
        if parse.object and #parse.object > 0 and parse.relation then
            relations:append(parse)
        end
    end)
    
    return relations
end

function M:parse_line(s, subject)
    if not subject then
        subject, s = M:parse_subject(s)
    end

    local object, relation = M:parse_predicate(s)

    return Dict({
        subject_label = subject,
        object = object,
        relation = relation,
    })
end

function M:parse_subject(s)
    s = s or ""
    local subject, s = unpack(s:split(":", 1):mapm("strip"))
    return subject, s
end

function M.parse_link(s)
    if type(s) == "string" then
        s = s:strip()

        local link = Link:from_str(s)

        if link then
            s = tonumber(link.url)
        end
    end

    return s
end

function M:parse_predicate(s)
    s = s or ""
    s = s:strip()
    for relation, symbol in pairs(self.conf.relations) do
        local prefix = string.format("%s(", symbol)
        local suffix = ")"
        if s:startswith(prefix) and s:endswith(suffix) then
            s = s:removeprefix(prefix):removesuffix(suffix)

            return M.parse_link(s), relation
        end
    end

    return M.parse_link(s)
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
            s = tonumber(link.url)
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

function Relation:read(line, subject)
    line = self:clean(line)

    local relations = List()

    if self:line_is_a(line) then
        line, relations = self:parse(line, subject)
    end
    
    return line, relations
end

function Relation:clean(line) return line end

local SubsetRelation = class(Relation)
SubsetRelation.name = "subset"
SubsetRelation.symbol = M.conf.relations.subset

function SubsetRelation:parse(l, subject)
    local relations = l:split(self.symbol):slice(2):transform(function(object)
        local relation = self:make(subject, object)
        subject = object
        return relation
    end)
    
    return "", relations
end


--------------------------------------------------------------------------------
--                             ConnectionRelation                             --
--------------------------------------------------------------------------------
local ConnectionRelation = class(Relation)
ConnectionRelation.name = "connection"
ConnectionRelation.symbol = M.conf.relations.connection

function ConnectionRelation:clean(l) return l:removesuffix(self.symbol):strip() end
function ConnectionRelation:line_is_a(l) return l and l:match(self.symbol) and true or false end

function ConnectionRelation:parse(l, subject)
    local relations = l:split(self.symbol):mapm("strip")
    l = relations:pop(1)
    
    return l, relations:transform(function(part)
        local object, type = self:parse_one(part)
        return self:make(subject, object, type)
    end)
end

function ConnectionRelation:parse_one(l)
    l = l:removeprefix("("):removesuffix(")"):strip()
    
    local object, relation
    if l:match(",") then
        relation, object = unpack(l:split(","):mapm("strip"))
    end
    
    return object or l, relation
end

--------------------------------------------------------------------------------
--                           GiveInstancesRelation                            --
--------------------------------------------------------------------------------
local GiveInstancesRelation = class(Relation)
GiveInstancesRelation.name = "give_instances"
GiveInstancesRelation.symbol = M.conf.relations.give_instances

function GiveInstancesRelation:parse(l, subject)
    local relation
    l, str = unpack(l:split(self.symbol, 1):mapm("strip"))
    
    local type, object = unpack(str:removeprefix("("):removesuffix(")"):split(","):mapm("strip"))
    
    M.conf.relations:foreach(function(key, symbol)
        if type == symbol then
            type = key
        end
    end)
    
    return l, List({self:make(subject, object, type)})
end

--------------------------------------------------------------------------------
--                              InstanceRelation                              --
--------------------------------------------------------------------------------
local InstanceRelation = class(Relation)
InstanceRelation.name = "instance"
InstanceRelation.symbol = M.conf.relations.instance

function InstanceRelation:line_is_a(l) return l and true end

function InstanceRelation:parse(object, subject)
    return "", List({self:make(subject, object)})
end

--------------------------------------------------------------------------------
--                                                                            --
--                                 LineParser                                 --
--                                                                            --
--------------------------------------------------------------------------------
local LineParser = {}
LineParser.Relations = List({
    ConnectionRelation,
    SubsetRelation,
    GiveInstancesRelation,
    InstanceRelation,
})

function LineParser:get_relations(url, line)
    local relations = List()
    self.Relations:foreach(function(Relation)
        local subrelations
        
        if line and #line > 0 then
            line, subrelations = Relation:read(line, url)
            
            if subrelations then
                relations:extend(subrelations)
            end
        end
    end)
    
    return relations
end

function LineParser:record_is_a(url, line)
    if DB.Relations:where({subject_url = url}) then
        DB.Relations:remove({subject_url = url})
    end

    local object
    self:get_relations(url, line):foreach(function(relation)
        object = relation.object
        relation.subject_url = relation:pop('subject')
        DB.Relations:insert(relation)
    end)
    
    return object and tostring(object)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                 FileParser                                 --
--                                                                            --
--------------------------------------------------------------------------------
local FileParser = {}

function FileParser:parse_taxonomy_lines(lines)
    local indent_to_parent = Dict()

    local relations = List()
    lines:foreach(function(subject)
        local indent, subject = subject:match("(%s*)(.*)")
        
        if subject:match(":") then
            subject, relation_str = unpack(subject:split(":", 1):mapm("strip"))

            indent_to_parent[indent .. M.conf.indent_size] = subject

            relations:extend(LineParser:get_relations(subject, relation_str))
            relations:append(SubsetRelation:make(subject, indent_to_parent[indent]))
        else
            relations:extend(LineParser:get_relations(subject, indent_to_parent[indent]))
        end
    end)
    
    return relations
end

function FileParser:parse_taxonomy_file(path)
    local url = DB.urls:get_file(path)
    
    DB.Relations:remove({subject_url = url.id})

    self:parse_taxonomy_lines(path:readlines()):foreach(function(r)
        r.subject_label = r:pop('subject')
        r.subject_url = url.id
        DB.Relations:insert(r)
    end)
end

M.SubsetRelation = SubsetRelation
M.ConnectionRelation = ConnectionRelation
M.GiveInstancesRelation = GiveInstancesRelation
M.InstanceRelation = InstanceRelation

M.LineParser = LineParser
M.FileParser = FileParser

function M:record_is_a(url, line)
    return M.LineParser:record_is_a(url, line)
end

function M:parse_taxonomy_file(path)
    return M.FileParser:parse_taxonomy_file(path)
end

return M
