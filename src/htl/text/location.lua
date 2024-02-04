io = require("hl.io")
local class = require("pl.class")

local List = require("hl.List")
local Path = require("hl.path")
local Config = require("htl.config")
local db = require("htl.db")

class.Location()
Location.config = Config.get("location")
Location.delimiter = Location.config.path_label_delimiter
Location.regex = "(.-)" .. Location.delimiter .. "(.*)"
Location.get_mark_locations_cmd = [[rg '\[.*\]\(\)' --no-heading ]]

function Location:_init(args)
    self = Dict.update(self, args or {}, {path = '', label = ''})
    self.path = tostring(self.path)
end

function Location:__tostring()
    return List({self.path, self.label}):filter(function(p) return #p > 0 end):join(self.delimiter)
end

function Location.str_has_label(str)
    return tostring(str):find(Location.delimiter)
end

function Location.from_str(str, args)
    args = Dict.from(args or {}, {relative_to = ''})
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
        local mark = Link.from_str(mark_str)
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
