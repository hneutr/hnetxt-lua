local class = require("pl.class")

local Link = require("htl.text.NLink").Link

class.URLDefinition(Link)
URLDefinition.url_delimiters = {
    open = "(" .. URLDefinition.delimiter,
    close = URLDefinition.delimiter .. ")",
}

return URLDefinition
