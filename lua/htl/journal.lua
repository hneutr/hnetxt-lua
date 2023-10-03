local Path = require("hl.path")
local Config = require("htl.config").get("journal")

return function(project_dir)
    local dir = Path(Config.global_dir)

    if project_dir then
        dir = Path(project_dir):join(Config.project_dir)
    end

    return tostring(dir:join(os.date("%Y%m%d") .. ".md"))
end
