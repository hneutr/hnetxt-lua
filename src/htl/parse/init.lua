local List = require("hl.PList")
local Dict = require("hl.Dict")

local Object = require("hl.object")
local Path = require("hl.path")

local Fold = require("htl.parse.fold")
local Mark = require("htl.text.mark")
local Header = require("htl.text.header")

local Parser = Object:extend()

function Parser:new(args)
    self = Dict.update(self, args or {})
    self.fold = Fold()
end

function Parser:parse(args)
    args = Dict.from(args, {lines = {}, by_fold_level = true})
    args.line_levels = self.fold:get_line_levels(args.lines)
    return self:parse_line_levels(args)
end

function Parser:parse_line_levels(args)
    args = Dict.from(args, {line_levels = {}, by_fold_level = true})
    local line_levels = args.line_levels

    local current_sections = {}
    local sections = {}
    for line_number, line_level in ipairs(line_levels) do
        for level, section in pairs(current_sections) do
            if level > line_level then
                -- close higher fold levels
                sections[level]:append(section)
                current_sections[level] = nil

            elseif level < line_level then
                -- add the line to the lower fold levels
                current_sections[level]:append(line_number)

            else
                if line_levels[line_number - 1] > level then
                    -- close the previous fold at this level if it's not continuous
                    sections[level]:append(current_sections[level])
                    current_sections[level] = List()
                end
                current_sections[level]:append(line_number)
            end
        end

        current_sections[line_level] = current_sections[line_level] or List({line_number})
        sections[line_level] = sections[line_level] or List()
    end

    for level, section in pairs(current_sections) do
        sections[level]:append(section)
    end

    if not args.by_fold_level then
        local flat_sections = List()
        for _, level_sections in pairs(sections) do
            flat_sections:extend(level_sections)
        end

        table.sort(flat_sections, function(a, b) return a[1] < b[1] end)

        sections = flat_sections
    end

    return sections
end

function Parser:get_mark_content_line_index(args)
    args = Dict.from(args, {mark_label = '', lines = {}, index_type = 'content'})

    local mark_line = Mark.find(args.mark_label, args.lines)

    if mark_line and args.index_type ~= 'content' then
        for size, header in pairs(Header.headers_by_size()) do
            if header:line_is_content(mark_line, args.lines) then
                if args.index_type == 'start' then
                    return mark_line - 1
                elseif args.index_type == 'end' then
                    return mark_line + 1
                end
            end
        end
    end

    return mark_line
end

function Parser:remove_initial_mark(mark_label, lines)
    local mark_end_index = self:get_mark_content_line_index({
        mark_label = mark_label,
        lines = lines,
        index_type = 'end',
    })

    if mark_end_index then
        local new_lines = {}
        for i, line in ipairs(lines) do
            if mark_end_index < i then
                new_lines[#new_lines + 1] = line
            end
        end
        lines = new_lines
    end
    
    return lines
end

function Parser:separate_mark_content(mark_label, lines)
    local start_line = self:get_mark_content_line_index({
        mark_label = mark_label,
        lines = lines,
        index_type = 'start',
    })

    if not start_line then
        return {lines, {}, {}}
    end

    local line_levels = self.fold:get_line_levels(lines)
    local content_level = line_levels[start_line]

    local parse_groups = self:parse_line_levels({line_levels = line_levels})[content_level]

    local end_line
    for _, parse_group in ipairs(parse_groups) do
        if List(parse_group):contains(start_line) then
            end_line = parse_group[#parse_group]
            break
        end
    end

    local before = {}
    local content = {}
    local after = {}
    for i, line in ipairs(lines) do
        if i < start_line then
            before[#before + 1] = line
        elseif start_line <= i and i <= end_line then
            content[#content + 1] = line
        else
            after[#after + 1] = line
        end
    end

    return {before, content, after}

end

function Parser:remove_mark_content(mark_location)
    local lines = Path.readlines(mark_location.path)
    local before, mark_content, after = unpack(self:separate_mark_content(mark_location.label, lines))

    Path.write(mark_location.path, self.merge_line_sets({before, after}))

    return mark_content
end

function Parser:add_mark_content(args)
    args = Dict.from(args, {
        new_content = {},
        from_mark_location = '',
        to_mark_location = '',
        include_mark = false,
    })
    local from_mark_location = args.from_mark_location
    local to_mark_location = args.to_mark_location

    new_content = self:remove_initial_mark(from_mark_location.label, args.new_content)
    
    local before, content, after = {}, {}, {}
    if Path.exists(to_mark_location.path) then
        local lines = Path.readlines(to_mark_location.path)
        before, content, after = unpack(self:separate_mark_content(to_mark_location.label, lines))
    end

    if #content == 0 and args.include_mark and #to_mark_location.label > 0 then
        content = tostring(Header({size = 'large', content = tostring(Mark({label = to_mark_location.label}))}))
    end

    Path.write(to_mark_location.path, self.merge_line_sets({before, content, new_content, after}))
end

function Parser.remove_empty_lines(lines, args)
    args = Dict.from(args, {head = true, tail = true})
    local fn = function(l) while #l > 0 and #l[#l] == 0 do l[#l] = nil end return l end

    local from = args.from

    if args.tail then
        lines = fn(lines)
    end

    if args.head then
        lines = fn(List(lines):reverse()):reverse()
    end

    return lines
end

function Parser.merge_line_sets(line_sets)
    local content = List()
    for i, line_set in ipairs(line_sets) do

        if #content > 0 then
            line_set = Parser.remove_empty_lines(line_set, {tail = false})

            if #line_set > 0 then
                content = Parser.remove_empty_lines(content, {head = false})
                content[#content + 1] = ""
            end
        end

        content = content .. line_set
    end

    return content
end

return Parser
