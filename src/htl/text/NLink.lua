string = require("hl.string")
local class = require("pl.class")
local List = require("hl.List")
local Dict = require("hl.Dict")

local Config = require("htl.config")

class.NLink()
NLink.delimiter = Config.get("link").delimiter
NLink.label_delimiters = {open = "[", close = "]"}
NLink.url_delimiters = {open = "(", close = ")"}

function NLink:_init(args)
    Dict.update(self, args or {}, {
        before = '',
        label = '',
        url = '',
        after = '',
    })
end

function NLink:regex()
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

function NLink:str_is_a(str)
    return str:match(self:regex())
end

function NLink:from_str(str)
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

function NLink:__tostring()
    return List({
        self.before,
        self.label_delimiters.open .. self.label .. self.label_delimiters.close,
        self.url_delimiters.open .. self.url .. self.url_delimiters.close,
        self.after,
    }):join("")
end

class.DefinitionLink(NLink)
DefinitionLink.url_delimiters = {
    open = "(" .. Config.get("link").delimiter,
    close = Config.get("link").delimiter .. ")",
}

return {
    Link = NLink,
    DefinitionLink = DefinitionLink,
}
