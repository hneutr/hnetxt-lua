table = require("hneutil.table")

local Path = require("hneutil.path")

local Config = require("hnetxt-lua.config")
local Project = require("hnetxt-lua.project")

local config = Config.get("journal")

local function get_path(args)
    args = table.default(args, {
        year = os.date("%Y"),
        month = os.date("%m"),
    })
    
    local dir
    if args.project then
        dir = Path.joinpath(Project(args.project).root, config.project_dir)
    else
        dir = config.dir
    end

    local file = string.format("%s%s.md", args.year, args.month)
    return Path.joinpath(dir, file)
end

return get_path
