local Path = require("hl.path")

local config = require("htl.config").get("goals")
config.template_file = Path.joinpath(config.dir, config.template_filename)

function get_path(args)
    args = table.default(args, {
        year = os.date("%Y"),
        month = os.date("%m"),
    })
    
    local filename = args.year .. args.month .. ".md"
    local path = Path.joinpath(config.dir, filename)

    if not Path.exists(path) then
        Path.write(path, Path.read(config.template_file))
    end

    return path
end

return get_path
