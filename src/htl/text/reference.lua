string = require("hl.string")
io = require("hl.io")
local Dict = require("hl.Dict")
local Path = require("hl.path")

local class = require("pl.class")

local db = require("htl.db")

local Config = require("htl.config")
local Link = require("htl.text.link")
local Location = require("htl.text.location")

local NLink = require("htl.text.NLink")
local LLink = NLink.Link


--------------------------------------------------------------------------------
--                                  Reference                                  
--------------------------------------------------------------------------------
-- format: [text](location)
-- preceded by: any
-- followed by: any
--------------------------------------------------------------------------------
class.Reference(Link)
Reference.config = Config.get("directory_file")
Reference.config.dir_file_stem = Reference.config.stem
Reference.get_referenced_marks_cmd = [[rg '\[.*\]\(.+\)' --no-heading --no-filename --no-line-number --hidden ]]
Reference.get_references_cmd = [[rg '\[.*\]\(.+\)' --no-heading --line-number --hidden ]]

function Reference:_init(args)
    self = Dict.update(self, args or {}, self.defaults)
    self.label = self.default_label(self.label, self.location)
end

function Reference.default_label(label, location)
    label = label or ""
    if #label == 0 then
        if #location.label > 0 then
            label = location.label
        else
            label = Path.stem(location.path)

            if label == Reference.config.dir_file_stem then
                label = Path.name(Path.parent(location.path))
            end
        end
    end

    label = label:gsub("%-", " ")

    return label
end

function Reference:__tostring()
    return tostring(Link({label = self.label, location = tostring(self.location)}))
end

function Reference.from_str(str)
    local before, label, location_str, after = str:match(Link.regex)

    return Reference({label = label, location = Location.from_str(location_str), before = before, after = after})
end

--------------------------------------------------------------------------------
-- get_referenced_locations
-- ------------------------
-- returns table of referenced locations in format:
-- {
--      location = {
--          file = {line_number_1, line_number_2}
--      }
-- }
--------------------------------------------------------------------------------
function Reference.get_referenced_locations(dir)
    dir = tostring(dir)
    local references_by_location = {}
    for _, line in ipairs(io.command(Reference.get_references_cmd .. dir):splitlines()) do
        if #line > 0 then
            local path, line_number, ref_str = unpack(line:split(":", 2))

            if not Path.is_relative_to(path, dir) then
                path = Path.join(dir, path)
            end

            while Reference.str_is_a(ref_str) do
                local reference = Reference.from_str(ref_str)
                local location = tostring(reference.location)
                local location_references = references_by_location[location] or {}

                if not location_references[path] then
                    location_references[path] = {}
                end

                table.insert(location_references[path], tonumber(line_number))
                references_by_location[location] = location_references

                ref_str = reference.after
            end
        end
    end

    return references_by_location
end

function Reference:get(dir)
    local cmd = List({self.get_references_cmd, dir}):join("")
    
    local url_to_references = Dict()

    io.list_command(cmd):foreach(function(line)
        local path, line_number, str = unpack(line:split(":", 2))
        path = Path(path)

        if not path:is_relative_to(dir) and dir:join(path):exists() then
            path = dir:join(path)
        end

        local link = LLink:from_str(str)
        while link do
            local url = link.url
            if not url_to_references[url] then
                url_to_references[url] = Dict()
            end

            if not url_to_references[url][tostring(path)] then
                url_to_references[url][tostring(path)] = List()
            end

            url_to_references[url][tostring(path)]:append(tonumber(line_number))

            link = LLink:from_str(link.after)
        end
    end)

    return url_to_references
end

return Reference
