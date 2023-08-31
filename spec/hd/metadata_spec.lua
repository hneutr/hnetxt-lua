local Metadata = require("hd.metadata")

describe("get_path", function()
    it("no project", function()
        print(require("inspect")(Metadata()))
        print(tostring(Metadata()))
        -- assert.are.same(
        --     false,
        --     true
        -- )
    end)
end)
