local stub = require('luassert.stub')
table = require("hl.table")
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Project = require("htl.project")
local Registry = require("htl.project.registry")

local m = require("htl.entry")
local SetConfig = m.SetConfig
local EntrySet = m.EntrySet

local test_data_dir = Path.joinpath(Path.tempdir(), "test-data-dir")
local test_project_dir = Path.joinpath(Path.tempdir(), 'test-project-dir')
local test_project_config_path = Path.joinpath(test_project_dir, ".project")
local test_project_name = "test project"

local test_entry_dir = Path.joinpath(test_project_dir, "standard_entries")
local test_entry_1 = Path.joinpath(test_entry_dir, "entry-1.md")
local test_entry_2 = Path.joinpath(test_entry_dir, "entry-2.md")

local test_list_dir = Path.joinpath(test_project_dir, "list_entries")

local test_list_1_dir = Path.joinpath(test_list_dir, "list-1")
local test_list_1_1 = Path.joinpath(test_list_1_dir, "1.md")
local test_list_1_2 = Path.joinpath(test_list_1_dir, "2.md")

local test_list_2_dir = Path.joinpath(test_list_dir, "list-2")
local test_list_2_1 = Path.joinpath(test_list_2_dir, "1.md")
local test_list_2_2 = Path.joinpath(test_list_2_dir, "2.md")

local test_prompt_dir = Path.joinpath(test_project_dir, "prompts")
local test_prompt_1 = Path.joinpath(test_prompt_dir, "prompt-1.md")
local test_prompt_2 = Path.joinpath(test_prompt_dir, "prompt-2.md")

local test_response_dir = Path.joinpath(test_prompt_dir, "responses")
local test_response_1_dir = Path.joinpath(test_response_dir, "prompt-1")
local test_response_1_1 = Path.joinpath(test_response_1_dir, "20230101.md")
local test_response_1_2 = Path.joinpath(test_response_1_dir, os.date("%Y%m%d") .. ".md")

local test_response_2_dir = Path.joinpath(test_response_dir, "prompt-2")
local test_response_2_1 = Path.joinpath(test_response_2_dir, "20230201.md")
local test_response_2_2 = Path.joinpath(test_response_2_dir, os.date("%Y%m%d") .. ".md")

local all_entries = {
    test_entry_1,
    test_entry_2,
    test_list_1_1,
    test_list_1_2,
    test_list_2_1,
    test_list_2_2,
    test_prompt_1,
    test_prompt_2,
    test_response_1_1,
    test_response_1_2,
    test_response_2_1,
    test_response_2_2,
}

local test_project_metadata = {
    entries = {
        entries = {
            "standard_entries",
            list_entries = {type = 'list'},
            prompts = {type = "prompt"},
        }
    },
}

local registry
local project
local set_config

before_each(function()
    Path.rmdir(test_data_dir, true)
    Registry.config = require("htl.config").get("project")
    Registry.config.data_dir = test_data_dir
    registry = Registry()

    Path.rmdir(test_project_dir, true)
    Project.create(test_project_name, test_project_dir, test_project_metadata)

    for _, p in ipairs(all_entries) do
        Path.touch(p)
    end

    set_config = SetConfig(test_project_dir)
end)

after_each(function()
    Path.rmdir(test_data_dir, true)
    Path.rmdir(test_project_dir, true)
end)

describe("SetConfig", function()
    describe("new", function()
        it("works", function()
            local actual = table.keys(set_config.entry_sets)
            local expected = {"standard_entries", "list_entries", "prompts", "prompts/responses"}
            table.sort(actual)
            table.sort(expected)

            assert.are.same(expected, actual)
        end)
    end)
end)

