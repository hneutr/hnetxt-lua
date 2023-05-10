local Path = require("hl.path")
local Fields = require("htl.project.notes.fields")
local PromptEntry = require("htl.project.notes.entry.prompt")
local ResponseEntry = require("htl.project.notes.entry.response")

local key = "prompts"
local response_key = Path.joinpath(key, "responses")

local test_project_root = Path.joinpath(Path.tempdir(), "test-project-root")

local test_prompt_dir = Path.joinpath(test_project_root, key)
local test_prompt = Path.joinpath(test_prompt_dir, 'p1.md')

local test_response_dir = Path.joinpath(test_project_root, response_key)
local test_response = Path.joinpath(test_response_dir, 'p1', os.date("%Y%m%d") .. ".md")

before_each(function()
    Path.rmdir(test_project_root, true)
end)

after_each(function()
    Path.rmdir(test_project_root, true)
end)

describe("get_response_key", function()
    it("nothing", function()
        assert.are.same('a/responses', PromptEntry.get_response_key('a'))
    end)

    it("key", function()
        assert.are.same('a/answers', PromptEntry.get_response_key('a', "answers"))
    end)

    it("..", function()
        assert.are.same('a/responses', PromptEntry.get_response_key('a/b', ".."))
    end)

    it("../key", function()
        assert.are.same('a/answers', PromptEntry.get_response_key('a/b', "../answers"))
    end)

    it("../..", function()
        assert.are.same('a/responses', PromptEntry.get_response_key('a/b/c', "../.."))
    end)

    it("../../key", function()
        assert.are.same('a/answers', PromptEntry.get_response_key('a/b/c', "../../answers"))
    end)

    it("../.. but prompt key is too short", function()
        assert.are.same('responses', PromptEntry.get_response_key('a', "../.."))
    end)
end)

describe("format", function()
    it("works", function()
        local entries = {
            a = {type = 'list'},
            b = {type = 'prompt', response_key = 'answers'},
        }

        PromptEntry.format(entries, 'b', entries.b)
        assert.are.same(
            {
                a = {type = 'list'},
                b = {
                    type = 'prompt',
                    response_key = 'b/answers',
                    fields = {open = true}
                },
                ['b/answers'] = {
                    type = 'response',
                    fields = {pinned = false},
                    prompt_key = 'b',
                },
            },
            entries
        )
    end)
end)

describe("response_entry_set", function()
    it("works", function()
        assert.are.same(
            "b",
            PromptEntry(key, {response_key = "a"}, {a = "b"}, test_project_root).response_entry_set
        )
    end)
end)

describe("respond", function()
    it("works", function()
        local response_config = ResponseEntry.get_entry(prompt_key)
        response_config.fields = Fields.format(response_config.fields)
        local response = ResponseEntry(response_key, response_config, {}, test_project_root)
        local prompt = PromptEntry(key, {response_key = response_key}, {[response_key] = response}, test_project_root)

        assert.are.same(test_response, prompt:respond(test_prompt))
        assert.are.same(
            {date = os.date("%Y%m%d"), pinned = false},
            response:get_metadata(test_response)
        )
    end)
end)
-- describe("responses", function()
--     it("works", function()
--         local input_to_expected = {
--             [test_prompt_1] = {test_response_1_1, test_response_1_2},
--             [test_prompt_2] = {test_response_2_1, test_response_2_2},
--         }
--         for input, expected in pairs(input_to_expected) do
--             local actual = set_config.entry_sets["prompts"]:responses(input)
--             table.sort(actual)
--             table.sort(expected)
--             assert.are.same(expected, actual)
--         end
--     end)
-- end)

-- describe("response", function()
--     it("all", function()
--         Yaml.write_document(test_response_1_1, {a = 1}, {"b"})
--         Yaml.write_document(test_response_1_2, {pinned = true}, {"c"})

--         local expected = {test_response_1_1, test_response_1_2}
--         local actual = set_config.entry_sets['prompts']:response(test_prompt_1, true)
--         table.sort(expected)
--         table.sort(actual)
                            
--         assert.are.same(expected, actual)
--     end)

--     it("!all", function()
--         Yaml.write_document(test_response_1_1, {a = 1}, {"b"})
--         Yaml.write_document(test_response_1_2, {pinned = true}, {"c"})

--         assert.are.same({test_response_1_2}, set_config.entry_sets['prompts']:response(test_prompt_1))
--     end)
-- end)
