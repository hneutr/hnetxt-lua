string = require("hl.string")
local Date = require("pl.Date")
local Path = require("hl.path")

local class = require("pl.class")
local YearSet = require("htl.goals.set.year")

class.WeekSet(YearSet)

WeekSet.type = 'week'

function WeekSet.get_monday()
    local date = Date()
    local monday_wday = 2

    if date.tab.wday ~= monday_wday then
        date:add({day = -1 * (date.tab.wday - monday_wday)})
    end

    return Date.Format("yyyymmdd"):tostring(date)
end

function WeekSet.get_sunday()
    local date = Date()
    local sunday_wday = 8

    if date.tab.wday ~= sunday_wday then
        date:add({day = sunday_wday - date.tab.wday})
    end

    return Date.Format("yyyymmdd"):tostring(date)
end

WeekSet.current_stem = string.format("%s-%s", WeekSet.get_monday(), WeekSet.get_sunday())

function WeekSet:is_instance(path)
    local stem = Path.stem(path)
    if stem:find("%-") then
        local d1, d2 = unpack(stem:split("-", 1))

        return #d1 == 8 and tonumber(d1) and #d2 == 8 and tonumber(d2)
    end
    return false
end

return WeekSet
