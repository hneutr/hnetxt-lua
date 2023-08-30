local stub = require('luassert.stub')
local Path = require("hl.path")
local yaml = require("hl.yaml")

local uuid = require("htl.uuid")

describe("get_path", function()
    it("no project", function()
        print(require("inspect")(uuid.uuid()))
        assert.are.same(
            false,
            true
        )
    end)
end)
