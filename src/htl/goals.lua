local Config = require("htl.config")

return function()
    local config = Config.get("intentions")
    local data_dir = Config.data_dir

    local goals_path = data_dir:join(config.goals_dir, os.date("%Y%m%d") .. ".md")
    local intentions_path = data_dir:join(config.intentions_dir, config.daily_intentions_file)

    if not goals_path:exists() then
        goals_path:write(intentions_path:read())
    end

    return goals_path
end
