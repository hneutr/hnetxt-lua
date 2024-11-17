local TerminalLink = require("htl.text.TerminalLink")
local Color = require("htl.Color")
local Taxonomy = require("htl.Taxonomy")

local M = class()

M.conf = Dict(Conf.Taxonomy)
M.conf.indent_size = "  "
M.conf.__all_relation_type = "__all"
M.conf.display = Dict(M.conf.display)

function M.indent(indent)
    if type(indent) == "string" then
        return indent .. M.conf.indent_size
    end

    return M.conf.indent_size:rep(indent or 0)
end

function M.get_display_parameter(parameter, t1, t2)
    local d = M.conf.display

    local keys = List({t1, t2}):notnil()
    keys:foreach(function(key)
        if d[key] == nil then
            d[key] = Dict()
        end

        if d[key][parameter] == nil then
            d[key][parameter] = d[parameter] or M.conf.display.defaults[parameter]
        end

        d = d[key]
    end)

    return d[parameter]
end

--------------------------------------------------------------------------------
--                                   Taxon                                    --
--------------------------------------------------------------------------------
local LinePrinter = class()
LinePrinter.type_sort = List({
    "subset",
    "value",
    "attribute",
    "instance",
})

function LinePrinter:_init(url, type)
    self.url = url
    self.type = type
    self.indent = ""
    self.sublines = List()
    self.id = self.url.id

    self.conf = M.conf.relations[self.type] or {color = {term = {label = 'white'}}}
    self.colors = self.conf.color.term
end

function LinePrinter:__tostring()
    return self.indent .. tostring(self:get_label()) .. self:get_suffix()
end

function LinePrinter:get_label()
    if self.url.type == "file" then
        return TerminalLink({
            label = self.url.label,
            url = self.url.id,
            colors = self.colors,
        })
    end

    return Color({self.url.label, self.colors.label})
end

function LinePrinter.__lt(a, b)
    local fns = List({
        function(e) return e.type_sort:index(e.type) or #e.type_sort + 1 end,
        function(e) return e.url.label:lower():removeprefix("the ") end,
        function(e) return e.url.id or 0 end,
        function(e) return tostring(e.url.path and e.url.path or "") end,
    })

    for fn in fns:iter() do
        local a_v = fn(a)
        local b_v = fn(b)

        if a_v < b_v then
            return true
        elseif a_v > b_v then
            return false
        end
    end

    return true
end

function LinePrinter:set_indent(indent)
    self.indent = indent and M.indent(indent) or ""
end

function LinePrinter:get_suffix()
    if #self.sublines == 0 then
        return ""
    end

    if self:can_merge() then
        local subline = self.sublines[1]
        self.merge_count = subline.merge_count + 1
        return self:get_merge_str(subline)
    else
        self.sublines:foreachm("set_indent", self.indent)
        return M.get_display_parameter("suffix", self.type) .. "\n" .. self.sublines:map(tostring):join("\n")
    end
end

function LinePrinter:get_merge_count()
    if self.merge_count == nil then
        self.merge_count = 1

        if self:can_merge() then
            self.merge_count = self.sublines[1]:get_merge_count() + 1
        end
    end

    return self.merge_count
end

function LinePrinter:can_merge()
    local can_merge = true

    if #self.sublines == 0 then
        return false
    end

    can_merge = can_merge and #self.sublines == 1

    local subline = self.sublines[1]
    local t1 = self.type
    local t2 = subline.type

    can_merge = can_merge and M.get_display_parameter("can_merge", t1, t2)
    can_merge = can_merge and subline:get_merge_count() < M.get_display_parameter("merge_max", t1, t2)

    return can_merge
end

function LinePrinter:get_merge_str(subline)
    return M.get_display_parameter("suffix", self.type, subline.type) .. tostring(subline)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Printer                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:_init(args)
    args = args or {}

    self.include_instances = args.include_instances
    self.by_attribute = args.by_attribute
    self.include_attribute_values = args.include_attribute_values
    self.instances_only = args.instances_only
    self.included_types = self:get_included_types()

    self.T = Taxonomy(args)
