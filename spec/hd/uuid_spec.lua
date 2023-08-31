local uuid = require("htl.uuid")

describe("get_path", function()
    it("no project", function()
        print(require("inspect")(uuid()))
        assert.are.same(
            false,
            true
        )
    end)
end)
