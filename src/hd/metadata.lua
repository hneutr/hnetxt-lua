local Path = require("hl.path")
local List = require("hl.List")
local Dict = require("hl.Dict")
local UUID = require("hd.uuid")
local Divider = require('htl.text.divider')
local Link = require('htl.text.link')
local Text = require("hd.text")

local class = require("pl.class")

class.Metadata()

Metadata.link_char = "!"
Metadata.defaults = {
    size = Divider.config.default_size,
    label = "INPUT:label",
    uuid = UUID,
    fields = {
        ["is a"] = "",
        of = "",
    },
}
Metadata.path_prefixes = {
    project = "~",
    of = "/",
    ["is a"] = ".",
    label = ":",
}
Metadata.tab = "  "

function Metadata:_init(args)
    self = Dict.update(self, args or {}, self.defaults)
    self.divider = Divider(self.size)
end

function Metadata:path()
    if type(self.uuid) == 'function' then
        self.uuid = self.uuid()
    end

    return Path.joinpath(Path.cwd(), self.uuid .. ".md")
end

function Metadata:get_field_strings()
    local strings = List()
    Dict(self.fields):foreach(function(k, v)
        strings:append(self.tab .. k .. ": " .. v)
    end)
    return strings
end

function Metadata:write()
    Path.write(self:path(), tostring(self))
end

function Metadata:str_is_definition(str)
    return Metadata.str_is_a(str, self.uuid)
end

function Metadata:search_path()
    return List({
        self:get_path_component(self.fields.of, self.path_prefixes['of']),
        self:get_path_component(self.fields['is a'], self.path_prefixes['is a']),
        self:get_path_component(self.label, self.path_prefixes['label']),
    }):join("")
end

function Metadata:get_path_component(val, prefix)
    local str = ""

    if val ~= nil then
        if type(val) == 'table' then
            val = val.label
        end

        if val:len() > 0 then
            str = prefix .. val
        end
    end

    return str
end

function Metadata.str_is_a(str, uuid)
    if Link.str_is_a(str) then
        local link = Link.from_str(str)
        if link.before == Metadata.link_char and link.after == ":" then
            if uuid == nil or link.location == uuid then
                return true
            end
        end
    end

    return false
end

function Metadata.from_lines(lines)
    lines = List(lines)
    if Metadata.str_is_a(lines[1]) then
        local link = Link.from_str(lines:pop(1))
        local args = {
            uuid = link.location,
            label = link.label,
            fields = Dict(),
        }

        for _, line in ipairs(lines) do
            args.fields:update(Metadata.parse_line(line))
        end

        return Metadata(args)
    end
end

function Metadata.parse_line(line)
    line = line:strip()
    local field, value = unpack(line:split(": ", 1))
    if Link.str_is_a(value) then
        local link = Link.from_str(value)
        value = {label = link.label, location = link.location}
    end

    return {[field] = value}
end

function Metadata:components()
    return List.from(
        {
            tostring(self.divider),
            self.link_char .. "[",
            self.label,
            "](",
            self.uuid,
            "):"
        },
        self:get_field_strings(),
        {tostring(self.divider)}
    )
end

function Metadata:__tostring()
    return Text.components_to_lines(self:components()):join("\n")
end

return Metadata
