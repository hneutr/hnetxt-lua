table = require("hneutil.table")
local Path = require("hneutil.path")
local Config = require("hnetxt-lua.config")

local M = {}

M.config = Config.get("goals")
M.config.template_file = Path.joinpath(M.config.dir, M.config.template_filename)

function M.get_path(args)
    args = table.default(args, {
        year = os.date("%Y"),
        month = os.date("%m"),
    })
    
    local filename = args.year .. args.month .. ".md"
    local path = Path.joinpath(M.config.dir, filename)

    if not Path.exists(path) then
        Path.write(path, Path.read(M.config.template_file))
    end

    return path
end

return M
