local Entry = require("htl.project.entry")

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

-- describe("EntrySet", function()
--     describe("find_items", function()
--         it("works", function()
--             local expected = {test_entry_1, test_entry_2}
--             table.sort(expected)

--             assert.are.same(
--                 expected,
--                 set_config.entry_sets["standard_entries"].items
--             )
--         end)
--     end)

--     describe("set_metadata", function()
--         it("works", function()
--             local metadata_before = {a = 1, b = 2}
--             local content = {"x", "y", "z"}

--             Yaml.write_document(test_entry_1, metadata_before, content)
--             set_config.entry_sets['standard_entries']:set_metadata(test_entry_1, {b = 3, c = 4})

--             local metadata_actual, content_after = unpack(Yaml.read_document(test_entry_1))
--             assert.are.same({a = 1, b = 3, c = 4}, metadata_actual)
--             assert.are.same(content, content_after:splitlines())
--         end)
--     end)

--     describe("new_entry", function()
--         it("works", function()
--             set_config.entry_sets['standard_entries']:new_entry(test_entry_1)

--             assert.are.same(
--                 {date = os.date("%Y%m%d")},
--                 set_config.entry_sets['standard_entries']:get_metadata(test_entry_1)
--             )
--         end)
--     end)
-- end)
