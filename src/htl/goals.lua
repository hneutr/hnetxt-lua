return function()
    local goals_path = Conf.paths.goals_dir:join(os.date("%Y%m%d") .. ".md")

    if not goals_path:exists() then
        goals_path:write(Conf.paths.daily_intentions_file:read())
    end

    return goals_path
end
