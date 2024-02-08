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
            "activity: true",
            track:activity_to_list_line("activity", true)
        )
    end)

    it("value defaulted", function()
        local activity = track.activities:keys()[1]
        local value = track.activities[activity].default
        assert.are.same(
            activity .. track.separator .. tostring(value),
            track:activity_to_list_line(activity)
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
