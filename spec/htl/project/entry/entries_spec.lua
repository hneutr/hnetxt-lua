local stub = require('luassert.stub')

local Fields = require("htl.project.entry.fields")
local Entries = require("htl.project.entry.entries")

local fields_format

before_each(function()
    fields_format = Fields.format
    Fields.format = function(args) return args end
end)

after_each(function()
    Fields.format = fields_format
end)


describe("format", function()
    it("basics", function()
        local fields = {a = 1}
        local actual = Entries.format({entries = {"a", "b"}, fields = fields})
        assert.are.same(
            {entries = {a = {fields = fields}, b = {fields = fields}}, fields = fields},
            actual
        )
    end)

    it("complex", function()
        local actual = Entries.format({
            entries = {
                a = {
                    type = 'list',
                    fields = {x = {i = "j"}, y = 2},
                    entries = {"b"},
                },
                c = {entries = {"d"}},
            },
            fields = {x = {i = "k", j = "l"}, q = "a"},
        })
        assert.are.same(
            {
                entries = {
                    a = {
                        type = 'list',
                        fields = {x = {i = "j", j = "l"}, q = "a", y = 2},
                        entries = {
                            b = {
                                fields = {x = {i = "j", j = "l"}, y = 2, q = "a"},
                            },
                        },
                    },
                    c = {
                        fields = {x = {i = "k", j = "l"}, q = "a"},
                        entries = {
                            d = {
                                fields = {x = {i = "k", j = "l"}, q = "a"},
                            },
                        },
                    },
                },
                fields = {x = {i = "k", j = "l"}, q = "a"},
            },
            actual
        )
    end)
end)