end

function M:get_included_types()
    if self.instances_only then
        return Set({"instance"})
    end

    local types = Set({"subset", "attribute"})

    if self.include_instances then
        types:add("instance")
    end

    if self.include_attribute_values then
        types:add("value")
    end

    return types
end

function M:__tostring()
    local lines

    if self.instances_only then
        lines = self:get_instance_lines(self.T.taxon_instances:values())
    elseif self.by_attribute then
        lines = self:get_attribute_lines()
    else
        lines = self:get_lines()
    end

    return lines:transform(tostring):join("\n")
end

function M:get_attribute_relations_by_key()
    -- TODO fix this
    local seeds = Set(self.T.seeds)

    local conditions = self.T.conditions:filter(function(c)
        return c.predicate and not DB.Metadata.conf.taxonomy_predicates:contains(c.predicate)
    end)

    local rows = List()
    if #conditions == 0 then
        conditions:append({predicate = "???????????????"})
    end

    local key_to_relations = Dict():set_default(function() return Dict():set_default(Set) end)

    conditions:map(self.T.get_condition_rows):foreach(function(rows)
        rows:foreach(function(r)
            local thing

            if r.val then
                thing = r.val
                if not self.T.urls_by_id[thing] then
                    self.T.urls_by_id[thing] = Dict({label = thing, id = thing})
                end
            elseif r.object then
                thing = r.object
            end

            if thing and seeds:has(r.subject) then
                key_to_relations[r.key or M.conf.__all_relation_type][thing]:add(r.subject)
            end
        end)
    end)

    return key_to_relations
end

function M:get_attribute_lines()
    local key_to_relations = self:get_attribute_relations_by_key()

    local lines = List()
    local key_to_line = Dict()

    key_to_relations:keys():sorted():foreach(function(attribute_key)
        local parent_key
        attribute_key:split("."):foreach(function(key_part)
            local key = key_part
            if parent_key then
                key = string.format("%s.%s", parent_key, key)
            end

            if not key_to_line[key] then
                local line = LinePrinter({label = key_part}, "attribute")
                key_to_line[key] = line

                if parent_key then
                    key_to_line[parent_key].sublines:append(line)
                else
                    lines:append(line)
                end
            end

            parent_key = key
        end)

        local attribute_line = key_to_line[attribute_key]
        local vals_by_object = key_to_relations[attribute_key]

        if self.included_types:has("value") then
            self:get_urls(vals_by_object, "value"):foreach(function(object)
                attribute_line.sublines:append(object)
                object.sublines:extend(self:get_urls(vals_by_object[object.url.id], "instance"))
            end)
        else
            attribute_line.sublines:extend(self:get_instance_lines(vals_by_object:values()))
        end
    end)

    return lines
end

function M:get_urls(ids, type)
    if self.included_types:has(type) then
        if ids:is_a(Set) then
            ids = ids:vals()
        elseif ids:is_a(Dict) then
            ids = ids:keys()
        end

        if ids then
            return ids:map(function(id) return LinePrinter(self.T.urls_by_id[id], type) end):sorted()
        end
    end

    return List()
end

function M:get_instance_lines(d)
    local instances = Set()
    d:foreach(function(_instances) instances:add(_instances) end)
    return self:get_urls(instances, "instance")
end

function M:get_lines()
    local taxonomy = self.T.taxonomy
    local taxa = self:get_urls(taxonomy, "subset")

    local lines = List(taxa)
    while #taxa > 0 do
        local taxon = taxa:pop()
        taxon.sublines:extend(self:get_urls(taxonomy:get(taxon.id), "subset"))
        taxa:extend(taxon.sublines)
        taxon.sublines:extend(self:get_urls(self.T.taxon_instances[taxon.id], "instance"))
    end

    return lines
end

return M
