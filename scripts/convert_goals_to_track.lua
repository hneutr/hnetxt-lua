local Path = require("hl.Path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local Track = require("htl.track")
local GoalSets = require("htl.goals.set")

local day_goal_paths = Path(GoalSets.dir):iterdir({dirs = false}):filter(function(p)
    return p:stem():len() == 8
end)

function line_to_status(line)
    local str_to_bool = {["⨉"] = false, ["✓"] = true}
    return str_to_bool[line:split()[1]]
end

local track_type_remap = Dict({
    ["todos in the morning"] = "morning todos",
    ["intentions: write todos in the morning"] = "morning todos",
    ["journal: morning pages"] = "journal",
    journal = "journal",
    caffeine = "caffeine",
    exercise = "exercise",
    alcohol = "alcohol",
})

function line_to_activity(line)
    local raw = line:split(" ", 1)[2]
    return track_type_remap[raw]
end

local tracker = Track()

day_goal_paths:foreach(function(goal_path)
    local track_path = Track.data_dir:join(goal_path:name())

    local goal_lines = List()
    local track_lines = List()

    if track_path:exists() then
        track_lines = track_path:readlines()
    end

    goal_path:readlines():foreach(function(l)
        local activity = line_to_activity(l)
        local status = line_to_status(l)

        if status ~= nil and activity ~= nil then
            track_lines:append(tracker:activity_to_list_line(activity, status))
        else
            goal_lines:append(l)
        end
    end)

    if #track_lines > 0 then
        goal_path:write(goal_lines)
        track_path:write(track_lines)
    end
end)
