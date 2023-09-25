string = require("hl.string")
local class = require("pl.class")
local List = require("hl.List")
local Dict = require("hl.Dict")
local Set = require("pl.Set")

local Config = require("htl.config")

local TextList = require("htl.text.list")

class.Goal()
Goal.config = Config.get('goals')
Goal.parser = TextList.Parser()
Goal.closed_set = Set({'done', 'reject'})
Goal.open_sigil = Config.get('list').types.todo.sigil

function Goal:_init(line)
    self.line = line
    self.text_line = self.parser:parse_line(line, 1)
    self.line_type = self.text_line.name
end

function Goal:completed()
    return self.line_type == 'done'
end

function Goal:open()
    return not self.closed_set[self.line_type]
end

function Goal.any_open(lines)
    return 0 < #List(lines):filter(function(l) 
        return #l > 0
    end):transform(Goal):filter(function(g)
        return g:open()
    end)
end

function Goal.any_completed(lines)
    return 0 < #List(lines):transform(Goal):filter(function(g) return g:completed() end)
end

function Goal.parse(str)
    local parse = {str = str}

    parse = Goal.parse_project(parse)
    parse = Goal.parse_qualifier(parse)
    parse = Goal.parse_scope(parse)

    if #parse.str > 0 then
        parse.object = parse.str
    end
    parse.str = nil

    return parse
end

function Goal.parse_project(parse)
    local str = parse.str or ""
    if str:endswith(Goal.config.format.project.close) and str:find(Goal.config.format.project.open) then
        str = str:removesuffix(Goal.config.format.project.close)
        str, parse.project = unpack(str:rsplit(Goal.config.format.project.open, 1))
        str = str:strip()
    end

    parse.str = str

    return parse
end

function Goal.format_qualifier(raw)
    for qualifier, config in pairs(Goal.config.qualifiers) do
        if config.has_number then
            local value = tonumber(raw:match(string.format("(.+)%s$", config.unit)) or "")

            if value then
                return {[qualifier] = value}
            end
        elseif raw == config.unit then
            return {[qualifier] = true}
        end
    end
end

function Goal.parse_qualifier(parse)
    local str = parse.str or ""
    local open = Goal.config.format.qualifier.open
    local close = Goal.config.format.qualifier.close
    if str:endswith(close) and str:find(string.escape(open)) then
        str = str:removesuffix(close)
        str, parse.qualifier = unpack(str:rsplit(open, 1))
        str = str:strip()

        parse.qualifier = Goal.format_qualifier(parse.qualifier)
    end

    parse.str = str

    return parse
end

function Goal.parse_scope(parse)
    local str = parse.str or ""
    if str:find(Goal.config.format.scope.delimiter) then
        parse.scope, str = unpack(str:rsplit(Goal.config.format.scope.delimiter, 1))
        str = str:strip()
    end

    parse.str = str

    return parse
end

return Goal
