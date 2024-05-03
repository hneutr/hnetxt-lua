local TerminalLink = require("htl.text.TerminalLink")
local Colorize = require("htc.Colorize")
local Taxonomy = require("htl.Taxonomy")

local M = class()

M.conf = Dict(Conf.Taxonomy)
M.conf.indent_size = "  "
M.conf.__all_relation_type = "__all"

function M.indent(i)
    return M.conf.indent_size:rep(i or 0)
end

--------------------------------------------------------------------------------
--                                   Taxon                                    --
--------------------------------------------------------------------------------
local LinePrinter = class()

function LinePrinter:_init(element, type, indent, suffix)
    self.element = element
    self.type = type
    self.indent = indent or ""
    self.suffix = suffix or ""
    self.sublines = List()
    
    self.conf = M.conf.relations[self.type] or {color = {term = 'white'}}
    self.colors = self.conf.color.term
end

function LinePrinter:__tostring()
    local s
    if self.element.url then
        s = TerminalLink({
            label = self.element.label,
            url = self.element.url.id,
            colors = self.colors,
        })
    else
        s = Colorize(self.element.label, self.colors.label)
    end
    
    local sublines_s = self.sublines:map(tostring):mapm("lstrip"):join(" ")
    
    if #sublines_s > 0 then
        sublines_s = " " .. sublines_s
    end

    return self.indent .. tostring(s) .. self.suffix .. sublines_s
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
    self.instances_only = args.instances_only

    self.T = Taxonomy(args)
end

function M:__tostring()
    local lines = List()
    if self.instances_only then
        lines = self:get_instance_lines()
    elseif self.by_attribute then
        lines = self:get_attribute_lines()
    else
        lines = self:get_lines()
    end

    return lines:transform(tostring):join("\n")
end

function M:get_attribute_lines()
    local seeds = Set(self.T.seeds)
    local relations_by_attribute = DefaultDict(function() return DefaultDict(Set) end)
    self.T.conditions:filter(function(c)
        return c.relation and c.relation == "connection"
    end):foreach(function(c)
        self.T.get_condition_rows(c):foreach(function(r)
            if r.object and seeds:has(r.subject) then
                relations_by_attribute[r.type or M.conf.__all_relation_type][r.object]:add(r.subject)
            end
        end)
    end)

    local lines = List()
    local printed_keys = Set()
    relations_by_attribute:keys():sorted():foreach(function(attribute_line)
        local parts = List()
        attribute_line:split("."):foreach(function(part)
            parts:append(part)
            
            local _key = parts:join(".")
            if not printed_keys:has(_key) then
                printed_keys:add(_key)
                lines:append(LinePrinter(
                    {label = part},
                    "attribute",
                    M.indent(#parts - 1),
                    ":"
                ))
            end
        end)

        local vals_by_object = relations_by_attribute[attribute_line]
        self:get_elements(
            vals_by_object:keys(),
            "value",
            M.indent(#parts),
            ":"
        ):foreach(function(object)
            lines:append(object)

            local val_lines = self:get_elements(
                vals_by_object[object.element.id]:vals(),
                "instance",
                M.indent(#parts + 1)
            )
            
            if #val_lines == 1 then
                object.sublines = val_lines
            else
                lines:extend(val_lines)
            end
        end)
    end)
    
    return lines
end

function M:get_element(id) return self.T.elements_by_id[id] end

function M.element_sort(a, b)
    return M.sort_label(a) < M.sort_label(b)
end

function M.sort_label(e)
    return e.label:lower():removeprefix("the ")
end

function M:get_elements(ids, type, indent, suffix)
    local elements = List()
    if ids then
        ids:transform(function(id)
            return self:get_element(id)
        end):sorted(self.element_sort):foreach(function(element)
            elements:append(LinePrinter(element, type, indent or "", suffix or ""))
        end)
    end
    
    return elements
end

function M:add_taxa(dict, taxa, indent)
    taxa:extend(self:get_elements(dict and dict:keys(), "subset", indent):reverse())
end

function M:add_instances(set, lines, indent)
    if self.include_instances and set then
        lines:extend(self:get_elements(set:vals(), "instance", indent))
    end
    
    return lines
end

function M:get_instance_lines()
    local instances = Set()
    self.T.taxon_instances:values():foreach(function(_instances) instances:add(_instances) end)
    return self:add_instances(instances, List())
end

function M:get_lines()
    local taxa = List()
    self:add_taxa(self.T.taxonomy, taxa)
    
    local lines = List()
    while #taxa > 0 do
        local taxon = taxa:pop()
        -- local taxon, type, indent = unpack()
        local i = #lines + 1
        local pre_count = #taxa + #lines
        local _indent = taxon.indent .. "  "
        
        self:add_taxa(self.T.taxonomy:get(taxon.element.id), taxa, _indent)
        self:add_instances(self.T.taxon_instances[taxon.element.id], lines, _indent)

        taxon.suffix = (#taxa + #lines) > pre_count and ":" or ""
        lines:insert(i, taxon)
    end
    
    return lines
end

return M
