io = require('hl.io')
local Path = require("hl.path")

describe("command", function()
    it("simple command", function()
        assert.are.same('a\n', io.command("echo 'a'"))
    end)

    it("cd", function()
        local command = "cd " .. tostring(Path.tempdir) .. " && echo $PWD"
        assert.are.same(tostring(Path.tempdir) .. '\n', io.command(command))
    end)
end)
