local TerminalLink = require("htl.text.TerminalLink")
local Colorize = require("htc.Colorize")
local PTaxonomy = require("htl.Taxonomy.Persistent")

local M = class()

M.conf = Dict(Conf.Taxonomy)
M.conf.indent_size = "  "

--------------------------------------------------------------------------------
--                                   Taxon                                    --
--------------------------------------------------------------------------------
local LinePrinter = class()

function LinePrinter:_init(element, type, indent, suffix)
    self.element = element
    self.type = type
    self.indent = indent or ""
    self.suffix = suffix or ""
    
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
    
    return self.indent .. tostring(s) .. self.suffix
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
    self.include_attributes = args.include_attributes
    self.instances_only = args.instances_only

    self.T = PTaxonomy(args)
    -- print(self.T:get_printable_taxon_instances())
end

function M:__tostring()
    local lines = List()
    if self.instances_only then
        lines = self:get_instance_lines()
    else
        lines = self:get_lines()
    end

    return lines:transform(function(l)
        return tostring(LinePrinter(unpack(l)))
    end):join("\n")
end

function M:get_element(id) return self.T.elements_by_id[id] end

function M.element_sort(a, b)
    return M.sort_label(a) < M.sort_label(b)
end

function M.sort_label(e)
    return e.label:lower():removeprefix("the ")
end

function M:get_elements(ids, type, indent)
    local elements = List()
    if ids then
        ids:transform(function(id)
            return self:get_element(id)
        end):sorted(self.element_sort):foreach(function(element)
            elements:append({element, type, indent or ""})
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
        local taxon, type, indent = unpack(taxa:pop())
        local i = #lines + 1
        local pre_count = #taxa + #lines
        local _indent = indent .. "  "
        
        self:add_taxa(self.T.taxonomy:get(taxon.id), taxa, _indent)
        self:add_instances(self.T.taxon_instances[taxon.id], lines, _indent)

        local suffix = (#taxa + #lines) > pre_count and ":"
        lines:insert(i, {taxon, "subset", indent, suffix})
    end
    
    return lines
end

return M
