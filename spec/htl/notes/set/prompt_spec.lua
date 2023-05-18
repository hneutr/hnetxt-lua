local PromptSet = require("htl.notes.set.prompt")

describe("format", function()
    local date = {default = os.date("%Y%m%d")}

    it("works", function()
        local actual = PromptSet.format()
        assert.are.same(
            {
                topics = {},
                statement = {fields = {open = {default = true}, date = date}, filters = {open = true}},
                file = {fields = {pinned = {default = false}, date = date}, filters = {}},
            },
            actual
        )
    end)
end)
