table = require("hneutil.table")
string = require("hneutil.string")
io = require("hneutil.io")
local Object = require("hneutil.object")
local Path = require("hneutil.path")

local Config = require("hnetxt-lua.config")
local Link = require("hnetxt-lua.text.link")
local Location = require("hnetxt-lua.text.location")



--------------------------------------------------------------------------------
--                                  Reference                                  
--------------------------------------------------------------------------------
-- format: [text](location)
-- preceded by: any
-- followed by: any
--------------------------------------------------------------------------------
Reference = Object:extend()
Reference.config = Config.get("directory_file")
Reference.config.dir_file_stem = Reference.config.stem
Reference.defaults = {
    label = '',
    location = nil,
    before = '',
    after = '',
}
Reference.get_referenced_marks_cmd = [[rg '\[.*\]\(.+\)' --no-heading --no-filename --no-line-number --hidden ]]
Reference.get_references_cmd = [[rg '\[.*\]\(.+\)' --no-heading --line-number --hidden ]]

function Reference:new(args)
    self = table.default(self, args or {}, self.defaults)
    self.label = self.default_label(self.label, self.location)
end

function Reference.default_label(label, location)
    if label:len() == 0 then
        if location.label:len() > 0 then
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

Reference.str_is_a = Link.str_is_a

function Reference.from_str(str)
    local before, label, location_str, after = str:match(Link.regex)

    return Reference({label = label, location = Location.from_str(location_str), before = before, after = after})
end

function Reference.get_referenced_mark_locations(dir)
    local locations = {}
    local locations_list = {}
    for _, line in ipairs(io.command(Reference.get_referenced_marks_cmd .. dir):splitlines()) do
        while Reference.str_is_a(line) do
            local reference = Reference.from_str(line)

            if not reference.location.path:startswith("http") then
                if reference.location.label:len() > 0 then
                    local location_str = tostring(reference.location)

                    if not locations[location_str] then
                        locations_list[#locations_list + 1] = reference.location
                    end

                    locations[location_str] = true
                end
            end

            line = reference.after
        end
    end

    return locations_list
end

function Reference.get_reference_locations(dir)
    local references = {}
    for _, line in ipairs(io.command(Reference.get_references_cmd .. dir):splitlines()) do
        local path, line_number, ref_str

        local path, line_number, ref_str = unpack(line:split(":", 2))

        references[path] = references[path] or {}
        local line_refs = references[path][line_number] or {}

        while Reference.str_is_a(ref_str) do
            local reference = Reference.from_str(ref_str)

            if not table.list_contains(line_refs, tostring(reference)) then
                line_refs[#line_refs + 1] = tostring(reference)
            end

            ref_str = reference.after
        end

        references[path][line_number] = line_refs
    end

    return references
end

return Reference
