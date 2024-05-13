local Link = class()

Link.delimiter = Conf.link.delimiter
Link.label_delimiters = {open = "[", close = "]"}
Link.url_delimiters = {open = "(", close = ")"}

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

return Link
