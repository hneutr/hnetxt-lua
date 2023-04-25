table = require("hneutil.table")
string = require("hneutil.string")
io = require("hneutil.io")
local Object = require("hneutil.object")
local Path = require("hneutil.path")
local Config = require("hnetxt-lua.config")

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Location                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
-- format: path:text
--------------------------------------------------------------------------------
Location = Object:extend()
Location.config = Config.get("location")
Location.regex = "(.-)" .. Location.config.path_label_delimiter .. "(.*)"
Location.defaults = {
    path = '',
    label = '',
}
Location.get_mark_locations_cmd = [[rg '\[.*\]\(\)' --no-heading ]]
Location.get_files_cmd = [[fd -tf '' ]]

function Location:new(args)
    self = table.default(self, args or {}, Location.defaults)
end

function Location:__tostring()
    local str = self.path

    if self.label:len() > 0 then
        str = str .. self.config.path_label_delimiter .. self.label
    end

    return str
end

function Location.str_has_label(str)
    return str:find(Location.config.path_label_delimiter)
end

function Location:relative_to(dir)
    if Path.is_relative_to(self.path, dir) then
        self.path = Path.relative_to(self.path, dir)
    end
end

function Location.from_str(str)
    local path, label

    if Location.str_has_label(str) then
        path, label = str:match(Location.regex)
    else
        path = str
    end

    return Location({path = path, label = label})
end

function Location.get_file_locations(dir)
    local locations = {}
    for _, line in ipairs(io.command(Location.get_files_cmd .. dir):splitlines()) do
        locations[#locations + 1] = Location({path = line})
    end
    return locations
end

function Location.get_mark_locations(dir)
    local locations = {}
    for _, line in pairs(io.command(Location.get_mark_locations_cmd .. dir):splitlines()) do
        local path, mark_str = line:match("(.-):(.*)")
        local mark = Mark.from_str(mark_str)
        locations[#locations + 1] = Location({path = path, label = mark.label})
    end

    return locations
end

function Location.get_all_locations(dir, args)
    args = table.default(args, {as_str = true, relative_to_dir = true})

    local locations = table.list_extend(Location.get_file_locations(dir), Location.get_mark_locations(dir))

    table.sort(locations, function(a, b) return tostring(a):len() < tostring(b):len() end)

    for i, location in ipairs(locations) do
        if args.relative_to_dir then
            location:relative_to(dir)
        end

        if args.as_str then
            location = tostring(location)
        end
        
        locations[i] = location
    end

    return locations
end

return Location
