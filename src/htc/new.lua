local Path = require("hl.path")

local Metadata = require("hd.metadata")

return {
    description = "make a new entry",
    {"+d --date", description = "use today's date for the file name", switch = 'on'},
    action = function(args)
        local i = 1
        local base_stem = ""
        local suffix = ".md"

        if args.date then
            base_stem = os.date("%Y%m%d")
            i = 0
        end

        local dir = Path.cwd()
        while true do
            local stem = base_stem

            if i > 0 then
                if stem:len() > 0 then
                    stem = stem .. "-"
                end

                stem = stem .. tostring(i)
            end

            path = Path.joinpath(dir, stem .. suffix)

            if Path.exists(path) then
                i = i + 1
            else
                print(path)
                return
            end
        end

        -- local note = Metadata()
        -- note:write()
        -- print(note:path())
    end,
}
