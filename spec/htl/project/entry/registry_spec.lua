local Registry = require("htl.project.entry.registry")

describe("format_all_config_entries", function()
    it("normal", function()
        assert.are.same(
            {
                entries = {
                    a = {
                        type = 'entry',
                        fields = {1, 2, 3},
                        entries = {},
                    },
                    b = {
                        type = 'entry',
                        entries = {
                            c = {
                                type = 'entry',
                                entries = {},
                            },
                            d = {
                                type = 'entry',
                                entries = {},
                            },
                        }
                    },
                },
            },
            Config.format_all_config_entries({entries = {
                a = {fields = {1, 2, 3}},
                b = {entries = {"c", "d"}},
            }})
        )
    end)

    it("list shorthand", function()
        assert.are.same(
            {
                entries = {
                    a = {type = 'entry', entries = {}},
                    b = {type = 'entry', entries = {}},
                }
            },
            Config.format_all_config_entries({entries = {"a", "b"}})
        )
    end)
end)

-- describe("add_entries", function()
--     local date = {type = "date"}

--     it("one entry", function()
--         local config = {type = 'entry', entries = {}}
--         local fields = {}
--         assert.are.same(
--             {a = {type = 'entry', fields = {date = date}}},
--             Config.thin_entries(Config.add_entries("a", config, fields))
--         )
--     end)

--     it("with subentry", function()
--         local b = {type = 'entry', entries = {}}
--         local a = {type = 'entry', entries = {b = b}}
--         local fields = {}
--         assert.are.same(
--             {
--                 a = {type = 'entry', fields = {date = date}},
--                 ["a/b"] = {type = 'entry', fields = {date = date}},
--             },
--             Config.thin_entries(Config.add_entries("a", a, fields))
--         )
--     end)

--     it("with fields", function()
--         local b = {type = 'entry', entries = {}}
--         local a = {type = 'entry', entries = {b = b}, fields = {test1 = true}}
--         local fields = {test2 = false}
--         local out_fields = {
--             date = date,
--             test1 = {type = 'bool', default = true},
--             test2 = {type = 'bool', default = false},
--         }
--         assert.are.same(
--             {
--                 a = {type = 'entry', fields = out_fields},
--                 ["a/b"] = {type = 'entry', fields = out_fields},
--             },
--             Config.thin_entries(Config.add_entries("a", a, fields))
--         )
--     end)
-- end)

-- describe("get_project_entries", function()
--     it("works", function()
--         local topics = {"1, 2, 3"}
--         local questions = {type = "prompt", response_entry = "answers"}
--         local unknown = {type = 'list', fields = {"author", "work"}}
--         local prompts = {type = "prompt", response_dir = "../reflections"}

--         local project_config = {
--             fields = {topic = topics},
--             entries = {
--                 words = {
--                     entries = {"cool", unknown = unknown},
--                 },
--                 reflections = {
--                     fields = {'topic'},
--                     entries = {prompts = prompts},
--                 },
--                 questions = questions,
--             },
--         }

--         local expected = {
--             words = {
--                 type = "entry",
--                 fields = {
--                     date = {type = 'date'},
--                     topic = {type = "field", values = topics},
--                 },
--             },
--             ["words/cool"] = {
--                 type = "entry",
--                 fields = {
--                     date = {type = 'date'},
--                     topic = {type = "field", values = topics},
--                 },
--             },
--             ["words/unknown"] = {
--                 type = "list",
--                 fields = {
--                     date = {type = 'date'},
--                     topic = {type = "field", values = topics},
--                     author = {type = "field"},
--                     work = {type = "field"},
--                 },
--             },
--             reflections = {
--                 type = "entry",
--                 fields = {
--                     date = {type = 'date'},
--                     topic = {type = "field"},
--                 },
--             },
--             ["reflections/prompts"] = {
--                 type = "prompt",
--                 response_dir = "reflections/responses",
--                 fields = {
--                     date = {type = 'date'},
--                     topic = {type = "field"},
--                     open = {type = "bool", default = true},
--                 },
--             },
--             ["reflections/responses"] = {
--                 type = "response",
--                 prompt_dir = "reflections/prompts",
--                 fields = {
--                     date = {type = 'date'},
--                     pinned = {type = "bool", default = false},
--                 },
--             },
--             questions = {
--                 type = "prompt",
--                 response_dir = "questions/answers",
--                 fields = {
--                     date = {type = 'date'},
--                     topic = {type = "field", values = topics},
--                     open = {type = "bool", default = true},
--                 },
--             },
--             ["questions/answers"] = {
--                 type = "response",
--                 prompt_dir = "questions",
--                 fields = {
--                     date = {type = 'date'},
--                     pinned = {type = "bool", default = false},
--                 },
--             }
--         }
--         assert.are.same(expected, Config.get_project_entries(project_config))
--     end)
-- end)
