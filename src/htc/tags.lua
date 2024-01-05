local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Snippet = require("htl.snippet")
local Config = require("htl.config")

local Metadata = require("htl.metadata")

--------------------------------------------------------------------------------
--                                x of the day                                --
--------------------------------------------------------------------------------
function set_x_of_the_day()
    local config = Config.get("x-of-the-day")
    local data_dir = Config.data_dir:join(config.data_dir)

    List(config.commands):foreach(function(command)
        local output_path = data_dir:join(command.name, os.date("%Y%m%d"))

        if not output_path:exists() then
            local path = Files(command):get_random_file()
            output_path:write(tostring(Snippet(path)))
        end
    end)
end

return {
    description = "list tags",
    {
        "conditions",
        args = "*",
        default = {},
        description = "the conditions to meet (fields:value?/@tag.subtag/exclusion!)", 
        action="concat",
    },
    {"-d --dir", default = Path.cwd(), description = "directory", convert=Path.as_path},
    {"-r --reference", description = "print", convert=Path.as_path},
    {"+f", target = "files", description = "list files", switch = "on"},
    {"+p", target = "print", description = "print", switch = "on"},
    {"+x", target = "x_of_the_day", description = "run the x-of-the-day", switch = "on"},
    action = function(args)
        if args.x_of_the_day then
            return set_x_of_the_day()
        end
        
        if args.reference and not args.reference:is_relative_to(Path.cwd()) then
            args.reference = Path.cwd():join(args.reference)
        end

        local files = Metadata.Files(args)

        if args.print then
            print(Snippet(files:get_random_file()))
        elseif args.files then
            files:get_files():foreach(print)
        else
            files:get_map():foreach(print)
        end
    end,
}
