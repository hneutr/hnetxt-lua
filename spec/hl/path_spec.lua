Path = require('hl.Path')

local file_path = "/tmp/test-file.txt"

local dir_path = "/tmp/test-dir"
local dir_file_path = "/tmp/test-dir/test-file.txt"

before_each(function()
    Path(dir_path):rmdir(true)
    Path(file_path):unlink()
end)

after_each(function()
    Path(dir_path):rmdir(true)
    Path(file_path):unlink()
end)

describe("init", function()
    it("works", function()
        local p = "~/Desktop"
        assert.are.same(p, Path(p).p)
    end)
end)

describe("tempdir", function()
    it("works", function()
        assert.are.equal(Path("/tmp"), Path.tempdir)
    end)
end)

describe("home", function()
    it("works", function()
        assert.are.equal(Path(os.getenv("HOME")), Path.home)
    end)
end)

describe("currentdir", function()
    it("works", function()
        assert.are.equal(Path(os.getenv("PWD")), Path.cwd())
    end)
end)

describe("exists", function()
    it("does", function()
        assert.is_true(Path("/Users/hne/Desktop"):exists())
    end)

    it("doesn't", function()
        assert.is_false(Path("steve"):exists())
    end)
end)

describe("unlink", function()
    local p = Path(file_path)
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

describe("join", function()
    it("base case", function()
        assert.are.equal(Path("a/b.c"), Path("a"):join("b.c"))
    end)

    it("empty second", function()
        assert.are.equal(Path("a"), Path("a"):join(""))
    end)

    it("multiple", function()
        assert.are.equal(Path("a/b/c.d"), Path("a"):join("b", "c.d"))
    end)

    it("trailing /", function()
        assert.are.equal(Path("a/b"), Path("a/"):join("b"))
    end)

    it("leading /", function()
        assert.are.equal(Path("a/b"), Path("a"):join("/b"))
    end)

    it("/ + other", function()
        assert.are.equal(Path("/a"), Path("/"):join("a"))
    end)

    it("path", function()
        assert.are.equal(Path("a/b"), Path("a"):join(Path("b")))
    end)

    it("doesn't modify args", function()
        local a = Path("a")
        local b = Path("b")
        local c = a:join(b)
        assert.are.same("a", tostring(a))
        assert.are.same("b", tostring(b))
        assert.are.same("a/b", tostring(c))
    end)
end)

describe("concat", function()
    it("works", function()
        assert.are.same(Path("a/b"), Path("a") .. "b")
    end)
end)

describe("expanduser", function()
    it("expands at start", function()
        assert.are.equal(Path.home:join("a"), Path("~/a"):expanduser())
    end)

    it("expands at start: non-object", function()
        assert.are.equal(tostring(Path.home:join("a")), Path.expanduser("~/a"))
    end)

    it("doesn't expand anywhere else", function()
        assert.are.equal(Path("/a/~/b"), Path("/a/~/b"):expanduser())
    end)
end)

describe("parts", function()
    it("single", function()
        assert.are.same({"a"}, Path("a"):parts())
    end)

    it("with root", function()
        assert.are.same({"/", "a"}, Path("/a"):parts())
    end)

    it("multiple", function()
        assert.are.same({"a", "b", "c"}, Path("a/b/c"):parts())
    end)
end)

describe("parents", function()
    it("no parents", function()
        assert.are.same({}, Path("a"):parents())
    end)

    it("has parents", function()
        assert.are.same({Path("a/b/c"), Path("a/b"), Path("a")}, Path("a/b/c/d"):parents())
    end)

    it("parents with root", function()
        assert.are.same({Path("/a/b/c"), Path("/a/b"), Path("/a"), Path("/")}, Path("/a/b/c/d"):parents())
    end)
end)

describe("parent", function()
    it("has parent", function()
        assert.are.same(Path("/a"), Path("/a/b"):parent())
    end)
    it("no parent", function()
        assert.are.same(Path("/"), Path("/a"):parent())
    end)
end)

describe("iterdir", function()
    local root = Path(dir_path)
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
    local p = Path(file_path)

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
        local p = Path(dir_file_path)
        p:parent():rmdir(true)

        assert.falsy(p:parent():exists())
        p:write(1)
        assert.are.same("1", p:read())
    end)
end)

describe("read", function()
    it("reads file", function()
        local content = "1\n2"

        local p = Path(file_path)
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
        local p = Path(file_path)
        p:write("1\n2")

        assert.are.same({"1", "2"}, p:readlines())
    end)
end)


describe("touch", function()
    local p = Path(file_path)
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
        assert(Path.tempdir:is_dir())
    end)

    it("-: non-existing", function()
        local p = Path("/fake-dir")
        assert.is_false(p:exists())
        assert.is_false(p:is_dir())
    end)

    it("-: file", function()
        local p = Path(file_path)
        p:touch()
        assert.is_false(p:is_dir())
    end)
end)

describe("is_file", function()
    local p = Path(file_path)

    it("+: non-method", function()
        p:touch()
        assert(Path.is_file(p))
    end)

    it("+: string", function()
        p:touch()
        assert(Path.is_file(file_path))
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
        assert.is_false(Path.tempdir:is_file())
    end)
end)

describe("rmdir", function()
    local dir = Path(dir_path)
    local dir_file = Path(dir_file_path)

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
    local dir = Path(dir_path)
    local dir_file = Path(dir_file_path)

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
    local dir = Path(dir_path)
    local dir_file = Path(dir_file_path)
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
        assert.are.equal("c.txt", Path("a/b/c.txt"):name())
    end)

    it("no suffix", function()
        assert.are.equal("c", Path("a/b/c"):name())
    end)
