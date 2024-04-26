local TerminalLink = require("htl.text.TerminalLink")
local Colorize = require("htc.Colorize")

local M = class()

M.conf = Dict(Conf.Taxonomy)
M.conf.indent_size = "  "

--------------------------------------------------------------------------------
--                                   Taxon                                    --
--------------------------------------------------------------------------------
local SubsetPrinter = class()
SubsetPrinter.key = "subset"

function SubsetPrinter:_init(entity)
    self.entity = entity
    self.colors = M.conf.relations[self.key].color.term
end

function SubsetPrinter:__tostring()
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

function SubsetPrinter:entity_is_a(entity) return entity.type == self.key end

--------------------------------------------------------------------------------
--                                                                            --
--                                  Instance                                  --
--                                                                            --
--------------------------------------------------------------------------------
local InstancePrinter = class(SubsetPrinter)
InstancePrinter.key = "instance"

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Printer                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.relation_to_printer = Dict({
    subset = SubsetPrinter,
    instance = InstancePrinter,
})

function M:_init(label_to_entity, taxonomy, taxon_to_instances)
    self.label_to_entity = label_to_entity
    self.taxonomy = taxonomy
    self.taxon_to_instances = taxon_to_instances
end

function M:get_string(args)
    args = Dict(args or {}, {include_instances = false})

    self.include_instances = args.include_instances
    
    return self:print_tree(self.taxonomy):join("\n")
end

function M:print_tree(tree, instances, indent)
    indent = indent or ""
    local lines = List()
    
    if instances and self.include_instances then
        instances:keys():sorted():foreach(function(instance)
            local entity = self.label_to_entity[instance]
            local entity_printer = self.relation_to_printer[entity.type](entity)
            lines:append(indent .. tostring(entity_printer))
        end)
    end
    
    Tree(tree):keys():sorted():foreach(function(label)
        local entity = self.label_to_entity[label]
        local entity_printer = self.relation_to_printer[entity.type](entity)
        
        local sublines = self:print_tree(tree[label], self.taxon_to_instances[label], indent .. self.conf.indent_size)
        
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
