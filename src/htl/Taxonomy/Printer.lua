local Colorize = require("htc.Colorize")

local Colors = Dict(Conf.Taxonomy.colors)

local TaxonPrinter = class()
TaxonPrinter.color_key = "taxon"

function TaxonPrinter:_init(entity)
    self.entity = entity
    self.colors = Colors[self.color_key]
end

function TaxonPrinter:entity_is_a(entity) return entity.from_taxonomy or not entity.id end

function TaxonPrinter:__tostring()
    return Colorize(self.entity.label, self.colors)
end

--------------------------------------------------------------------------------
--                              TaxonLinkPrinter                              --
--------------------------------------------------------------------------------
local TaxonLinkPrinter = class(TaxonPrinter)
TaxonLinkPrinter.color_key = "link"

function TaxonLinkPrinter:entity_is_a(entity) return not entity.from_taxonomy and entity.id end
function TaxonLinkPrinter:__tostring()
    return DB.urls:get_reference(self.entity):terminal_string(self.colors)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Printer                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local M = class()

M.conf = Dict(Conf.Taxonomy)
M.conf.indent_size = "  "
M.conf.Printers = List({TaxonPrinter, TaxonLinkPrinter})

function M:_init(label_to_entity, taxonomy, instance_taxonomy, instances)
    self.label_to_entity = label_to_entity
    self.taxonomy = taxonomy
    self.instance_taxonomy = instance_taxonomy
    self.instances = instances
end

function M:get_entity_printer(entity)
    for Printer in M.conf.Printers:iter() do
        if Printer:entity_is_a(entity) then
            return Printer(entity)
        end
    end
end

function M:print_tree(tree, indent)
    indent = indent or ""
    local lines = List()
    Tree(tree):keys():sorted():foreach(function(label)
        local entity_printer = self:get_entity_printer(self.label_to_entity[label])
        
        local sublines = self:print_tree(tree[label], indent .. self.conf.indent_size)
        
        local line = indent .. tostring(entity_printer)
        
        if #sublines > 0 then
            line = line .. ":"
        end
        
        lines:append(line)
        lines:extend(sublines)
    end)
    
    return lines
end

return M
