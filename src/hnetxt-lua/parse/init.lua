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
    local sections_by_level = {0 = {{}}}
    for line_number, level in pairs(self.fold:get_line_levels(lines)) do
        -- start a new section if last line number in section wasn't line_number - 1
        for _level, _level_sections in pairs(sections_by_level) do
            if level <= _level then
                local _level_section = _level_sections[#_level_sections]
                local section_size = #_level_section
                if section_size == 0 or _level_section[section_size] + 1 == line_number then
                    _level_section[section_size + 1] = line_number
                else
                    table.insert(sections_by_level[_level], {line_number})
                end
            end
        end
    end

    return sections_by_level
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
