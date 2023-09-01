local uuid = require("hd.uuid")

describe("get_path", function()
    it("no project", function()
        print(require("inspect")(uuid()))
        print(require("inspect")(uuid("extended")))
        -- assert.are.same(
        --     false,
        --     true
        -- )
    end)
end)
