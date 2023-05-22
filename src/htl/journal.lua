local Dict = require("hl.Dict")
local Path = require("hl.path")

local Config = require("htl.config")
local Project = require("htl.project")

local config = Config.get("journal")

local function get_path(args)
    args = Dict.from(args, {
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
