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

function SubsetPrinter:_init(entity, indent)
    self.entity = entity
    self.colors = M.conf.relations[self.key].color.term
    self.indent = indent or ""
    self.suffix = ""
end

function SubsetPrinter:__tostring()
    local s
    if not self.entity.from_taxonomy and self.entity.id then
        s = tostring(TerminalLink({
            label = self.entity.label,
            url = self.entity.id,
            colors = self.colors,
        }))
    else
        s = Colorize(self.entity.label, self.colors.label)
    end
    
    return self.indent .. s .. self.suffix
end

function SubsetPrinter:entity_is_a(entity) return entity.type == self.key end

--------------------------------------------------------------------------------
--                                                                            --
--                                  Instance                                  --
--                                                                            --
--------------------------------------------------------------------------------
local InstancePrinter = class(SubsetPrinter)
InstancePrinter.key = "instance"

local AttributePrinter = class(SubsetPrinter)
AttributePrinter.key = "attribute"
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
    attribute = AttributePrinter,
})

function M:_init(T, args)
    args = args or {}

    self.path = args.path
    self.include_instances = args.include_instances
    self.include_attributes = args.include_attributes
    self.subsets = args.subsets

    self.T = T

    if self.path then
        self.T:trim_for_relevance(self.path, self.subsets)
    end
end

function M:__tostring()
    return self:print_tree(self.T.taxonomy):transform(tostring):join("\n")
end

function M:print_attributes(attributes, indent)
    local lines = List()
    local seen_keys = Dict()
    attributes:keys():sorted():foreach(function(key)
        local key_parts = key:split(".")
        
        local val = attributes[key]
        local entity = self.T.label_to_entity[val]

        if entity then
            local _indent = indent
            key_parts:foreach(function(key_part)
                if not seen_keys[key_part] then
                    lines:append(_indent .. key_part .. ":")
                end
                
                _indent = _indent .. "  "
            end)
            
            -- local entity_printer = self.relation_to_printer[entity.type](entity)
            -- lines:append(_indent .. tostring(entity_printer))
            -- lines:append(val)
            
            seen_keys:set(key_parts)
        end
    end)

    return lines
end

function M:print_tree(tree, instances, indent)
    indent = indent or ""
    local lines = List()
    
    if instances and self.include_instances then
        instances:keys():sorted():foreach(function(instance)
            local entity = self.T.label_to_entity[instance]
            lines:append(self.relation_to_printer[entity.type](entity, indent))
            
            -- print(entity.attributes)
            -- print(require("inspect")(entity.attributes))
            -- if self.include_attributes and entity.attributes then
            --     lines:extend(self:print_attributes(entity.attributes, indent))
            -- end
        end)
    end
    
    Tree(tree):keys():sorted():foreach(function(label)
        local entity = self.T.label_to_entity[label]
        local entity_printer = self.relation_to_printer[entity.type](entity, indent)
        
        local sublines = self:print_tree(
            tree[label],
            self.T.taxon_to_instances[label],
            indent .. self.conf.indent_size
        )
        
        if #sublines > 0 then
            entity_printer.suffix = ":"
        end
        
        lines:append(entity_printer)
        lines:extend(sublines)
    end)
    
    return lines
end

return M
