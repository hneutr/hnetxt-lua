local stub = require('luassert.stub')
local mock = require("luassert.mock")

local Parser = require("hneutil.parse")
local Fold = require("hnetxt-lua.parse.fold")
local List = require("hnetxt-lua.text.list")

-- before_each(function()
--     stub(List.Parser, "new")
    
--     List.Parser.new.returns({})
-- end)

-- after_each(function()
--     mock.revert(Fold)
--     mock.revert(List.Parser)
-- end)

-- describe("parse", function()
--     local parser = Parser()
--     before_each(function()
--         stub(Fold, "get_line_levels")
--     end)

--     it("assigns groups", function()
--         Fold.get_line_levels.returns({0, 1, 2, 2, 1, 3, 3})
--         assert.are.same(
--             {
--                 0 = {{1, 2, 3, 4, 5, 6, 7}},
--                 1 = {{2, 3, 4}, {5, 6, 7}},
--                 2 = {{3, 4}},
--                 3 = {{6, 7}},
--             },
--             parser:parse()
--         )
--     end)
-- end)
