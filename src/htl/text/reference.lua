string = require("hl.string")
io = require("hl.io")
local Dict = require("hl.Dict")
local Path = require("hl.path")

local class = require("pl.class")

local db = require("htl.db")

local Config = require("htl.config")
local Link = require("htl.text.link")
local Location = require("htl.text.location")


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

function Reference.get_referenced_mark_locations(dir)
    dir = tostring(dir)
    local locations = {}
    local locations_list = {}
    for _, line in ipairs(io.command(Reference.get_referenced_marks_cmd .. dir):splitlines()) do
        while Reference.str_is_a(line) do
            local reference = Reference.from_str(line)

            if not reference.location.path:startswith("http") then
                if #reference.location.label > 0 then
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

--------------------------------------------------------------------------------
-- update
-- ------
-- takes a dict of location changes in format: {old = new}
--
-- for each location change, updates references to those locations:
--      - if `old` is a mark (ie #old.label > 0) then:
--          - point old references → new
--      - if `old` is a file (ie #old.label == 0):
--          - point old references → new
--          - point references to marks in old → new
--------------------------------------------------------------------------------
function Reference.update_locations(location_changes, dir)
    dir = tostring(dir or db.get().projects.get_path())
    local relative_location_changes = {}
    for k, v in pairs(location_changes or {}) do
        if Path.is_relative_to(k, dir) then
            k = Path.relative_to(k, dir)
        end
        if Path.is_relative_to(v, dir) then
            v = Path.relative_to(v, dir)
        end

        relative_location_changes[k] = v
    end
    local old_locations = Dict.keys(relative_location_changes)

    -- sort from longest to shortest so that file updates don't "clobber" mark updates
    table.sort(old_locations, function(a, b) return #a > #b end)

    local content_updates = {}
    local references_by_location = Reference.get_referenced_locations(dir)
    for _, old_location in ipairs(old_locations) do
        references_by_location, content_updates = unpack(Reference.update_location(
            old_location,
            relative_location_changes[old_location],
            references_by_location,
            content_updates
        ))
    end

    for path, content in pairs(content_updates) do
        Path(path):write(content)
    end
end

function Reference.update_location(old_location, new_location, references_by_location, content_updates)
    old_location = tostring(old_location)
    new_location = tostring(new_location)
    local old_location_is_file = not Location.str_has_label(old_location)
    for referenced_location, references in pairs(references_by_location) do
        local update = old_location == referenced_location
        update = update or (old_location_is_file and referenced_location:startswith(old_location)) 

        if update then
            for reference_path, reference_lines in pairs(references) do
                if not content_updates[reference_path] then
                    content_updates[reference_path] = Path.readlines(reference_path)
                end

                for _, reference_line in ipairs(reference_lines) do
                    content_updates[reference_path][reference_line] = string.gsub(
                        content_updates[reference_path][reference_line],
                        old_location:escape(),
                        new_location
                    )
                end
            end
            references_by_location[referenced_location] = nil
        end
    end

    return {references_by_location, content_updates}
end

return Reference
