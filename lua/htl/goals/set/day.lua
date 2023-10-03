local class = require("pl.class")
local YearSet = require("htl.goals.set.year")

class.DaySet(YearSet)

DaySet.type = 'day'
DaySet.current_stem = os.date("%Y%m%d")

return DaySet