end)

describe("suffixes", function()
    it("none", function()
        assert.are.same({}, Path("a/b"):suffixes())
    end)

    it("1", function()
        assert.are.same({".x"}, Path("a/b.x"):suffixes())
    end)

    it("2", function()
        assert.are.same({".x", ".y"}, Path("a/b.x.y"):suffixes())
    end)
end)

describe("suffix", function()
    it("with suffix", function()
        assert.are.equal(".txt", Path("a/b/c.txt"):suffix())
    end)

    it("no suffix", function()
        assert.are.equal("", Path("a/b/c"):suffix())
    end)

    it("multiple suffixes", function()
        assert.are.equal(".y", Path("a/b/c.x.y"):suffix())
    end)
end)

describe("stem", function()
    it("with suffix", function()
        assert.are.equal("c", Path("a/b/c.txt"):stem())
    end)

    it("no suffix", function()
        assert.are.equal("c", Path("a/b/c"):stem())
    end)
end)

describe("with_name", function()
    it("does it", function()
        assert.are.same(Path("/a/b/x.y"), Path("/a/b/c.d"):with_name("x.y"))
    end)

    it("+: base", function()
        assert.are.same("/a/b/x.y", Path.with_name("/a/b/c.d", "x.y"))
    end)
end)

describe("with_stem", function()
    it("no suffix", function()
        assert.are.same(Path("/a/b/x"), Path("/a/b/c"):with_stem("x"))
    end)
    it("has suffix", function()
        assert.are.same(Path("/a/b/x.d"), Path("/a/b/c.d"):with_stem("x"))
    end)
end)

describe("with_suffix", function()
    it("no suffix", function()
        assert.are.same(Path("/a/b/c.x"), Path("/a/b/c"):with_suffix(".x"))
    end)
    it("has suffix", function()
        assert.are.same(Path("/a/b/c.x"), Path("/a/b/c.d"):with_suffix(".x"))
    end)
end)

describe("is_relative_to", function()
    it("root", function()
        assert(Path("/a/b"):is_relative_to("/"))
    end)

    it("parent", function()
        assert(Path("/a/b"):is_relative_to("/a"))
    end)

    it("parent's parent", function()
        assert(Path("/a/b/c"):is_relative_to("/a"))
    end)

    it("non-parent", function()
        assert.is_false(Path("/a/b/c"):is_relative_to("/d"))
    end)

    it("self", function()
        assert(Path("a"):is_relative_to("a"))
    end)
end)

describe("relative_to", function()
    it("root", function()
        assert.are.same(Path("a"), Path("/a"):relative_to("/"))
    end)

    it("self", function()
        assert.are.same(Path(""), Path("a"):relative_to("a"))
    end)

    it("parent", function()
        assert.are.same(Path("b"), Path("/a/b"):relative_to("/a"))
    end)

    it("parent's parent", function()
        assert.are.same(Path("c"), Path("a/b/c"):relative_to("a/b"))
    end)

    it("non-relative fails", function()
        assert.has_error(function() Path("/a"):relative_to("b") end, "/a is not relative to b")
    end)
end)

describe("resolve", function()
    it("leading '.'", function()
        assert.are.same(Path.cwd():join("a"), Path("./a"):resolve())
    end)

    it("nonleading '.'", function()
        assert.are.same(Path.cwd():join("a/./b"), Path("a/./b"):resolve())
    end)

    it("'..'", function()
        assert.are.same(Path.cwd():join("a/c"), Path("a/b/../c"):resolve())
    end)

    it("'.a'", function()
        assert.are.same(Path.cwd():join(".a"), Path(".a"):resolve())
    end)
end)

describe("rename", function()
    it("file", function()
        local old = Path(dir_file_path)
        local new = Path(file_path)

        old:write("123")
        old:rename(new)
        assert.falsy(old:exists())
        assert.are.same("123", new:read())
    end)

    it("dir", function()
        local old_dir = Path(dir_path)
        local old_file = old_dir:join("file.txt")

        local new_dir = old_dir:with_name("new-dir")
        local new_file = new_dir:join(old_file:name())

        old_file:write("123")
        old_dir:rename(new_dir)

        assert.falsy(old_dir:exists())
        assert.are.same("123", new_file:read())
    end)
end)

describe("is_file_like", function()
    it("+: extention", function()
        assert(Path("a.md"):is_file_like())
    end)
    it("-: no extention", function()
        assert.falsy(Path("a"):is_file_like())
    end)
end)

describe("is_dir_like", function()
    it("+: no extention", function()
        assert(Path("a"):is_dir_like())
    end)
    it("-: extention", function()
        assert.falsy(Path("a.md"):is_dir_like())
    end)
end)

describe("make_fn_match_input", function()
    local dummy_fn = function(...) return ... end

    it("string -> string", function()
        assert.are.same("abc", Path.make_fn_match_input(dummy_fn)("abc"))
    end)

    it("Path -> Path", function()
        local p = Path("abc")
        assert.are.same(p, Path.make_fn_match_input(dummy_fn)(p))
    end)
end)

describe("removesuffix", function()
    it("works with string", function()
        assert.are.same(
            "ab",
            Path.removesuffix("abc", "c")
        )
    end)

    it("works with Path", function()
        assert.are.same(
            Path("ab"),
            Path("abc"):removesuffix("c")
        )
    end)
end)
