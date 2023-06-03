local class = require("pl.class")
local Path = require("hl.path")

local Notes = require("htl.notes")

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
    local intention_goals = self:get_intention_goals()

    if #intention_goals == 0 then
        intention_goals:append("")
    end

    intention_goals:sort():transform(function(g) return Goal.open_sigil .. " " .. g end)

    if not Path.exists(path) then
        Path.write(path, intention_goals:join("\n"))
    end

    return path
end

function YearSet:get_current(dir)
    return Path.joinpath(dir, self.current_stem .. ".md")
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
