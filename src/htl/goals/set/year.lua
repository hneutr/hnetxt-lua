local class = require("pl.class")
local Path = require("hl.path")

local Config = require("htl.config")

local Goal = require("htl.goals.goal")

class.YearSet()

YearSet.type = 'year'
YearSet.current_stem = os.date("%Y")

function YearSet:is_current(path)
    return Path.stem(path) == self.current_stem
end

function YearSet:is_instance(path)
    local stem = Path.stem(path)
    return #stem == #self.current_stem and tonumber(stem)
end

function YearSet:is_open(path)
    if Path.exists(path) then
        return Goal.any_open(Path.readlines(path))
    end
end

function YearSet:should_be_closed(path)
    return self:is_open(path) and not self:is_current(path)
end

function YearSet:touch(path)
    if not Path.exists(path) then
        Path.write(path, Goal.open_sigil .. " ")
    end
end

function YearSet:get_current(dir)
    return Path.joinpath(dir, self.current_stem .. ".md")
end

return YearSet
