Path = require('hl.Path')

local file_path = "/tmp/test-file.txt"

local dir_path = "/tmp/test-dir"
local dir_file_path = "/tmp/test-dir/test-file.txt"

local M = Path

before_each(function()
    M(dir_path):rmdir(true)
    M(file_path):unlink()
end)

after_each(function()
    M(dir_path):rmdir(true)
    M(file_path):unlink()
end)

describe("init", function()
    it("works", function()
        assert.are.same("a", M("a").p)
    end)

    it("works", function()
        assert.are.same(M.home:join("a"), M("~/a"))
    end)
end)

describe("tempdir", function()
    it("works", function()
        assert.are.same(M("/tmp"), M.tempdir)
    end)
end)

describe("home", function()
    it("works", function()
        assert.are.same(M(os.getenv("HOME")), M.home)
    end)
end)

describe("currentdir", function()
    it("works", function()
        assert.are.same(M(os.getenv("PWD")), M.cwd())
    end)
end)

describe("exists", function()
    it("does", function()
        assert.is_true(M("/Users/hne/Desktop"):exists())
    end)

    it("doesn't", function()
        assert.is_false(M("steve"):exists())
    end)
end)

describe("unlink", function()
    local p = M(file_path)
    it("removes existing file", function()
        p:write("1")

        assert(p:exists())
        p:unlink()
        assert.is_false(p:exists())
    end)

    it("doesn't remove non-existing file", function()
        assert.is_false(p:exists())
        p:unlink()
        assert.is_false(p:exists())
    end)
end)

describe("concat", function()
    it("works", function()
        assert.are.same(M("a/b"), M("a") .. "b")
    end)
end)

describe("expanduser", function()
    it("expands at start", function()
        assert.are.same(tostring(M.home:join("a")), M("~/a"):expanduser())
    end)

    it("expands at start: non-object", function()
        assert.are.same(tostring(M.home:join("a")), M.expanduser("~/a"))
    end)

    it("doesn't expand anywhere else", function()
        assert.are.same(tostring(M("/a/~/b")), M("/a/~/b"):expanduser())
    end)
end)

describe("parts", function()
    it("single", function()
        assert.are.same({"a"}, M("a"):parts())
    end)

    it("with root", function()
        assert.are.same({"/", "a"}, M("/a"):parts())
    end)

    it("multiple", function()
        assert.are.same({"a", "b", "c"}, M("a/b/c"):parts())
    end)
end)

describe("parents", function()
    it("no parents", function()
        assert.are.same({}, M("a"):parents())
    end)

    it("has parents", function()
        assert.are.same({M("a/b/c"), M("a/b"), M("a")}, M("a/b/c/d"):parents())
    end)

    it("parents with root", function()
        assert.are.same({M("/a/b/c"), M("/a/b"), M("/a"), M("/")}, M("/a/b/c/d"):parents())
    end)
end)

describe("parent", function()
    it("has parent", function()
        assert.are.same(M("/a"), M("/a/b"):parent())
    end)

    it("parent = root", function()
        assert.are.same(M("/"), M("/a"):parent())
    end)

    it("no parent", function()
        assert.are.same(M(""), M("a"):parent())
    end)
end)

describe("iterdir", function()
    local root = M(dir_path)
    local root_f = root:join("1.txt")

    local a = root:join("a")
    local a_f = a:join("2.txt")

    local b = root:join("b")
    local b_f = b:join("3.txt")

    before_each(function()
        root:mkdir()
        root_f:touch()
        a:mkdir()
        a_f:touch()

        b:mkdir()
        b_f:touch()
    end)

    local function check(expected, actual)
        table.sort(actual, function(a, b) return tostring(a) < tostring(b) end)
        table.sort(expected, function(a, b) return tostring(a) < tostring(b) end)
        assert.are.same(expected, actual)
    end

    it("works", function()
        local expected = {
            a,
            a_f,
            b,
            b_f,
            root_f,
        }

        check(expected, root:iterdir())
    end)

    it("doesn't recurse", function()
        check({root_f, a, b}, root:iterdir({recursive = false}))
    end)

    it("files only", function()
        check({root_f, a_f, b_f}, root:iterdir({dirs = false}))
    end)

    it("dirs only", function()
        check({a, b}, root:iterdir({files = false}))
    end)
end)

describe("write", function()
    local p = M(file_path)

    before_each(function()
        p:unlink()
    end)

    after_each(function()
        p:unlink()
    end)

    it("writes str", function()
        local content = "123"
        p:write(content)
        assert.are.same(content, p:read())
    end)

    it("writes int", function()
        local content = 1
        p:write(content)
        assert.are.same(tostring(content), p:read())
    end)

    it("writes table of strs", function()
        local content = List({"a", "b"})
        p:write(content)
        assert.are.same(content:join("\n"), p:read())
    end)

    it("parent doesn't exist", function()
        local p = M(dir_file_path)
        p:parent():rmdir(true)

        assert.falsy(p:parent():exists())
        p:write(1)
        assert.are.same("1", p:read())
    end)
end)

