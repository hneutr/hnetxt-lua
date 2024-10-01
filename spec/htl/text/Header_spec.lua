require("htl")

local M = require("htl.text.Header")

describe("exclude_from_document", function()
    it("excludes", function()
        assert(M("{x}", 1):exclude_from_document())
    end)
    
    it("includes", function()
        assert.is_false(M("x", 1):exclude_from_document())
    end)
end)
