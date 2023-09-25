local Path = require("hl.path")

local Config = require("htl.config")

local function get_path(project_dir)
    local config = Config.get("journal")
    local dir = config.global_dir

    if project_dir then
        dir = Path.join(project_dir, config.project_dir) 
    end

    return Path.join(dir, os.date("%Y%m%d") .. ".md")
end

return get_path