describe("read", function()
    it("reads file", function()
        local content = "1\n2"

        local p = M(file_path)
        local fh = io.open(tostring(p), "w")
        fh:write(content)
        fh:flush()
        fh:close()

        assert.are.same(content, p:read())
        p:unlink()
    end)
end)

describe("readlines", function()
    it("does", function()
        local p = M(file_path)
        p:write("1\n2")

        assert.are.same({"1", "2"}, p:readlines())
    end)
end)


describe("touch", function()
    local p = M(file_path)
    it("creates file if it doesn't exist", function()
        p:unlink()
        assert.is_false(p:exists())
        p:touch()
        assert(p:exists())
    end)

    it("does not overwrite existing file", function()
        local content = "123"
        p:write(content)
        p:touch()
        assert(p:exists())
        assert.are.same(content, p:read())
    end)
end)


describe("is_dir", function()
    it("+", function()
        assert(M.tempdir:is_dir())
    end)

    it("-: non-existing", function()
        local p = M("/fake-dir")
        assert.is_false(p:exists())
        assert.is_false(p:is_dir())
    end)

    it("-: file", function()
        local p = M(file_path)
        p:touch()
        assert.is_false(p:is_dir())
    end)
end)

describe("is_file", function()
    local p = M(file_path)

    it("+: non-method", function()
        p:touch()
        assert(M.is_file(p))
    end)

    it("+: string", function()
        p:touch()
        assert(M.is_file(file_path))
    end)

    it("+", function()
        p:touch()
        assert(p:is_file())
    end)

    it("-: non-existing", function()
        p:unlink()
        assert.is_false(p:is_file())
    end)

    it("-: dir", function()
        assert.is_false(M.tempdir:is_file())
    end)
end)

describe("rmdir", function()
    local dir = M(dir_path)
    local dir_file = M(dir_file_path)

    it("doesn't remove non-existing", function()
        assert.is_false(dir:exists())
        dir:rmdir()
        assert.is_false(dir:exists())
    end)

    it("removes existing", function()
        dir:mkdir()
        assert(dir:exists())
        dir:rmdir()
        assert.is_false(dir:exists())
    end)

    it("doesn't remove if non-empty", function()
        dir_file:touch()
        assert(dir_file:exists())
        dir:rmdir()
        assert(dir_file:exists())
    end)

    it("removes if non-empty and `force`", function()
        dir_file:touch()
        assert(dir_file:exists())
        dir:rmdir(true)
        assert.is_false(dir_file:exists())
    end)
end)

describe("is_empty", function()
    local dir = M(dir_path)
    local dir_file = M(dir_file_path)

    it("empty dir", function()
        dir:rmdir(true)
        dir:mkdir()
        assert(dir:is_empty())
    end)

    it("non-empty dir", function()
        dir_file:touch()
        assert.is_false(dir:is_empty())
    end)
end)

describe("mkdir", function()
    local dir = M(dir_path)
    local dir_file = M(dir_file_path)
    local subdir = dir:join("subdir")

    it("+", function()
        assert.is_false(dir:exists())
        dir:mkdir()
        assert(dir:is_dir())
    end)

    it("existing", function()
        dir_file:write("1")
        dir:mkdir()
        assert.are.same("1", dir_file:read())
    end)

    it("makes parents", function()
        assert.is_false(dir:exists())
        assert.is_false(subdir:exists())
        subdir:mkdir()
        assert(dir:exists())
        assert(subdir:exists())
    end)
end)

describe("name", function()
    it("with suffix", function()
        assert.are.same("c.txt", M("a/b/c.txt"):name())
    end)

    it("no suffix", function()
        assert.are.same("c", M("a/b/c"):name())
    end)
end)

describe("suffixes", function()
    it("none", function()
        assert.are.same({}, M("a/b"):suffixes())
    end)

    it("1", function()
        assert.are.same({".x"}, M("a/b.x"):suffixes())
    end)

    it("2", function()
        assert.are.same({".x", ".y"}, M("a/b.x.y"):suffixes())
    end)
end)

describe("suffix", function()
    it("with suffix", function()
        assert.are.same(".txt", M("a/b/c.txt"):suffix())
    end)

    it("no suffix", function()
        assert.are.same("", M("a/b/c"):suffix())
    end)

    it("multiple suffixes", function()
        assert.are.same(".y", M("a/b/c.x.y"):suffix())
    end)
end)

describe("stem", function()
    it("with suffix", function()
        assert.are.same("c", M("a/b/c.txt"):stem())
    end)

    it("no suffix", function()
        assert.are.same("c", M("a/b/c"):stem())
    end)
end)

describe("with_name", function()
    it("does it", function()
        assert.are.same(M("/a/b/x.y"), M("/a/b/c.d"):with_name("x.y"))
    end)

    it("+: base", function()
        assert.are.same(M("/a/b/x.y"), M("/a/b/c.d"):with_name("x.y"))
    end)
end)

