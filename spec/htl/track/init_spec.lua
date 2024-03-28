local Track = require("htl.track")
local Config = require("htl.Config")

before_each(function()
    Config.before_test()
end)

after_each(function()
    Config.after_test()
end)

describe("touch", function()
    it("writes", function()
        Track:touch()
        assert.are.same(Track.to_track_path:read(), Track:path():read())
    end)
end)
