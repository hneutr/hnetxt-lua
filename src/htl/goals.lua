local Config = require("htl.Config")

return function()
    local goals_path = Config.paths.goals_dir:join(os.date("%Y%m%d") .. ".md")

    if not goals_path:exists() then
        goals_path:write(Config.paths.daily_intentions_file:read())
    end

    return goals_path
end
