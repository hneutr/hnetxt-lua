table = require("hneutil.table")
string = require("hneutil.string")
io = require("hneutil.io")
local Object = require("hneutil.object")
local Path = require("hneutil.path")
local Config = require("hnetxt-lua.config")

--------------------------------------------------------------------------------
--                                  Location                                   
--------------------------------------------------------------------------------
-- format: path:text
--------------------------------------------------------------------------------
Location = Object:extend()
Location.config = Config.get("location")
Location.regex = "(.-)" .. Location.config.path_label_delimiter .. "(.*)"
Location.defaults = {
    path = '',
    label = '',
}
Location.get_mark_locations_cmd = [[rg '\[.*\]\(\)' --no-heading ]]
Location.get_files_cmd = [[fd -tf '' ]]

function Location:new(args)
    self = table.default(self, args or {}, Location.defaults)
end

function Location:__tostring()
    local str = self.path

    if self.label:len() > 0 then
        str = str .. self.config.path_label_delimiter .. self.label
    end

    return str
end

function Location.str_has_label(str)
    return str:find(Location.config.path_label_delimiter)
end

function Location.from_str(str)
    local path, label

    if Location.str_has_label(str) then
        path, label = str:match(Location.regex)
    else
        path = str
    end

    return Location({path = path, label = label})
end

function Location.get_file_locations(dir)
    local locations = {}
    for _, line in ipairs(io.command(Location.get_files_cmd .. dir):splitlines()) do
        locations[#locations + 1] = Location({path = line})
    end
    return locations
end

function Location.get_mark_locations(dir)
    local locations = {}
    for _, line in pairs(io.command(Location.get_mark_locations_cmd .. dir):splitlines()) do
        local path, mark_str = line:match("(.-):(.*)")
        local mark = Mark.from_str(mark_str)
        locations[#locations + 1] = Location({path = path, label = mark.label})
    end

    return locations
end

function Location.get_all_locations(dir, as_str)
    as_str = as_str or false
    local locations = table.list_extend(Location.get_file_locations(dir), Location.get_mark_locations(dir))
    table.sort(locations, function(a, b) return tostring(a):len() < tostring(b):len() end)

    if as_str then
        for i, location in ipairs(locations) do
            locations[i] = tostring(location)
        end
    end

    return locations
end




-- function Location.update(args)
--     args = table.default(args, {old_location = nil, new_location = nil})

--     local old = args.old_location:gsub('/', '\\/')
--     local new = args.new_location:gsub('/', '\\/')

--     local cursor = vim.api.nvim_win_get_cursor(0)

--     local cmd = "%s/\\](" .. old .. ")/\\](" .. new .. ")/g"
--     pcall(function() vim.cmd(cmd) return end)
--     vim.api.nvim_win_set_cursor(0, cursor)
-- end



-- function Location.goto(open_command, str)
--     local location = Location.from_str(str)

--     if location.path ~= Path.current_file() then
--         Path.open(location.path, open_command)
--     end

--     if location.text:len() > 0 then
--         Mark.goto(location.text)
--     end
-- end

return Location
