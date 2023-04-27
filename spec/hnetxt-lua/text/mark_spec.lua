local Path = require("hneutil.path")

local Mark = require("hnetxt-lua.text.mark")

describe("__tostring", function() 
    it("+", function()
        local one = Mark({label = 'a'})
        local two = Mark({label = 'b'})
        assert.equals("[a]()", tostring(one))
        assert.equals("[b]()", tostring(two))
    end)
end)

describe("from_str", function() 
    it("basic", function()
        assert.are.same(Mark({label = 'string'}), Mark.from_str("[string]()"))
    end)

    it("before and after", function()
        assert.are.same(
            Mark({label = 'string', before = '# ', after = ' after'}),
            Mark.from_str("# [string]() after")
        )
    end)
end)

describe("str_is_a", function() 
    it("+: accept", function()
        assert(Mark.str_is_a("[a]()"))
    end)

    it("-: non-link", function()
        assert.falsy(Mark.str_is_a("test"))
    end)

    it("-: has location", function()
        assert.falsy(Mark.str_is_a("[a](b)"))
    end)
end)

describe("find", function() 
    it("-: not present", function()
        assert.falsy(Mark.find("a", {}))
    end)

    it("+", function()
        assert.are.same(3, Mark.find("a", {"a", "", "[a]()"}))
    end)

    it("+: multiple marks and refs", function()
        assert.are.same(5, Mark.find("a", {"[a](b)", "c", "[d]()", "", "[a]()"}))
    end)
end)
