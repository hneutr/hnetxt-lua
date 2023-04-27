table = require("hneutil.table")
local Object = require("hneutil.object")
local Fold = require("hnetxt-lua.parse.fold")
local Mark = require("hnetxt-lua.text.mark")
local Header = require("hnetxt-lua.text.header")

local Parser = Object:extend()

function Parser:new(args)
    self = table.default(self, args or {})
    self.fold = Fold()
end

function Parser:parse(lines)
    local current_sections = {}
    local all_sections = {}
    local line_levels = self.fold:get_line_levels(lines)
    for line_number, line_level in ipairs(line_levels) do
        for level, section in pairs(current_sections) do
            if level > line_level then
                -- close higher fold levels
                table.insert(all_sections[level], section)
                current_sections[level] = nil

            elseif level < line_level then
                -- add the line to the lower fold levels
                table.insert(current_sections[level], line_number)

            else
                if line_levels[line_number - 1] > level then
                    -- close the previous fold at this level if it's not continuous
                    table.insert(all_sections[level], current_sections[level])
                    current_sections[level] = {}
                end
                table.insert(current_sections[level], line_number)
            end
        end

        if not current_sections[line_level] then
            current_sections[line_level] = {line_number}
            all_sections[line_level] = all_sections[line_level] or {}
        end
    end

    for level, section in pairs(current_sections) do
        table.insert(all_sections[level], section)
    end

    return all_sections
end

--function MarkOperation.remove_mark_content_from_file(args)
--    local content = Path.read(args.path)
--    local mark_content

--    content, mark_content = unpack(remove_mark_content(content, args.mark))
--    Path.write(args.path, content)
--    return mark_content
--end

----[[
--add_mark_content_to_file(file, new_mark_content, mark, include_header=false):
--        1. content = Path.read(file)
--        2. before, mark_content, after = partition_mark_content(content, mark)
--            - if mark_content:len() > 0:
--                - mark_content += new_mark_content
--            - else:
--                - if include_header:
--                    - after += Header(mark)
--                - after += new_mark_content
--        3. Path.write(before .. mark_content .. after)
--    ]]
--function MarkOperation.add_mark_content_to_file(args)
--    local content = Path.read(path)

--    content, mark_content = unpack(remove_mark_content(content, mark))
--    Path.write(path, content)
--    return mark_content
--end


return Parser
