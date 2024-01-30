io = require("hl.io")
local class = require("pl.class")

local List = require("hl.List")
local Path = require("hl.path")
local Config = require("htl.config")
local db = require("htl.db")

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

function Location:_init(args)
    self = Dict.update(self, args or {}, Location.defaults)
    self.path = tostring(self.path)
end

function Location:__tostring()
    local str = self.path

    if #self.label > 0 then
        str = str .. self.config.path_label_delimiter .. self.label
    end

    return str
end

function Location.str_has_label(str)
    return tostring(str):find(Location.config.path_label_delimiter)
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
    local project = db.get()['projects'].get_by_path(dir)

    local query
    if project then
        query = {where = {project = project.title}}
    end

    return db.get()['urls']:get(query):transform(function(url)
        return url.path
    end)
end

function Location.get_mark_locations(dir)
    return List(io.command(Location.get_mark_locations_cmd .. tostring(dir)):splitlines()):filter(function(line)
        return #line > 0
    end):map(function(line)
        local path, mark_str = line:match(Location.regex)
        local mark = Mark.from_str(mark_str)
        return Path(Location({path = path, label = mark.label}))
    end)
end

function Location.get_all_locations(dir)
    return List.from(
        Location.get_file_locations(dir),
        Location.get_mark_locations(dir)
    ):transform(function(path)
        return tostring(path:relative_to(dir))
    end):sorted(function(a, b)
        return #tostring(a) < #tostring(b)
    end)
end

return Location
