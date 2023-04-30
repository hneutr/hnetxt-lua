--[[
TODO:
- to_mark:
    - process: test
]]
local stub = require('luassert.stub')

local Operation = require("hnetxt-lua.project.move.operation")

local FileOperation = require("hnetxt-lua.project.move.operation.file")

describe("to_mark.map_mirrors", function()
    before_each(function()
        stub(Operation, 'map_mirrors')
    end)

    after_each(function()
        mock:revert(Operation)
    end)

    it("works", function()
        FileOperation.to_mark.map_mirrors({a = "b.md:z", c = "d.md"})
        assert.stub(Operation.map_mirrors).was_called_with({a = "b.md", c = "d.md"})
    end)
end)
