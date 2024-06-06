require("htl")

local M = require("htl.Snippet")

describe("testing", function()
    local M = M.M
    it("works", function()
        print(M("book").definition)
        
    end)
    
end)
