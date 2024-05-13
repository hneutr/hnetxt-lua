local Colorize = require("htc.Colorize")

local TerminalLink = class(require("htl.text.Link"))

function TerminalLink:_init(args)
    Dict.update(self, args or {}, {
        before = '',
        label = '',
        url = '',
        after = '',
        colors = Conf.link.colors
    })
end

function TerminalLink:__tostring()
    local parts = List({
        {
            text = self.label_delimiters.open,
            key = "label_delimiters",
        },
        {
            text = self.label,
            key = "label",
        },
        {
            text = self.label_delimiters.close,
            key = "label_delimiters",
        },
        {
            text = self.url_delimiters.open,
            key = "url_delimiters",
        },
        {
            text = self.url,
            key = "url",
        },
        {
            text = self.url_delimiters.close,
            key = "url_delimiters",
        },
    }):transform(function(part) return Colorize(part.text, self.colors[part.key]) end)

    parts:append("")
    return parts:join("")
end

return TerminalLink
