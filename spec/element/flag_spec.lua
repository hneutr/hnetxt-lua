local Path = require("hneutil.path")
local Flag = require("hnetxt-lua.element.flag")

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")
local test_file = Path.joinpath(test_dir, "test-file.md")

local test_subdir = Path.joinpath(test_dir, "test-subdir")
local test_subfile = Path.joinpath(test_subdir, "test-subfile.md")

before_each(function()
    Path.rmdir(test_dir, true)
end)

after_each(function()
    Path.rmdir(test_dir, true)
end)

describe("__tostring", function() 
    it("empty", function()
        assert.equals("||", tostring(Flag()))
    end)

    it("populated", function()
        assert.equals("|?*|", tostring(Flag({question = true, brainstorm = true})))
    end)
end)

describe("str_is_a", function()
    it("rejects text", function()
        assert.falsy(Flag.str_is_a("abcde"))
    end)

    it("rejects a link with bad location content", function()
        assert.falsy(Flag.str_is_a("|steve|"))
    end)

    it("accepts a link with good location content", function()
        assert(Flag.str_is_a("|?|"))
    end)

    it("kitchen sink acceptance", function()
        assert(Flag.str_is_a("before |?*| after"))
    end)
end)

describe("from_str", function()
    it("correct flags when present", function()
        assert.are.same(
            Flag({before = 'a ', after = ' z', question = true}),
            Flag.from_str("a |?| z")
        )
    end)

    it("multiple flags when flags present", function()
        assert.are.same(
            Flag({before = 'a ', after = ' z', question = true, brainstorm = true}),
            Flag.from_str("a |?*| z")
        )
    end)
end)

describe("get_instances", function()
    it("works", function()
        Path.write(test_file, {"a |?*|", "no flags", "bc |*?|"})
        Path.write(test_subfile, {"z |?|", "no flags", "x |*|"})
        local actual = Flag.get_instances("question", test_dir)
        table.sort(actual, function(a, b) return a:len() < b:len() end)
        assert.are.same(
            {
                "test file: a",
                "test file: bc",
                "test subfile: z"
            },
            actual
        )
    end)
end)

describe("clean_flagged_path", function()
    it("relativizes", function()
        assert.are.same("b", Flag.clean_flagged_path("/a/b", "/a"))
    end)

    it("handles dir_file_stem", function()
        assert.are.same("b", Flag.clean_flagged_path("/a/b/@"))
    end)

    it("removes -", function()
        assert.are.same("b c", Flag.clean_flagged_path("/a/b-c"))
    end)
end)

describe("clean_flagged_str", function()
    it("removes flags", function()
        assert.are.same("a", Flag.clean_flagged_str("a |?*#|"))
    end)

    it("removes links", function()
        assert.are.same("a", Flag.clean_flagged_str("[a](b)"))
    end)

    it("removes commenting", function()
        assert.are.same("a", Flag.clean_flagged_str("> a"))
    end)

    it("removes lists", function()
        assert.are.same("a", Flag.clean_flagged_str("- a"))
        assert.are.same("a", Flag.clean_flagged_str("+ a"))
        assert.are.same("a", Flag.clean_flagged_str("10. a"))
    end)
end)
