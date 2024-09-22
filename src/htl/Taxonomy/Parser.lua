local Divider = require("htl.text.divider")
local Mirrors = require("htl.Mirrors")
local Link = require("htl.text.Link")

local M = {}
M.conf = Dict(Conf.Taxonomy)
M.conf.relations = Dict(M.conf.relations)
M.conf.indent_size = "  "
M.conf.to_skip = Set({"on page", "page"})
M.conf.metadata = Dict(M.conf.metadata)
M.conf.metadata.divider = tostring(Divider("large", "metadata"))
M.conf.grammar.comment_pattern = string.format("%s.*", M.conf.grammar.comment_prefix)

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
    local lines = M.separate_metadata(M.read_metadata_lines(path))
    lines:extend(M.read_metadata_lines(Mirrors:get_path(path, "metadata")))
    
    return lines
end

function M.read_metadata_lines(path)
    local lines = List()
    if path and path:exists() then
        path:readlines():foreach(function(l)
            if l:match(M.conf.grammar.comment_prefix) then
                l = l:gsub(M.conf.grammar.comment_pattern, "")
                l = l:rstrip()
                if #l:strip() > 0 then
                    lines:append(l)
                end
            else
                lines:append(l)
            end
        end)
    end
    
    return lines
end

function M.separate_metadata(lines)
    if #lines > 0 then
        local l1 = lines[1]
        if not l1:match(":") and not M.TagRelation:line_is_a(l1) then
            return List()
        end
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
    result = result and l ~= M.conf.metadata.divider

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
    
    if conf then
        return {[self.name .. "TaxonomySymbol"] = {string = conf.symbol, color = conf.color.syntax}}
    end
end

function Relation:condition_is_a(l) return self:line_is_a(l) end
function Relation:from_commandline(str)
    local condition = Dict({relation = self.name})
    str, condition.is_exclusion = str:removesuffix(M.conf.grammar.exclusion_suffix)
    
    str, condition.is_recursive = str:gsub(M.conf.grammar.recursive, ":")

    condition.is_recursive = condition.is_recursive > 0

    return self:annotate_condition(condition, str)
end

function Relation:annotate_condition(condition, str)
    return condition
end

function Relation.val_to_url_id(val)
    local path = Path.from_commandline(val)

    if path:exists() then
        local url = DB.urls:get_file(path)
        val = url and url.id or val
    end
    
    return val
end

--------------------------------------------------------------------------------
--                             ConnectionRelation                             --
--------------------------------------------------------------------------------
local ConnectionRelation = class(Relation)
ConnectionRelation.name = "connection"
ConnectionRelation.symbol = M.conf.relations.connection.symbol

function ConnectionRelation:clean(l) return l:removesuffix(self.symbol):strip() end
function ConnectionRelation:line_is_a(l) return l and l:match(self.symbol) and true or false end

function ConnectionRelation:parse(l)
    local str
    l, str = utils.parsekv(l, self.symbol)

    if str:startswith("(") then
        str = str:removeprefix("("):removesuffix(")")
    end

    local key, val
    if str:match(",") then
        key, val = utils.parsekv(str, ",")
    else
        val = str
    end

    return l, self:make(key, val)
end

function ConnectionRelation:make(key, val)
    local r = Dict({
        relation = self.name,
        key = key,
    })

    val = self.parse_link(val)
    
    if type(val) == "string" then
        r.val = val
    else
        r.object = val
    end
    
    return r
end

function ConnectionRelation:condition_is_a(l) return true end
function ConnectionRelation:annotate_condition(condition, str)
    if str:match(":") then
        local raw_vals
        condition.key, raw_vals = utils.parsekv(str, ":")

        local objects = List()
        local vals = List()
        raw_vals:split(M.conf.grammar.or_delimiter):transform(self.val_to_url_id):foreach(function(v)
            if type(v) == "number" then
                objects:append(v)
            else
                vals:append(v)
            end
        end)
        
        if #objects > 0 then
            condition.object = objects
        end
        
        if #vals > 0 then
            condition.val = vals
        end
    else
        condition.key = str
    end

    return condition
end


--------------------------------------------------------------------------------
--                          InstancesAreAlsoRelation                          --
--------------------------------------------------------------------------------
local InstancesAreAlsoRelation = class(Relation)
InstancesAreAlsoRelation.name = "instances_are_also"
InstancesAreAlsoRelation.symbol = M.conf.relations.instances_are_also.symbol

function InstancesAreAlsoRelation:parse(l, subject)
    local object
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

function SubsetRelation:condition_is_a(l) return l:strip():startswith(M.conf.grammar.taxon_prefix) end

