local stub = require('luassert.stub')

local Fields = require("htl.notes.field")
local Sets = require("htl.notes.set")
local DateField = require("htl.notes.field.date")

describe("format", function()
    it("basics", function()
        local fields = {a = 1}
        local filters = {x = true}
        local actual = Sets.format({subsets = {"a", "b"}, fields = fields, filters = filters})
        assert.are.same(
            {
                subsets = {
                    a = {fields = fields, filters = filters},
                    b = {fields = fields, filters = filters},
                },
                fields = fields,
                filters = filters,
            },
            actual
        )
    end)

    it("complex", function()
        local actual = Sets.format({
            subsets = {
                a = {
                    type = 'topic',
                    fields = {x = {i = "j"}, y = 2},
                    filters = {ff = true},
                    subsets = {"b"},
                },
                c = {subsets = {"d"}},
            },
            fields = {x = {i = "k", j = "l"}, q = "a"},
            filters = {ff = false},
        })
        assert.are.same(
            {
                subsets = {
                    a = {
                        type = 'topic',
                        fields = {x = {i = "j", j = "l"}, q = "a", y = 2},
                        filters = {ff = true},
                        subsets = {
                            b = {
                                fields = {x = {i = "j", j = "l"}, y = 2, q = "a"},
                                filters = {ff = true},
                            },
                        },
                    },
                    c = {
                        filters = {ff = false},
                        fields = {x = {i = "k", j = "l"}, q = "a"},
                        subsets = {
                            d = {
                                filters = {ff = false},
                                fields = {x = {i = "k", j = "l"}, q = "a"},
                            },
                        },
                    },
                },
                filters = {ff = false},
                fields = {x = {i = "k", j = "l"}, q = "a"},
            },
            actual
        )
    end)
end)

describe("format_subsets", function()
    it("listed subsets", function()
        local fields = {a = 1}
        assert.are.same(
            {subsets = {a = {}, b = {}}, fields = fields},
            Sets.format_subsets({"a", "b", fields = fields})
        )
    end)

    it("keyed subsets", function()
        local fields = {a = 1}
        local filters = {x = true}
        local actual = 
        assert.are.same(
            {subsets = {a = {}, b = {}}, fields = fields, filters = filters},
            Sets.format_subsets({a = {}, b = {}, fields = fields, filters = filters})
        )
    end)
end)

describe("flatten", function()
    it("works", function()
        local actual = Sets.flatten({
            a = {
                type = 'topic',
                fields = {1},
                subsets = {b = {fields = {2}}},
            },
            c = {
                fields = {3},
                subsets = {d = {fields = {4}}},
            },
        })

        local expected = {
            a = {type = 'topic', fields = {1}},
            ["a/b"] = {fields = {2}},
            c = {fields = {3}},
            ["c/d"] = {fields = {4}}
        }

        assert.are.same(expected, actual)
    end)
end)

describe("format_config", function()
    it("basics", function()
        assert.are.same(
            {
                a = {
                    fields = {
                        date = {default = DateField.default},
                    },
                    filters = {},
                },
            },
            Sets.format_config({subsets = {"a"}})
        )
    end)

    it("no top level subsets key", function()
        local a_fields = {x = 1}
        local b_fields = {y = 2}
        local actual = Sets.format_config({a = {fields = a_fields}, b = {fields = b_fields}})
        assert.are.same(
            {a = {fields = a_fields, filters = {}}, b = {fields = b_fields, filters = {}}},
            actual
        )
    end)
end)
