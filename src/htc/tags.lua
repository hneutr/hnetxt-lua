local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Yaml = require("hl.yaml")

local exclusions = List({'.project'})

return {
    description = "list tags",
    {"tag", args = "?", description = "the tag to look for"},
    {"-d --dir", default = Path.cwd(), description = "directory"},
    -- {"-p --path", description = "the file to look for tags in"},
    action = function(args)
        local paths = Path.iterdir(args.dir, {dirs = false}):filter(function(p)
            return not exclusions:contains(p:name())
        end)

        local tags = List()
        local tagged_paths = Dict()
        paths:foreach(function(path)
            List(Yaml.read_raw_frontmatter(tostring(path))):foreach(function(line)
                if line:startswith("@") then
                    tag = line:removeprefix("@")

                    if #tag > 0 then
                        if not tagged_paths[tag] then
                            tagged_paths[tag] = List()
                        end

                        tagged_paths[tag]:append(path:relative_to(args.dir))

                        if not tags:contains(tag) then
                            tags:append(tag)
                        end
                    end
                end
            end)
        end)

        local to_print

        if args.tag then
            print(args.tag .. ":")
            to_print = tagged_paths[args.tag]:map(function(v) return "    " .. v end)
        else
            to_print = tags
        end

        to_print:sorted():foreach(print)
    end,
}
