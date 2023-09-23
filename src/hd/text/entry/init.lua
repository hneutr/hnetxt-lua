local class = require("pl.class")
local Path = require("hl.path")

local Config = require("htl.config")
local Divider = require("htl.text.divider")
local Metadata = require("hd.metadata")

class.Entries()

Entries.data_dir = Config.get_data_dir("entries")

function Entries.dir(...)
    return Path.joinpath(Entries.data_dir, ...)
end

function Entries.parse(lines)
    return Divider.parse_divisions(lines):map(function(division_line_numbers)
        local division_lines = division_line_numbers:map(function(line_number)
            return lines[line_number]
        end)

        return Metadata.from_lines(division_lines)
    end):filter(function(entry)
        return entry ~= nil
    end)
end

function Entries.paths(lines)
    return Entries.parse(lines):transform(function(entry)
        return entry:search_path()
    end)
end

return Entries
