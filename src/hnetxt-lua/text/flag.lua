table = require("hneutil.table")
string = require("hneutil.string")
io = require("hneutil.io")
local Object = require("hneutil.object")
local Path = require("hneutil.path")
local Config = require("hnetxt-lua.config")

Flag = Object:extend()
Flag.defaults = {
    before = '',
    after = '',
}
Flag.types = Config.get("flags")
Flag.list_types = Config.get("list").types
Flag.dir_file_stem = Config.get("directory_file").stem

function Flag:new(args)
    self = table.default(self, args or {}, self.defaults)
end

function Flag:__tostring()
    local chars = {}

    for name, info in pairs(self.types) do
        if self[name] then
            chars[info.order] = info.symbol
        end
    end

    local text = table.concat(chars)

    return "|" .. text .. "|"
end

function Flag.regex()
    local flag_characters = ""
    for name, info in pairs(Flag.types) do
        flag_characters = flag_characters .. info.regex_symbol
    end

    local before_re = "(.-)"
    local flags_re = "|([" .. flag_characters .. "]+)|"
    local after_re = "(.*)"

    return before_re .. flags_re .. after_re
end

function Flag.str_is_a(str) 
    local before, location, after = str:match(Flag.regex())

    if location ~= nil then
        local partial_location = location
        for name, info in pairs(Flag.types) do
            partial_location = partial_location:gsub(info.regex_symbol, '')
        end

        if partial_location:len() == 0 then
            return true
        end
    end

    return false
end

function Flag.from_str(str)
    local args = {}
    local before, flags_string, after = str:match(Flag.regex())

    args.before = before
    args.after = after

    for name, info in pairs(Flag.types) do
        if flags_string:find(info.regex_symbol) then
            args[name] = true
        end
    end

    return Flag(args)
end

function Flag.get_instances(flag_type, dir)
    local other_flag_regexes =  {}
    for name, info in pairs(Flag.types) do
        if name ~= flag_type then
            other_flag_regexes[#other_flag_regexes + 1] = "\\" .. info.symbol
        end
    end

    local flag_regex = "\\" .. Flag.types[flag_type].symbol
    local other_flags_regex = "[" .. table.concat(other_flag_regexes) .. "]*"

    local pattern = other_flags_regex .. flag_regex .. other_flags_regex
    local command = [[rg --no-heading "\|]] .. pattern .. [[\|" ]] .. dir

    local instances = {}
    for _, result in ipairs(io.command(command):splitlines()) do
        local path, text = result:match("(.-)%.md%:(.*)")
        instances[#instances + 1] = Flag.clean_flagged_path(path, dir) .. ": " .. Flag.clean_flagged_str(text)
    end

    return instances
end

function Flag.clean_flagged_path(path, dir)
    if dir then
        path = Path.relative_to(path, dir)
    end

    if Path.stem(path) == Flag.dir_file_stem then
        path = Path.parent(path)
    end

    path = Path.name(path)
    path = path:gsub("%-", " ")
    return path
end

function Flag.clean_flagged_str(str)
    str = str:gsub("|.*|", "")
    str = str:strip()
    str = str:gsub("^>%s*", "")
    str = str:gsub("^%d+%.%s*", "")

    for list_type, info in pairs(Flag.list_types) do
        if info.sigil then
            str = str:removeprefix(info.sigil)
        end
    end

    str = str:strip()
    str = str:gsub("%[", "")
    str = str:gsub("%]%(.*%)", "")
    str = str:strip()
    return str
end

return Flag
