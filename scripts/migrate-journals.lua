local Path = require("hl.Path")
local List = require("hl.List")
local Config = require("htl.config")
local Divider = require("htl.text.divider")
local Link = require("htl.text.link")

local source_dir = Path.home:join("Documents", "text", "written", "fiction", "chasefeel", ".journal")
local output_dir = Path(Config.get("journal").global_dir)
local divider = "--------------------------------------------------------------------------------"

source_dir:iterdir():foreach(function(p)
    p:read():split(divider):transform(function(entry)
        return entry:strip():split("\n")
    end):filter(function(lines)
        return #lines > 1
    end):foreach(function(lines)
        local date = p:stem()
        if Link.str_is_a(lines[1]) then
            date = Link.from_str(lines:pop(1)).label
        end

        local new_entry_path = output_dir:join(date .. ".md")

        local pre_lines = List()
        if new_entry_path:exists() then
            for line in new_entry_path:readlines():iter() do
                pre_lines:append(line)
                if line == "is a: journal entry" then
                    pre_lines:append("  project: chasefeel")
                end
            end

            pre_lines:extend({
                "",
                tostring(Divider("large")),
                ""
            })

        else
            pre_lines = List({
                "date: " .. date,
                "is a: journal entry",
                "  project: chasefeel",
                "",
            })
        end

        lines = pre_lines:extend(lines)
        new_entry_path:write(lines)
    end)

    p:unlink()
end)
