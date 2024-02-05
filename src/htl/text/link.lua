io = require("hl.io")
string = require("hl.string")
local class = require("pl.class")
local List = require("hl.List")
local Dict = require("hl.Dict")

local Config = require("htl.config")

class.Link()
Link.delimiter = Config.get("link").delimiter
Link.label_delimiters = {open = "[", close = "]"}
Link.url_delimiters = {open = "(", close = ")"}
Link.get_references_cmd = [[rg '\[.*\]\(.+\)' --no-heading --line-number --hidden]]

function Link:_init(args)
    Dict.update(self, args or {}, {
        before = '',
        label = '',
        url = '',
        after = '',
    })
end

function Link:regex()
    return List({
        "(.-)", -- before
        self.label_delimiters.open:escape(),
        "(.-)", -- label
        self.label_delimiters.close:escape(),
        self.url_delimiters.open:escape(),
        "(.-)", -- url
        self.url_delimiters.close:escape(),
        "(.*)", -- after
    }):join("")
end

function Link:__tostring()
    return self.before .. self:bare_link_string() .. self.after
end

function Link:bare_link_string()
    return List({
        self.label_delimiters.open .. self.label .. self.label_delimiters.close,
        self.url_delimiters.open .. self.url .. self.url_delimiters.close,
    }):join("")
end

function Link:str_is_a(str)
    return str:match(self:regex())
end

function Link:from_str(str)
    local before, label, url, after = str:match(self:regex())

    if before and label and url and after then
        return self({
            before = before,
            label = label,
            url = url,
            after = after,
        })
    end

    return
end

function Link:get_nearest(str, position)
    local distance_to_link = Dict()

    local dist = 1
    local link = self:from_str(str)
    while link do
        dist = dist + #link.before 
        distance_to_link[math.abs(dist - position)] = link
        dist = dist + #link:bare_link_string() + 1
        distance_to_link[math.abs(dist - position)] = link
        link = self:from_str(link.after)
    end

    return distance_to_link[distance_to_link:keys():sort()[1]]
end

function Link:get_references(dir)
    local cmd = List({self.get_references_cmd, dir}):join(" ")
    
    local url_to_references = Dict()
    io.list_command(cmd):foreach(function(line)
        local path, line_number, str = unpack(line:split(":", 2))
        path = Path(path)

        if not path:is_relative_to(dir) and dir:join(path):exists() then
            path = dir:join(path)
        end

        local link = self:from_str(str)
        while link do
            local url = link.url
            if not url_to_references[url] then
                url_to_references[url] = Dict()
            end

            if not url_to_references[url][tostring(path)] then
                url_to_references[url][tostring(path)] = List()
            end

            url_to_references[url][tostring(path)]:append(tonumber(line_number))

            link = self:from_str(link.after)
        end
    end)

    return url_to_references
end

return Link
