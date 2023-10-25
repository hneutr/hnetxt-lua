local Path = require("hl.Path")

local Track = require("htl.track")

local test_dir = Path.tempdir:join('test-track')
local track

before_each(function()
    test_dir:rmdir(true)
    test_dir:mkdir()

    track = Track()
    track.data_dir = test_dir
end)

after_each(function()
    test_dir:rmdir(true)
end)

describe("activity_to_list_line", function()
    it("value provided", function()
        assert.are.same(
            "`activity`: true",
            track:activity_to_list_line("activity", true)
        )
    end)

    it("value defaulted", function()
        local activity = track.activities[1]
        local value = track.activity_defaults[activity]
        assert.are.same(
            track.surround .. activity .. track.surround .. track.separator .. tostring(value),
            track:activity_to_list_line(activity)
        )
    end)
end)

describe("list_line_to_row", function()
    local key = "test"

    it("empty", function()
        assert.is_nil(track:list_line_to_row(track:activity_to_list_line(key)))
    end)

    it("true", function()
        assert.are.same(
            {field = key, value = true, date = track.default_date()},
            track:list_line_to_row(track:activity_to_list_line(key, true))
        )
    end)

    it("false", function()
        assert.are.same(
            {field = key, value = false, date = track.default_date()},
            track:list_line_to_row(track:activity_to_list_line(key, false))
        )
    end)

    it("number", function()
        assert.are.same(
            {field = key, value = 1234, date = track.default_date()},
            track:list_line_to_row(track:activity_to_list_line(key, 1234))
        )
    end)
end)

describe("touch", function()
    it("doesn't overwrite", function()
        track:list_path():touch()
        assert.are.same("", track:list_path():read())
        track:touch()
        assert.are.same("", track:list_path():read())
    end)

    it("writes", function()
        track:touch()
        assert.are.same(track:list_lines(), track:list_path():readlines())
    end)
end)

describe("list_path_to_rows", function()
    it("works", function()
        local l1 = track:activity_to_list_line("a", true)
        local l2 = track:activity_to_list_line("b", false)
        local l3 = track:activity_to_list_line("c")

        track:list_path():write({l1, l2, l3})

        local r1 = track:list_line_to_row(l1)
        local r2 = track:list_line_to_row(l2)

        assert.are.same(
            {r1, r2},
            track:list_path_to_rows(track:list_path())
        )
    end)
end)

describe("create_csv", function()
    it("works", function()
        local l1 = track:activity_to_list_line("a", true)
        local l2 = track:activity_to_list_line("a", 123)

        track:list_path():write({l1})
        track:list_path("19900120"):write({l2})

        track:create_csv()
        assert.are.same(3, #track:csv_path():readlines())
    end)
end)
