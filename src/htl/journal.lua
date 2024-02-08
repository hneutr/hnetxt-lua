local Config = require("htl.Config")

return function()
    local date = os.date("%Y%m%d")
    local path = Config.paths.journals_dir:join(date .. ".md")

    if not path:exists() then
        path:write({
            "date: " .. date,
            "is a: journal entry",
            "",
            "",
        })
    end

    return path
end
