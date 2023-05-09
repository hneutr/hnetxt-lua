local stub = require('luassert.stub')

table = require('hl.table')
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Project = require("htl.project")
local Registry = require("htl.project.registry")

local EntryConfigModule = require("htl.entry.config")
local EntryConfig = EntryConfigModule.EntryConfig
local PromptEntryConfig = EntryConfigModule.PromptEntryConfig
local ResponseEntryConfig = EntryConfigModule.ResponseEntryConfig
local Config = EntryConfigModule.Config

local test_data_dir = Path.joinpath(Path.tempdir(), "test-data-dir")
local test_project_dir = Path.joinpath(Path.tempdir(), 'test-project-dir')
local test_project_config_path = Path.joinpath(test_project_dir, ".project")
local test_project_name = "test project"
local registry

-- function create_project(metadata)
--     Project.create(test_project_name, test_project_dir, metadata)
-- end

before_each(function()
    Path.rmdir(test_data_dir, true)
    Registry.config = require("htl.config").get("project")
    Registry.config.data_dir = test_data_dir
    registry = Registry()

    Path.rmdir(test_project_dir, true)
end)

after_each(function()
    Path.rmdir(test_data_dir, true)
    Path.rmdir(test_project_dir, true)
end)

describe("EntryConfig", function()
    describe("move_entry_into_dir", function()
        it("relative", function()
            assert.are.same('a/b', EntryConfig.move_entry_into_dir('a/b', 'a'))

        end)

        it("not relative", function()
            assert.are.same('a/b', EntryConfig.move_entry_into_dir('b', 'a'))
        end)
    end)

    describe("move_into_dir", function()
        it("works", function()
            local entry = EntryConfig("b")
            entry:move_into_dir("a")
            assert.are.same("a/b", entry.name)
        end)
    end)
end)

describe("PromptEntryConfig", function()
    local fields = {pinned = false, date = {type = "date"}}
    local entries = {}
    describe("new", function()
        it("no response_dir, no response_entry", function()
            assert.are.same(
                {["a/responses"] = {type = 'response', prompt_dir = 'a', fields = fields, entries = entries}},
                PromptEntryConfig("a", {type = 'question'}).config.entries
            )
        end)

        it("response_dir, no response_entry", function()
            assert.are.same(
                {["b"] = {type = 'response', prompt_dir = 'a', fields = fields, entries = entries}},
                PromptEntryConfig("a", {type = 'question', response_dir = 'b', response_entry = ''}).config.entries
            )
        end)

        it("response_dir, response_entry", function()
            assert.are.same(
                {["b/c"] = {type = 'response', prompt_dir = 'a', fields = fields, entries = entries}},
                PromptEntryConfig("a", {type = 'question', response_dir = 'b', response_entry = 'c'}).config.entries
            )
        end)

        it("no response_dir, response_entry", function()
            assert.are.same(
                {["a/b"] = {type = 'response', prompt_dir = 'a', fields = fields, entries = entries}},
                PromptEntryConfig("a", {type = 'question', response_entry = 'b'}).config.entries
            )
        end)
    end)

    describe("move_into_dir", function()
        it("works", function()
            local entry = PromptEntryConfig("b", {response_dir = 'c'})
            entry:move_into_dir("a")
            assert.are.same("a/b", entry.name)
            assert.are.same("a/c/responses", entry.response_dir)
        end)
    end)

end)

describe("ResponseEntryConfig", function()
    describe("move_into_dir", function()
        it("works", function()
            local entry = ResponseEntryConfig("b", {prompt_dir = 'c'})
            entry:move_into_dir("a")
            assert.are.same("a/b", entry.name)
            assert.are.same("a/c", entry.prompt_dir)
        end)
    end)
end)

describe("Config", function()
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

    describe("add_entries", function()
        local date = {type = "date"}

        it("one entry", function()
            local config = {type = 'entry', entries = {}}
            local fields = {}
            assert.are.same(
                {a = {type = 'entry', fields = {date = date}}},
                Config.thin_entries(Config.add_entries("a", config, fields))
            )
        end)

        it("with subentry", function()
            local b = {type = 'entry', entries = {}}
            local a = {type = 'entry', entries = {b = b}}
            local fields = {}
            assert.are.same(
                {
                    a = {type = 'entry', fields = {date = date}},
                    ["a/b"] = {type = 'entry', fields = {date = date}},
                },
                Config.thin_entries(Config.add_entries("a", a, fields))
            )
        end)

        it("with fields", function()
            local b = {type = 'entry', entries = {}}
            local a = {type = 'entry', entries = {b = b}, fields = {test1 = true}}
            local fields = {test2 = false}
            local out_fields = {
                date = date,
                test1 = {type = 'bool', default = true},
                test2 = {type = 'bool', default = false},
            }
            assert.are.same(
                {
                    a = {type = 'entry', fields = out_fields},
                    ["a/b"] = {type = 'entry', fields = out_fields},
                },
                Config.thin_entries(Config.add_entries("a", a, fields))
            )
        end)
    end)

    describe("get_project_entries", function()
        it("works", function()
            local topics = {"1, 2, 3"}
            local questions = {type = "prompt", response_entry = "answers"}
            local unknown = {type = 'list', fields = {"author", "work"}}
            local prompts = {type = "prompt", response_dir = "../reflections"}

            local project_config = {
                fields = {topic = topics},
                entries = {
                    words = {
                        entries = {"cool", unknown = unknown},
                    },
                    reflections = {
                        fields = {'topic'},
                        entries = {prompts = prompts},
                    },
                    questions = questions,
                },
            }

            local expected = {
                words = {
                    type = "entry",
                    fields = {
                        date = {type = 'date'},
                        topic = {type = "field", values = topics},
                    },
                },
                ["words/cool"] = {
                    type = "entry",
                    fields = {
                        date = {type = 'date'},
                        topic = {type = "field", values = topics},
                    },
                },
                ["words/unknown"] = {
                    type = "list",
                    fields = {
                        date = {type = 'date'},
                        topic = {type = "field", values = topics},
                        author = {type = "field"},
                        work = {type = "field"},
                    },
                },
                reflections = {
                    type = "entry",
                    fields = {
                        date = {type = 'date'},
                        topic = {type = "field"},
                    },
                },
                ["reflections/prompts"] = {
                    type = "prompt",
                    response_dir = "reflections/responses",
                    fields = {
                        date = {type = 'date'},
                        topic = {type = "field"},
                        open = {type = "bool", default = true},
                    },
                },
                ["reflections/responses"] = {
                    type = "response",
                    prompt_dir = "reflections/prompts",
                    fields = {
                        date = {type = 'date'},
                        pinned = {type = "bool", default = false},
                    },
                },
                questions = {
                    type = "prompt",
                    response_dir = "questions/answers",
                    fields = {
                        date = {type = 'date'},
                        topic = {type = "field", values = topics},
                        open = {type = "bool", default = true},
                    },
                },
                ["questions/answers"] = {
                    type = "response",
                    prompt_dir = "questions",
                    fields = {
                        date = {type = 'date'},
                        pinned = {type = "bool", default = false},
                    },
                }
            }
            assert.are.same(expected, Config.get_project_entries(project_config))
        end)
    end)
end)
