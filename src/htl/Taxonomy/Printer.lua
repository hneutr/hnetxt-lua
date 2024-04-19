local TerminalLink = require("htl.text.TerminalLink")
local Colorize = require("htc.Colorize")

local Colors = Dict(Conf.Taxonomy.colors)

--------------------------------------------------------------------------------
--                                   Taxon                                    --
--------------------------------------------------------------------------------
local TaxonPrinter = class()
TaxonPrinter.color_key = "taxon"

function TaxonPrinter:_init(entity)
    self.entity = entity
    self.colors = Colors[self.color_key]
end

function TaxonPrinter:__tostring()
    if not self.entity.from_taxonomy and self.entity.id then
        return tostring(TerminalLink({
            label = self.entity.label,
            url = self.entity.id,
            colors = self.colors,
        }))
    else
        return Colorize(self.entity.label, self.colors.label)
    end
end

function TaxonPrinter:entity_is_a(entity) return true end

--------------------------------------------------------------------------------
--                                                                            --
--                                  Instance                                  --
--                                                                            --
--------------------------------------------------------------------------------
local InstancePrinter = class(TaxonPrinter)
InstancePrinter.color_key = "instance"

function InstancePrinter:entity_is_a(entity) return entity.type == "instance" end

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
M.conf.Printers = List({
    InstancePrinter,
    TaxonPrinter,
})

function M:_init(label_to_entity, taxonomy, instance_taxonomy)
    self.label_to_entity = label_to_entity
    self.taxonomy = taxonomy
    self.instance_taxonomy = instance_taxonomy
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
