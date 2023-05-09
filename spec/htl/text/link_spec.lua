local Link = require("htl.text.Link")

describe("__tostring", function() 
    it("works", function()
        local one = Link({label = 'a', location = 'b'})
        local two = Link({label = 'c', location = 'd'})
        assert.equals("[a](b)", tostring(one))
        assert.equals("[c](d)", tostring(two))
    end)
end)

describe("from_str", function() 
    it("plain", function()
        local actual = Link.from_str("[a](b)")
        local expected = Link{ label = 'a', location = 'b', before = '', after = '' }
        assert.are.same(actual, expected)
    end)

    it("empty", function()
        local actual = Link.from_str("[]()")
        local expected = Link{ label = '', location = '', before = '', after = '' }
        assert.are.same(actual, expected)
    end)

    it("+ before and after", function()
        local actual = Link.from_str("before [a](b) after")
        local expected = Link{ label = 'a', location = 'b', before = 'before ', after = ' after' }

        assert.are.same(actual, expected)
    end)

    it("another link after", function()
        local actual = Link.from_str("before [a](b) [c](d)")
        local expected = Link{ label = 'a', location = 'b', before = 'before ', after = ' [c](d)' }

        assert.are.same(actual, expected)
    end)
end)

describe("str_is_a", function() 
    it("negative case", function()
        assert.is_false(Link.str_is_a("not a link"))
    end)
end)

describe("get_nearest", function()
    it("1 link: cursor in link", function()
        local line = "a [b](c) d"
        local position = line:find("a")
        local expected = "[b](c)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("1 link: cursor before link", function()
        local line = "a [b](c) d"
        local position = line:find("a")
        local expected = "[b](c)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("1 link: cursor after link", function()
        local line = "a [b](c) d"
        local position = line:find("d")
        local expected = "[b](c)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("2 links: cursor before link 1", function()
        local line = "a [b](c) d [e](f) g"
        local position = line:find("a")
        local expected = "[b](c)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("2 links: cursor in link 1", function()
        local line = "a [b](c) d [e](f) g"
        local position = line:find("b")
        local expected = "[b](c)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("2 links: cursor in between links", function()
        local line = "a [b](c) d [e](f) g"
        local position = line:find("d")
        local expected = "[b](c)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("2 links: cursor in link 2", function()
        local line = "a [b](c) d [e](f) g"
        local position = line:find("e")
        local expected = "[e](f)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("2 links: cursor in after link 2", function()
        local line = "a [b](c) d [e](f) g"
        local position = line:find("g")
        local expected = "[e](f)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)

    it("3 links: cursor between link 2 and 3", function()
        local line = "a [b](c) d [e](f) g [h](i) j"
        local position = line:find("g")
        local expected = "[e](f)"
        assert.equal(expected, tostring(Link.get_nearest(line, position)))
    end)
end)
