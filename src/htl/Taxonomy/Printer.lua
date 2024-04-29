local TerminalLink = require("htl.text.TerminalLink")
local Colorize = require("htc.Colorize")
local Taxonomy = require("htl.Taxonomy")

local M = class()

M.conf = Dict(Conf.Taxonomy)
M.conf.indent_size = "  "

--------------------------------------------------------------------------------
--                                   Taxon                                    --
--------------------------------------------------------------------------------
local LinePrinter = class()

function LinePrinter:_init(entity, indent, suffix)
    self.entity = entity
    self.indent = indent or ""
    self.suffix = suffix or ""
    
    self.conf = M.conf.relations[self.entity.type] or {color = {term = 'white'}}
    self.colors = self.conf.color.term
end

function LinePrinter:__tostring()
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

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Printer                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:_init(args)
    args = args or {}

    self.path = args.path
    self.include_instances = args.include_instances
    self.include_attributes = args.include_attributes
    self.instances_only = args.instances_only
    self.subsets = args.subsets

    self.T = Taxonomy._M(args.path)
    utils.time_it("taxonomy creation")

    if self.path or self.subsets then
        self:trim_for_relevance(self.path, self.subsets)
    end

    utils.time_it("taxonomy filtering")
end

function M:trim_for_relevance(path, subset_filters)
    local relevant_instances = Set()
    local relevant_subsets = Set()
    self.T.label_to_entity:foreach(function(label, entity)
        if entity.path and entity.path:is_relative_to(path) then
            if entity.type == "instance" then
                relevant_instances:add(label)
            elseif entity.type == "subset" then
                relevant_subsets:add(label)
            end
        end
    end)
    
    self.T.taxon_to_instances:transformv(function(instances)
        return instances:filterk(function(k) return relevant_instances:has(k) end)
    end):filterk(function(taxon)
        return #self.T.taxon_to_instances[taxon]:keys() > 0
    end)
    
    relevant_subsets:add(self.T.taxon_to_instances:keys())

    local ancestors = self.T.taxonomy:ancestors()
    relevant_subsets:foreach(function(subset)
        relevant_subsets:add(ancestors[subset])
    end)
    
    if #subset_filters > 0 then
        subset_filters = Set(subset_filters)
        local descendants = self.T.taxonomy:descendants()
        subset_filters:foreach(function(subset)
            subset_filters:add(descendants[subset])
        end)
        
        relevant_subsets = relevant_subsets * subset_filters 
    end
    
    local taxonomy = Tree()
    local generations = self.T.taxonomy:generations()
    local irrelevant_subsets = List()
    self.T.taxonomy:nodes():sorted(function(a, b)
        return (generations[a] or 0) < (generations[b] or 0)
    end):foreach(function(subset)
        if relevant_subsets:has(subset) then
            if not taxonomy:get(subset) then
                taxonomy[subset] = self.T.taxonomy:get(subset)
            end
        else
            irrelevant_subsets:append(subset)
        end
    end)
    
    irrelevant_subsets:foreach(function(s) taxonomy:pop(s) end)

    local nodes = Set(taxonomy:nodes())
    self.T.taxon_to_instances:filterk(function(taxon) return nodes:has(taxon) end)
    self.T.taxonomy = taxonomy
end

function M:__tostring()
    local lines = List()
    if self.instances_only then
        lines = self:get_instance_lines()
    else
        lines = self:get_lines()
    end

    return lines:transform(function(l)
        if type(l) == "string" then
            l = {l}
        end

        local key, indent, suffix = unpack(l)
        return tostring(LinePrinter(self.T.label_to_entity[key], indent, suffix))
    end):join("\n")
end

function M:add_keys(dict, keys, indent)
    if dict then
        dict:keys():sorted():reverse():foreach(function(key)
            keys:append({key, indent or ""})
        end)
    end
end

function M:add_instances(dict, lines, indent)
    if self.include_instances and dict then
        dict:keys():sorted():foreach(function(instance)
            lines:append({instance, indent or ""})
        end)
    end
end

function M:get_instance_lines()
    local instances = Set()
    self.T.taxon_to_instances:values():foreach(function(_instances) instances:add(_instances:keys()) end)
    return instances:vals():sorted()
end

function M:get_lines()
    local keys = List()
    self:add_keys(self.T.taxonomy, keys)
    
    local lines = List()
    while #keys > 0 do
        local key, indent = unpack(keys:pop())
        local key_i = #lines + 1
        local pre_count = #keys + #lines
        local _indent = indent .. "  "
        
        self:add_keys(self.T.taxonomy:get(key), keys, _indent)
        
        self:add_instances(self.T.taxon_to_instances[key], lines, _indent)

        local suffix = (#keys + #lines) > pre_count and ":"
        lines:insert(key_i, {key, indent, suffix})
    end
    
    return lines
end

return M
