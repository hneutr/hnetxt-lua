local htl = require("htl")
local Header = require("htl.text.header")

describe("str_is: upper", function()
    local s = Header({size = 'small'})
    local m = Header({size = 'medium'})

    it("+", function()
        assert(s:str_is_a(s.upper))
    end)

    it("-: length mismatch", function()
        assert.is_false(m:str_is_a(s.upper))
    end)
end)

describe("str_is_a: middle", function()
    local s = Header({size = 'small'})

    it("+: content", function()
        assert(s:str_is_a("┃ x"))
    end)

    it("+: no content", function()
        assert(s:str_is_a("┃ "))
    end)

    it("-: no space", function()
        assert.is_falsy(s:str_is_a("┃hello"))
    end)
end)
