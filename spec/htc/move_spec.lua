local stub = require("luassert.stub")

local htl = require("htl")

local M = require("htc.move")

local d1 = htl.test_dir / "dir-1"
local d2 = htl.test_dir / "dir-2"
local d3 = d1 / "dir-3"
local d4 = d1 / "dir-4"
local d5 = d2 / "dir-3"

local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"
local f3 = d2 / "file-1.md"
local f4 = d2 / "file-2.md"

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930120"}
local p3 = {title = "test3", path = d3, created = "19930120"}

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
            string.format("%s %s %s", M.command_str, f1, f2), M.command(f1, f2)
        )
    end)
end)

describe("line_is_valid", function()
    it("+", function()
        assert(M.line_is_valid("a -> b"))
    end)

    it("-", function()
        assert.is_falsy(M.line_is_valid("usage: mv [-f | -i | -n] [-hv] source target"))
    end)
end)

describe("parse_line", function()
    it("+", function()
        assert.are.same(
            {source = Path("a"), target = Path("b")},
            M.parse_line("a -> b")
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
            M:handle_dir_move(move)
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
            M:handle_dir_move({source = d1, target = d2}):sorted(function(a, b)
                return tostring(a.source) < tostring(b.source)
            end)
        )
    end)
end)

describe("end to end project move", function()
    it("works", function()
        DB.projects:drop()
        
        local root = htl.test_dir / "root"
        local dir_a = root / "a"
        local dir_ab = dir_a / "b"
        local dir_b = root / "b"
        
        local file_a = dir_a / "a.md"
        local file_ab = dir_ab / "b.md"
        local file_b = dir_b / "b.md"
        
        local p_a = {title = "project a", path = dir_a}
        local p_ab = {title = "project b", path = dir_ab}
        local p_b = {title = "project b", path = dir_b}

        DB.projects:insert(p_a)
        DB.projects:insert(p_ab)
        
        file_a:touch()
        file_ab:touch()
        
        local u_a = DB.urls:insert({path = file_a})
        local u_b = DB.urls:insert({path = file_ab})
        
        M.run({source = dir_ab, target = dir_b})
        
        assert.is_false(dir_ab:exists())
        assert(dir_b:exists())

        assert(DB.projects:where(p_a))
        assert(DB.projects:where(p_b))
        assert.is_nil(DB.projects:where(p_ab))
        
        assert.are.same(file_a, DB.urls:where({id = u_a}).path)
        assert.are.same(file_b, DB.urls:where({id = u_b}).path)
    end)
end)