function SubsetRelation:annotate_condition(condition, str)
    condition.object = str:gsub(M.conf.grammar.taxon_prefix, ""):split(
        M.conf.grammar.or_delimiter
    ):transform(self.val_to_url_id)

    return condition
end

--------------------------------------------------------------------------------
--                              InstanceRelation                              --
--------------------------------------------------------------------------------
local InstanceRelation = class(FileRelation)
InstanceRelation.name = "instance"
InstanceRelation.symbol = M.conf.relations.instance.symbol

function InstanceRelation:clean(l) return l:removeprefix("is a:"):strip() end
function InstanceRelation:line_is_a(l) return l and l:strip():startswith("is a:") or false end

function InstanceRelation:parse(object, subject)
    local l = ""
    
    if object:match(",") then
        l, object = unpack(object:rsplit(',', 1):mapm("strip"))
        l = string.format("is a: %s", l)
    end
    
    return l, self:make(subject, object)
end


--------------------------------------------------------------------------------
--                                TagRelation                                 --
--------------------------------------------------------------------------------
local TagRelation = class(FileRelation)
TagRelation.name = "tag"
TagRelation.symbol = M.conf.relations.tag.symbol

function TagRelation:clean(l) return l:strip():removeprefix(self.symbol) end
function TagRelation:line_is_a(l) return l and l:match(self.symbol) and true or false end
function TagRelation:parse(tag)
    local l = ""
    
    tag = tag:strip()
    if not tag:startswith(self.symbol) then
        local split = tag:rsplit(self.symbol, 1)
        
        if #split == 1 then
            tag = split[1]
        else
            l, tag = unpack(split)
        end
    end

    return l, self:make(tag)
end

function TagRelation:make(tag)
    local r = Dict({relation = self.name})

    tag = self:clean(tag)
    tag = self.parse_link(tag)
    
    if type(tag) == "number" then
        r.object = tag
    else
        r.key = tag
    end

    return r
end

function TagRelation:annotate_condition(condition, str)
    local raw_keys = str:gsub(self.symbol, ""):split(M.conf.grammar.or_delimiter)

    condition.object = List()
    condition.key = List()
    raw_keys:foreach(function(key)
        local key = self.val_to_url_id(key)

        if type(key) == "number" then
            condition.object:append(key)
        else
            condition.key:append(key)
        end
    end)
    
    List({"object", "key"}):foreach(function(k)
        if #condition[k] == 0 then
            condition[k] = nil
        end
    end)
    
    return condition
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

function M.parse_condition(str)
    local Relations = List({
        TagRelation,
        SubsetRelation,
        ConnectionRelation,
    })
    
    for _Relation in Relations:iter() do
        if _Relation:condition_is_a(str) then
            return _Relation:from_commandline(str)
        end
    end
end

function M:get_relations(url, line, context)
    local relations = List()
    
    self.Relations:filter(function(_Relation)
        return _Relation.contexts[context]
    end):foreach(function(_Relation)
        while line and #line > 0 and _Relation:line_is_a(line) do
            line = _Relation:clean(line)
            local relation

            line, relation = _Relation:parse(line, url)

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
        local indent
        indent, subject = subject:match("(%s*)(.*)")

        if subject:match(":") then
            local relation_str
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
    local indent_to_key = Dict()
    local relations = List()

    lines:foreach(function(l)
        local indent
        indent, l = l:match("(%s*)(.*)")
        indent_to_key:filterk(function(_indent) return #_indent <= #indent end)

        if InstanceRelation:line_is_a(l) or TagRelation:line_is_a(l) then
            relations:extend(M:get_relations(url.id, l, "file"))
        else
            local key, val
            if l:match(":") then
                key, val = utils.parsekv(l)
                key = self.get_nested_key(key, indent, indent_to_key, not val)
            else
                key = indent_to_key[indent]
                val = l:strip()
            end

            if key and val then
                relations:append(ConnectionRelation:make(key, val))
            end
        end
    end)

    return relations
end

function M.get_nested_key(key, indent, indent_to_key, add)
    if indent_to_key[indent] then
        key = string.format("%s.%s", indent_to_key[indent], key)
    end

    if add then
        indent_to_key[indent .. M.conf.indent_size] = key
    end

    return key
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

function M:persist()
    DB.Relations:drop()

    DB.urls:get({where = {type = "file"}}):sorted(function(a, b)
        return tostring(a.path) < tostring(b.path)
    end):foreach(function(u)
        if not pcall(function() M:record(u) end) then
            print(u.path)
            os.exit()
        else
            print(u.path)
        end
    end)
end

M.SubsetRelation = SubsetRelation
M.ConnectionRelation = ConnectionRelation
M.InstancesAreAlsoRelation = InstancesAreAlsoRelation
M.InstanceRelation = InstanceRelation
M.TagRelation = TagRelation
M.Relation = Relation

return M
