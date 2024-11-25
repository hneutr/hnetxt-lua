local TerminalLink = require("htl.text.TerminalLink")
local Color = require("htl.Color")
local Taxonomy = require("htl.Metadata.Taxonomy")

local M = class()

M.conf = Conf.Taxonomy

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
    "instance",
    "predicate",
})

function LinePrinter:_init(url, type)
    self.url = url
    self.type = type
    self.indent = ""
    self.sublines = List()
    self.id = self.url.id

    self.color = M.conf.color[self.type] or 'white'
end

function LinePrinter:__tostring()
    return self.indent .. tostring(self:get_label()) .. self:get_suffix()
end

function LinePrinter:get_label()
    if self.url.type == "file" then
        return TerminalLink({
            label = self.url.label,
            url = self.url.id,
            colors = {label = self.color},
        })
    end

    return Color({self.url.label, self.color})
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
    self.conditions = args.conditions

    self.types = Set({"subset"})

    if args.include_instances then
        self.types:add("instance")
    end

    self.T = Taxonomy(args)
end

function M:__tostring()
    local taxonomy = self.T.taxonomy
    local taxa = self:get_urls(taxonomy, "subset")

    local lines = List(taxa)
    while #taxa > 0 do
        local taxon = taxa:pop()
        taxon.sublines:extend(self:get_urls(taxonomy:get(taxon.id), "subset"))
        taxa:extend(taxon.sublines)
        taxon.sublines:extend(self:get_urls(taxonomy.taxon_instances[taxon.id], "instance"))
    end

    return lines:transform(tostring):join("\n")
end

function M:get_urls(ids, type)
    if self.types:has(type) then
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

return M
