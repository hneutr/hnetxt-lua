local stub = require("luassert.stub")

local htl = require("htl")

local Move = require("htc.move")

local d1 = htl.test_dir / "dir-1"
local d2 = htl.test_dir / "dir-2"

local f1 = d1:join("file-1.md")
local f2 = d1:join("file-2.md")

local f3 = d2:join("file-1.md")
local f4 = d2:join("file-2.md")

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930120"}
local pwd = os.getenv("PWD")

before_each(function()
    htl.before_test()

    DB.projects:insert(p1)
    DB.projects:insert(p2)
    stub(os, "getenv")
    os.getenv.on_call_with("PWD").returns(tostring(d1))
end)

after_each(function()
    htl.after_test()
    os.getenv:revert()
end)

describe("command", function()
    it("works", function()
        assert.are.same(
            string.format("%s %s %s", Move.command_str, f1, f2), Move:command(f1, f2)
        )
    end)
end)

describe("line_is_valid", function()
    it("+", function()
        assert(Move:line_is_valid("a -> b"))
    end)

    it("-", function()
        assert.is_falsy(Move:line_is_valid("usage: mv [-f | -i | -n] [-hv] source target"))
    end)
end)

describe("parse_line", function()
    it("+", function()
        assert.are.same(
            {source = Path("a"), target = Path("b")},
            Move:parse_line("a -> b")
        )
    end)
end)

describe("handle_dir_move", function()
    it("file to file", function()
        f1:touch()
        f2:touch()
        local move = {source = f1, target = f2}
        assert.are.same(
            {move},
            Move:handle_dir_move(move)
        )
    end)

    it("dir to dir", function()
        d1:mkdir()
        f3:touch()
        f4:touch()

        assert.are.same(
            {
                {source = f1, target = f3},
                {source = f2, target = f4},
            },
            Move:handle_dir_move({source = d1, target = d2}):sorted(function(a, b)
                return tostring(a.source) < tostring(b.source)
            end)
        )
    end)
end)

describe("update", function()
    it("works", function()
        DB.urls:insert({path = f1, label = "a"})
        
        Move:update(List({
            {source = f1, target = f3}
        }))

        assert.is_nil(DB.urls:where({path = f1}))
        assert.are.same("a", DB.urls:where({path = f3}).label)
    end)
end)
