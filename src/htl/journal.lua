local Config = require("htl.Config")

return function()
    local date = os.date("%Y%m%d")
    local path = Conf.paths.journals_dir:join(date .. ".md")

    if not path:exists() then
        path:write({
            "is a: journal entry",
            "",
            "",
        })
    end

    return path
end
