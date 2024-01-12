local Path = require("hl.path")
local Config = require("htl.config")

return {
    description = "return the path to a journal",
    action = function(args)
        local dir = Path(Config.get("journal").global_dir)
        local date = os.date("%Y%m%d")
        local path = dir:join(date .. ".md")

        if not path:exists() then
            path:write({
                "date: " .. date,
                "is a: journal entry",
                "",
                "",
            })
        end

        print(path)
    end,
}
