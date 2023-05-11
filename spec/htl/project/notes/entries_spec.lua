local stub = require('luassert.stub')

local Fields = require("htl.project.notes.fields")
local Entries = require("htl.project.notes.entries")
local DateField = require("htl.project.notes.field.date")

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

describe("flatten", function()
    it("works", function()
        local actual = Entries.flatten({
            a = {
                type = 'list',
                fields = {1},
                entries = {b = {fields = {2}}},
            },
            c = {
                fields = {3},
                entries = {d = {fields = {4}}},
            },
        })

        local expected = {
            a = {type = 'list', fields = {1}},
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
                },
            },
            Entries.format_config({entries = {"a"}})
        )
    end)

    it("prompts", function()
        local actual = Entries.format_config({
            entries = {
                a = {type = 'prompt'},
                b = {type = 'prompt', response_key = "c"},
            },
        })

        assert.are.same(
            {
                a = {
                    type = 'prompt',
                    response_key = 'a/responses',
                    fields = {
                        date = {default = DateField.default},
                        open = {default = true},
                    },
                },
                ["a/responses"] = {
                    type = 'response',
                    prompt_key = 'a',
                    fields = {
                        date = {default = DateField.default},
                        pinned = {default = false},
                    },
                },
                b = {
                    type = 'prompt',
                    response_key = 'b/c',
                    fields = {
                        date = {default = DateField.default},
                        open = {default = true}
                    },
                },
                ["b/c"] = {
                    type = 'response',
                    prompt_key = 'b',
                    fields = {
                        date = {default = DateField.default},
                        pinned = {default = false},
                    },
                },
            },
            actual
        )
    end)
end)
