local class = require("pl.class")
local YearSet = require("htl.goals.set.year")

class.MonthSet(YearSet)

MonthSet.type = 'month'
MonthSet.current_stem = os.date("%Y%m")

return MonthSet
