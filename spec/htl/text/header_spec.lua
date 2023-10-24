local Header = require("htl.text.header")

describe("str_is_upper", function()
    local s = Header({size = 'small'})
    local m = Header({size = 'medium'})

    it("+", function()
        assert(s:str_is_upper(s.line_templates.upper))
    end)

    it("-", function()
        assert.is_false(s:str_is_upper(s.line_templates.lower))
    end)

    it("-: length mismatch", function()
        assert.is_false(m:str_is_upper(s.line_templates.upper))
    end)
end)

describe("str_is_middle", function()
    local s = Header({size = 'small'})

    it("+: content", function()
        assert(s:str_is_middle("┃ x"))
    end)

    it("+: no content", function()
        assert(s:str_is_middle("┃ "))
    end)

    it("-: no space", function()
        assert.is_falsy(s:str_is_middle("┃hello"))
    end)
end)

describe("strs_are_a", function()
    it("+: no content", function()
        local s = Header({size = 'small'})
        assert(s:strs_are_a(unpack(s:get_lines())))
    end)

    it("+: content", function()
        local s = Header({size = 'small', content = "hello"})
        assert(s:strs_are_a(unpack(s:get_lines())))
    end)
end)
