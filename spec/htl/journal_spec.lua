local Path = require("hl.Path")

local Config = require("htl.config").get("journal")

local Journal = require("htl.journal")

describe("get_path", function()
    it("no project", function()
        assert.are.same(Config.global_dir, Path.parent(Journal()))
    end)

    it("project", function()
        local project_dir = Path.tempdir:join("journal-test")

        assert.are.same(
            tostring(project_dir:join(Config.project_dir, os.date("%Y%m%d") .. ".md")),
            Journal(project_dir)
        )
    end)
end)
