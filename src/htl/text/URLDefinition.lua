local Link = require("htl.text.Link")

local URLDefinition = class(Link)

URLDefinition.url_delimiters = {
    open = "(" .. URLDefinition.delimiter,
    close = URLDefinition.delimiter .. ")",
}

return URLDefinition
