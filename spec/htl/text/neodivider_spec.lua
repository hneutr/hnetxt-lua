local Divider = require("htl.text.neodivider")

-- print(Divider("small"))
-- print(Divider("medium"))
-- print(Divider("large"))

-- local dividers = {
--     small = "=---------------------------------------",
--     medium = "=-----------------------------------------------------------",
--     large = "=-------------------------------------------------------------------------------",
-- }

-- describe("__tostring", function()
--     it("small", function()
--         assert.equal(dividers.small, tostring(Divider("small")))
--     end)

--     it("medium", function()
--         assert.equal(dividers.medium, tostring(Divider("medium")))
--     end)

--     it("large", function()
--         assert.equal(dividers.large, tostring(Divider("large")))
--     end)
-- end)

-- describe("line_is_a", function()
--     it("+", function()
--         assert(Divider():line_is_a(1, {dividers.small}))
--     end)

--     it("-: wrong divider", function()
--         assert.falsy(Divider():line_is_a(1, {dividers.large}))
--     end)

--     it("-: not a divider", function()
--         assert.falsy(Divider():line_is_a(1, {"text"}))
--     end)
-- end)

-- describe("parse_levels", function()
--     it("works", function()
--         local lines = {
--             "a",
--             "=-------------------------------------------------------------------------------",
--             "[b]()",
--             "=-------------------------------------------------------------------------------",
--             "c",
--             "=-----------------------------------------------------------",
--             "d",
--             "=---------------------------------------",
--             "e",
--             "=-----------------------------------------------------------",
--             "f",
--             "=---------------------------------------",
--             "g",
--             "=-------------------------------------------------------------------------------",
--             "h"
--         }

--         assert.are.same(
--             {0, 0, 0, 0, 0, 1, 1, 2, 2, 1, 1, 2, 2, 0, 0},
--             Divider.parse_levels(lines)
--         )
--     end)
-- end)

-- describe("parse_divisions", function()
--     it("works", function()
--         local lines = {
--             "a",
--             "=-------------------------------------------------------------------------------",
--             "b",
--             "c",
--             "=-------------------------------------------------------------------------------",
--             "=-----------------------------------------------------------",
--             "=---------------------------------------",
--             "d",
--             "e",
--             "=-------------------------------------------------------------------------------",
--         }

--         assert.are.same(
--             {{1}, {3, 4}, {8, 9}},
--             Divider.parse_divisions(lines)
--         )
--     end)
-- end)

