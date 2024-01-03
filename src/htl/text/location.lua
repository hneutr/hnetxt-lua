io = require("hl.io")
local class = require("pl.class")

local List = require("hl.List")
local Path = require("hl.path")
local Config = require("htl.config")

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Location                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
-- format: path:text
--------------------------------------------------------------------------------
class.Location()
Location.config = Config.get("location")
Location.regex = "(.-)" .. Location.config.path_label_delimiter .. "(.*)"
Location.defaults = {
    path = '',
    label = '',
}
Location.get_mark_locations_cmd = [[rg '\[.*\]\(\)' --no-heading ]]
Location.get_files_cmd = [[fd -tf '' ]]

-- function Location:new(args)
function Location:_init(args)
    self = Dict.update(self, args or {}, Location.defaults)
end

function Location:__tostring()
    local str = self.path

    if #self.label > 0 then
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

function Location.from_str(str, args)
    args = Dict.from(args, {relative_to = ''})
    local path, label

    if Location.str_has_label(str) then
        path, label = str:match(Location.regex)
    else
        path = str
    end

    if #args.relative_to > 0 and not Path.is_relative_to(path, args.relative_to) then
        path = Path.join(args.relative_to, path)
    end

    return Location({path = path, label = label})
end

function Location.get_file_locations(dir)
    return List(io.command(Location.get_files_cmd .. tostring(dir)):splitlines()):filter(function(line)
        return #line > 0
    end):map(function(line)
        return Location({path = line})
    end)
end

function Location.get_mark_locations(dir)
    return List(io.command(Location.get_mark_locations_cmd .. tostring(dir)):splitlines()):filter(function(line)
        return #line > 0
    end):map(function(line)
        local path, mark_str = line:match(Location.regex)
        local mark = Mark.from_str(mark_str)
        return Location({path = path, label = mark.label})
    end)
end

function Location.get_all_locations(dir, args)
    args = Dict.from(args, {as_str = true, relative_to_dir = true})

    local locations = List.from(Location.get_file_locations(dir), Location.get_mark_locations(dir))

    locations:sort(function(a, b) return #tostring(a) < #tostring(b) end)

    return locations:map(function(location)
        if args.relative_to_dir then
            location:relative_to(dir)
        end

        if args.as_str then
            location = tostring(location)
        end
        
        return location
    end)
end

return Location
