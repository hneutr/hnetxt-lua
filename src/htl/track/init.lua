local cjson = require("cjson")
local DataFrame = require("hl.DataFrame")
local Path = require("hl.Path")
local List = require("hl.List")
local Dict = require("hl.Dict")
local class = require("pl.class")

local Config = require("htl.config")

class.Track()

Track.config = Config.get('track')
Track.config.activities = List(Track.config.activities)
Track.data_dir = Config.data_dir:join(Track.config.data_dir)

function Track:_init()
    self = Dict.update(self, Track.config)
    self:set_up_activities()
end

function Track:set_up_activities()
    local activities = List()
    local activity_defaults = Dict()


    self.activities:transform(Dict):foreach(function(raw)
        local activity = raw:keys()[1]
        activities:append(activity)
        activity_defaults[activity] = raw[activity].default or false
    end)

    self.activities = activities
    self.activity_defaults = activity_defaults
end

function Track.default_date(date)
    date = date or os.date("%Y%m%d")
    return tostring(date)
end

function Track:list_path(date)
    return self.data_dir:join(self.default_date(date) .. ".md")
end

function Track:date_from_list_path(list_path)
    return tonumber(list_path:stem())
end

function Track:csv_path()
    return self.data_dir:join(".log.csv")
end

function Track:activity_to_list_line(activity, value)
    if value == nil then
        value = self.activity_defaults[activity]

        if value == nil then
            value = ' '
        end
    end

    return self.surround .. activity .. self.surround .. self.separator .. tostring(value)
end

function Track:list_lines()
    return self.activities:map(function(e) return self:activity_to_list_line(e) end)
end

function Track:touch(date)
    local list_path = self:list_path(date)

    if not list_path:exists() then
        list_path:write(self:list_lines())
    end

    return list_path
end

function Track:list_line_to_row(line, date)
    line = line:gsub(self.surround, "")
    local field, value = unpack(line:rsplit(self.separator, 1))
    value = value:strip()

    if #value == 0 then
        value = nil
    elseif value == 'true' then
        value = true
    elseif value == 'false' then
        value = false
    else
        value = tonumber(value)
    end

    if value ~= nil then
        return {field = field, value = value, date = self.default_date(date)}
    end
end

function Track:list_path_to_rows(list_path)
    local date = self:date_from_list_path(list_path)
    return list_path:readlines():transform(function(line)
        return self:list_line_to_row(line, date)
    end):filter(function(r) return r ~= nil end)
end

function Track:create_csv()
    local rows = List()
    self.data_dir:iterdir({dirs = false}):foreach(function(p)
        if p ~= self:csv_path() then
            rows:extend(self:list_path_to_rows(p))
        end
    end)

    DataFrame.to_csv(rows, self:csv_path(), {cols = {"date", "field", "value"}})
end

return Track
