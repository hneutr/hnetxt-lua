local Path = require("hl.path")
local List = require("hl.List")
local GoalSets = require("htl.goals.set")
local WeekSet = require("htl.goals.set.week")

local shorthands = {
    d = os.date("%Y%m%d"),
    w = WeekSet.current_stem,
    m = os.date("%Y%m"),
    y = os.date("%Y"),
}

local function convert_shorthand(set)
    set = shorthands[set or 'd'] or set

    if #Path.suffix(set) == 0 then
        set = set .. ".md"
    end

    return set
end

local function shorthand_help()
    return "\n" .. List({'d', 'w', 'm', 'y'}):transform(function(s)
        return string.format(" %s = %s", s, convert_shorthand(s))
    end):join("\n") .. "\n"
end

return {
    description = "touch and return a goalset path.",
    {
        "path",
        description = "a set path or shorthand: " .. shorthand_help(),
        default = convert_shorthand('d'),
        convert = convert_shorthand,
    },
    action = function(args)
        print(GoalSets.touch(args.path))
    end,
}
