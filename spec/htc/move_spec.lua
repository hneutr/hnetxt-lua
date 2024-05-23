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
            string.format("%s %s %s", M.command_str, f1, f2), M:command(f1, f2)
        )
    end)
end)

describe("line_is_valid", function()
    it("+", function()
        assert(M:line_is_valid("a -> b"))
    end)

    it("-", function()
        assert.is_falsy(M:line_is_valid("usage: mv [-f | -i | -n] [-hv] source target"))
    end)
end)

describe("parse_line", function()
    it("+", function()
        assert.are.same(
            {source = Path("a"), target = Path("b")},
            M:parse_line("a -> b")
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

describe("update_projects", function()
    it("dir is a project", function()
        DB.projects:insert(p3)
        
        assert(DB.projects:where({path = d3}))
        M:update_projects({source = d3, target = d4})

        assert.is_nil(DB.projects:where({path = d3}))
        assert(DB.projects:where({path = d4}))
    end)
    
    it("dir with multiple projects", function()
        DB.projects:drop()

        DB.projects:insert(p1)
        DB.projects:insert(p3)
        
        assert(DB.projects:where({path = d1}))
        assert(DB.projects:where({path = d3}))

        M:update_projects({source = d1, target = d2})

        assert.is_nil(DB.projects:where({path = d1}))
        assert.is_nil(DB.projects:where({path = d3}))

        assert(DB.projects:where({path = d2}))
        assert(DB.projects:where({path = d5}))
    end)
end)

describe("update", function()
    it("works", function()
        DB.urls:insert({path = f1, label = "a"})
        
        M:update(List({
            {source = f1, target = f3}
        }))

        assert.is_nil(DB.urls:where({path = f1}))
        assert.are.same("a", DB.urls:where({path = f3}).label)
    end)
end)