describe("with_stem", function()
    it("no suffix", function()
        assert.are.same(M("/a/b/x"), M("/a/b/c"):with_stem("x"))
    end)

    it("has suffix", function()
        assert.are.same(M("/a/b/x.d"), M("/a/b/c.d"):with_stem("x"))
    end)

    it("multiple suffixes", function()
        assert.are.same(M("x.b.c"), M("a.b.c"):with_stem("x"))
    end)
end)

describe("with_suffix", function()
    it("no suffix", function()
        assert.are.same(M("/a/b/c.x"), M("/a/b/c"):with_suffix(".x"))
    end)
    it("has suffix", function()
        assert.are.same(M("/a/b/c.x"), M("/a/b/c.d"):with_suffix(".x"))
    end)
end)

describe("is_relative_to", function()
    it("root", function()
        assert(M("/a/b"):is_relative_to("/"))
    end)

    it("parent", function()
        assert(M("/a/b"):is_relative_to("/a"))
    end)

    it("parent's parent", function()
        assert(M("/a/b/c"):is_relative_to("/a"))
    end)

    it("non-parent", function()
        assert.is_false(M("/a/b/c"):is_relative_to("/d"))
    end)

    it("self", function()
        assert(M("a"):is_relative_to("a"))
    end)
end)

describe("relative_to", function()
    it("root", function()
        assert.are.same(M("a"), M("/a"):relative_to("/"))
    end)

    it("self", function()
        assert.are.same(M(""), M("a"):relative_to("a"))
    end)

    it("parent", function()
        assert.are.same(M("b"), M("/a/b"):relative_to("/a"))
    end)

    it("parent's parent", function()
        assert.are.same(M("c"), M("a/b/c"):relative_to("a/b"))
    end)

    it("non-relative fails", function()
        assert.has_error(function() M("/a"):relative_to("b") end, "/a is not relative to b")
    end)
end)

describe("rename", function()
    it("file", function()
        local old = M(dir_file_path)
        local new = M(file_path)

        old:write("123")
        old:rename(new)
        assert.falsy(old:exists())
        assert.are.same("123", new:read())
    end)

    it("dir", function()
        local old_dir = M(dir_path)
        local old_file = old_dir:join("file.txt")

        local new_dir = old_dir:with_name("new-dir")
        local new_file = new_dir:join(old_file:name())

        old_file:write("123")
        old_dir:rename(new_dir)

        assert.falsy(old_dir:exists())
        assert.are.same("123", new_file:read())
    end)
end)

describe("join", function()
    it("base case", function()
        assert.are.same(M("a/b.c"), M("a"):join("b.c"))
    end)

    it("empty second", function()
        assert.are.same(M("a"), M("a"):join(""))
    end)

    it("multiple", function()
        assert.are.same(M("a/b/c.d"), M("a"):join("b", "c.d"))
    end)

    it("trailing /", function()
        assert.are.same(M("a/b"), M("a/"):join("b"))
    end)

    it("leading /", function()
        assert.are.same(M("a/b"), M("a"):join("/b"))
    end)

    it("/ + other", function()
        assert.are.same(M("/a"), M("/"):join("a"))
    end)

    it("path", function()
        assert.are.same(M("a/b"), M("a"):join(M("b")))
    end)

    it("doesn't modify args", function()
        local a = M("a")
        local b = M("b")
        local c = a:join(b)
        assert.are.same("a", tostring(a))
        assert.are.same("b", tostring(b))
        assert.are.same("a/b", tostring(c))
    end)

    it("div operator", function()
        assert.are.same(M("a/b"), M("a") / "b")
    end)
end)

describe("resolve", function()
    it("leading '.'", function()
        assert.are.same(M.cwd() / "a", M("./a"):resolve())
    end)

    it("nonleading '.'", function()
        assert.are.same(M.cwd() / "a/b", M("a/./b"):resolve())
    end)

    it("'..'", function()
        assert.are.same(M.cwd() / "a/c", M("a/b/../c"):resolve())
    end)

    it("'.a'", function()
        assert.are.same(M.cwd() / ".a", M(".a"):resolve())
    end)
end)

describe("is_absolute", function()
    it("root: +", function()
        assert(M("/"):is_absolute())
    end)

    it("root/etc: +", function()
        assert(M("/a"):is_absolute())
    end)

    it("-", function()
        assert.is_false(M("a"):is_absolute())
    end)
end)

describe("string_to_path", function()
    it("hyphen to underscore", function()
        assert.are.same(M("a_b"), M.string_to_path("a-b"))
    end)

    it("space to hyphen", function()
        assert.are.same(M("a-b"), M.string_to_path("a b"))
    end)

    it("kitchen sink", function()
        assert.are.same(M("a_b-c_d"), M.string_to_path("a_b c-d"))
    end)
end)
