local Path = require("hl.path")
local List = require("hl.List")

local Config = require("htl.config")

local YearSet = require("htl.goals.set.year")
local MonthSet = require("htl.goals.set.month")
local WeekSet = require("htl.goals.set.week")
local DaySet = require("htl.goals.set.day")
local UndatedSet = require("htl.goals.set.undated")

local Sets = {}
Sets.config = Config.get("goals")

Sets.classes = List({
    YearSet,
    MonthSet,
    WeekSet,
    DaySet,
    UndatedSet,
})

function Sets.get_class(path)
    for _, SetClass in ipairs(Sets.classes) do
        if SetClass():is_instance(path) then
            return SetClass
        end
    end

    return UndatedSet
end

function Sets.touch(path)
    if not Path.is_relative_to(path, Sets.config.dir) then
        path = Path.joinpath(Sets.config.dir, path)
    end

    path = Path.with_suffix(path, ".md")

    if not Path.exists(path) then
        Sets.get_class(path):touch(path)
    end

    return path
end

function Sets.to_close()
    local paths = List(Path.iterdir(Sets.config.dir, {recursive = false, dirs = false}))
    return paths:filter(function(p)
        return Sets.get_class(p):should_be_closed(p)
    end)
end

function Sets.to_create()
    return Sets.classes:map(function(c)
        return c:get_current(Sets.config.dir)
    end):filter(function(c)
        return c and not Path.exists(c)
    end):transform(function(c)
        return Path.relative_to(c, Sets.config.dir)
    end)
end


return Sets
