local Path = require("hl.Path")
local List = require("hl.List")
local Dict = require("hl.Dict")
local class = require("pl.class")

local Config = require("htl.Config")

class.Track()
Track.to_track_path = Config.paths.to_track_file

function Track:path(date)
    return Config.paths.track_dir / string.format("%s.md", date or os.date("%Y%m%d"))
end

function Track:touch(args)
    args = args or {}
    local path = self:path(args.date)

    if not path:exists() then
        path:write(self.to_track_path:read())
    end

    return path
end

return Track
