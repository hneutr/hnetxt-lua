local Colorize = require("htc.Colorize")

local class = require("pl.class")

local colors = Dict(Conf.metadata.colors)

local KeyPrinter = class()
KeyPrinter.color_key = "key"

function KeyPrinter:colors() return colors[self.color_key] end
function KeyPrinter:is_a(entity) return entity.from_taxonomy or not entity.id end
function KeyPrinter:for_terminal(entity)
    return Colorize(entity.label, self:colors())
end


local LinkPrinter = class(KeyPrinter)
LinkPrinter.color_key = "link"

function LinkPrinter:is_a(entity) return not entity.from_taxonomy and entity.id end
function LinkPrinter:for_terminal(entity)
    return DB.urls:get_reference(entity):terminal_string(self:colors())
end

local M = class()

M.conf = Dict(Conf.metadata)
M.conf.indent_size = "  "
M.conf.Printers = List({KeyPrinter, LinkPrinter})

function M:_init(label_to_entity, taxonomy, taxon_to_instance_taxon, instances)
    self.label_to_entity = label_to_entity
    self.taxonomy = taxonomy
    self.taxon_to_instance_taxon = taxon_to_instance_taxon
    self.instances = instances
end

function M:get_entity_printer(entity)
    for Printer in M.conf.Printers:iter() do
        if Printer:is_a(entity) then
            return Printer
        end
    end
end

function M:print_tree(tree, indent)
    indent = indent or ""
    Tree(tree):keys():sorted():foreach(function(label)
        local entity = self.label_to_entity[label]
        local Printer = self:get_entity_printer(entity)
        print(indent .. Printer:for_terminal(entity) .. ":")
        
        self:print_tree(tree[label], indent .. self.conf.indent_size)
    end)
end

return M
