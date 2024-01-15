local Path = require("hl.path")
local Config = require("htl.config").get("journal")

return function()
    local date = os.date("%Y%m%d")
    local path = Path(Config.global_dir):join(date .. ".md")

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