describe("EntrySet", function()
    describe("find_items", function()
        it("works", function()
            local expected = {test_entry_1, test_entry_2}
            table.sort(expected)

            assert.are.same(
                expected,
                set_config.entry_sets["standard_entries"].items
            )
        end)
    end)

    describe("set_metadata", function()
        it("works", function()
            local metadata_before = {a = 1, b = 2}
            local content = {"x", "y", "z"}

            Yaml.write_document(test_entry_1, metadata_before, content)
            set_config.entry_sets['standard_entries']:set_metadata(test_entry_1, {b = 3, c = 4})

            local metadata_actual, content_after = unpack(Yaml.read_document(test_entry_1))
            assert.are.same({a = 1, b = 3, c = 4}, metadata_actual)
            assert.are.same(content, content_after:splitlines())
        end)
    end)

    describe("new_entry", function()
        it("works", function()
            set_config.entry_sets['standard_entries']:new_entry(test_entry_1)

            assert.are.same(
                {date = os.date("%Y%m%d")},
                set_config.entry_sets['standard_entries']:get_metadata(test_entry_1)
            )
        end)
    end)
end)

describe("PromptSet", function()
    describe("find_items", function()
        it("works", function()
            local expected = {test_prompt_1, test_prompt_2}
            table.sort(expected)

            assert.are.same(
                expected,
                set_config.entry_sets["prompts"].items
            )
        end)
    end)

    describe("response_sets", function()
        it("works", function()
            assert.are.same(
                set_config.entry_sets["prompts/responses"],
                set_config.entry_sets["prompts"]:response_sets()
            )
        end)
    end)

    describe("responses", function()
        it("works", function()
            local input_to_expected = {
                [test_prompt_1] = {test_response_1_1, test_response_1_2},
                [test_prompt_2] = {test_response_2_1, test_response_2_2},
            }
            for input, expected in pairs(input_to_expected) do
                local actual = set_config.entry_sets["prompts"]:responses(input)
                table.sort(actual)
                table.sort(expected)
                assert.are.same(expected, actual)
            end
        end)
    end)

    describe("response", function()
        it("all", function()
            Yaml.write_document(test_response_1_1, {a = 1}, {"b"})
            Yaml.write_document(test_response_1_2, {pinned = true}, {"c"})

            local expected = {test_response_1_1, test_response_1_2}
            local actual = set_config.entry_sets['prompts']:response(test_prompt_1, true)
            table.sort(expected)
            table.sort(actual)
                              
            assert.are.same(expected, actual)
        end)

        it("!all", function()
            Yaml.write_document(test_response_1_1, {a = 1}, {"b"})
            Yaml.write_document(test_response_1_2, {pinned = true}, {"c"})

            assert.are.same({test_response_1_2}, set_config.entry_sets['prompts']:response(test_prompt_1))
        end)
    end)

    describe("respond", function()
        it("works", function()
            local path = set_config.entry_sets['prompts']:respond(test_prompt_1)
            assert.are.same(test_response_1_2, path)
            assert.are.same(
                {date = os.date("%Y%m%d"), pinned = false},
                set_config.entry_sets['prompts/responses']:get_metadata(path)
            )
        end)
    end)
end)

describe("ResponseSet", function()
    describe("find_items", function()
        it("works", function()
            local expected = {test_response_1_1, test_response_1_2, test_response_2_1, test_response_2_2}
            table.sort(expected)

            assert.are.same(
                expected,
                set_config.entry_sets["prompts/responses"].items
            )
        end)
    end)

    describe("get_prompt_set", function()
        it("works", function()
            assert.are.same(
                set_config.entry_sets["prompts"],
                set_config.entry_sets["prompts/responses"]:get_prompt_set()
            )
        end)
    end)

    describe("path", function()
        it("works", function()

        end)

    end)
end)

describe("ListSet", function()
    describe("find_items", function()
        it("works", function()
            local expected = {test_list_1_1, test_list_1_2, test_list_2_1, test_list_2_2}
            table.sort(expected)

            assert.are.same(
                expected,
                set_config.entry_sets["list_entries"].items
            )
        end)
    end)
end)

-- describe("EntrySet")

-- describe("new", function()
--     it("works", function()
--         local metadata = {a = 1, b = 2}
--         local text = "test\ncontent"

--         Yaml.write_document(test_entry_path, metadata, text)

--         local entry = Entry(test_entry_path)
--         assert.are.same(test_entry_path, entry.path)
--         assert.are.same(metadata, entry.metadata)
--         assert.are.same(text, entry.text)
--     end)
-- end)
