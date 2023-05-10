local Path = require("hl.path")
local PromptEntry = require("htl.project.notes.entry.prompt")

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
            PromptEntry(key, {response_key = "a"}, {a = "b"}, test_project_root):response_entry_set()
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

-- describe("respond", function()
--     it("works", function()
--         local path = set_config.entry_sets['prompts']:respond(test_prompt_1)
--         assert.are.same(test_response_1_2, path)
--         assert.are.same(
--             {date = os.date("%Y%m%d"), pinned = false},
--             set_config.entry_sets['prompts/responses']:get_metadata(path)
--         )
--     end)
-- end)
