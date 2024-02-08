local Path = require("hl.Path")
local List = require("hl.List")
local Dict = require("hl.Dict")
local class = require("pl.class")

local Config = require("htl.Config")

class.Track()

Track.config = Config.get('track')
Track.data_dir = Config.paths.track_dir

function Track:_init()
    self = Dict.update(self, Track.config)
    self:set_up_config()
end

function Track:set_up_config()
    local categories = List()
    local activities = Dict()

    local order = 1
    List(self.categories):foreach(function(category_config)
        categories:append(category_config.name)
        List(category_config.activities):foreach(function(activity_config)
            activity_config.category = category
            activity_config.order = order
            order = order + 1

            if activity_config.default == nil then
                activity_config.default = self.datatype_defaults[activity_config.datatype]
            end

            activities[activity_config.name] = activity_config
        end)
    end)

    self.categories = categories
    self.activities = activities
end

function Track.default_date(date)
    date = date or os.date("%Y%m%d")
    return tostring(date)
end

function Track:list_path(date)
    return self.data_dir:join(self.default_date(date) .. ".md")
end

function Track:activity_to_list_line(activity, value)
    if value == nil then
        local config = self.activities[activity] or {}
        value = config.default

        if value == nil then
            value = ' '
        end
    end

    return activity .. self.separator .. tostring(value)
end

function Track:list_lines()
    return self.activities:keys():sort(function(a, b)
        local a_config = self.activities[a] or {order = 0}
        local b_config = self.activities[b] or {order = 0}
        return a_config.order < b_config.order
    end):map(function(a)
        return self:activity_to_list_line(a)
    end)
end

function Track:touch(date)
    local list_path = self:list_path(date)

    if not list_path:exists() then
        list_path:write(self:list_lines())
    end

    return list_path
end

return Track
