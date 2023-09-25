local class = require("pl.class")
local Path = require("hl.Path")

local Notes = require("htl.notes")

local Config = require("htl.config")

local Goal = require("htl.goals.goal")

class.YearSet()

YearSet.type = 'year'
YearSet.current_stem = os.date("%Y")

function YearSet:is_current(path)
    return Path(path):stem() == self.current_stem
end

function YearSet:is_instance(path)
    local stem = Path(path):stem()
    return #stem == #self.current_stem and tonumber(stem)
end

function YearSet:is_open(path)
    path = Path(path)
    if path:exists() then
        return Goal.any_open(path:readlines())
    end
end

function YearSet:should_be_closed(path)
    return self:is_open(path) and not self:is_current(path)
end

function YearSet:touch(path)
    local intention_goals = self:get_intention_goals()

    if #intention_goals == 0 then
        intention_goals:append("")
    end

    intention_goals:sort():transform(function(g) return Goal.open_sigil .. " " .. g end)

    path = Path(path)
    if not path:exists() then
        path:write(intention_goals:join("\n"))
    end

    return path
end

function YearSet:get_current(dir)
    return Path(dir):join(self.current_stem .. ".md")
end

function YearSet:get_intention_goals()
    local sets = Notes.all_sets_of_type("intention")
    local intention_goals = List()
    sets:foreachv(function(set)
        for _, path in ipairs(set:files()) do
            local note_file = set:path_file(path)
            note_file.filters = Dict.update(note_file.filters, {start = true, ["end"] = true})

            local metadata = note_file:get_filtered_metadata()

            if metadata.goal_type == self.type then
                intention_goals:append(metadata.goal)
            end
        end
    end)

    return intention_goals
end

return YearSet
