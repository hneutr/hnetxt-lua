local stub = require('luassert.stub')
local Path = require("hl.path")
local yaml = require("hl.yaml")

local Registry = require("htl.project.registry")
local Project = require("htl.project")
local config = require("htl.config").get("journal")

local Journal = require("htl.journal")

describe("get_path", function()
    it("no project", function()
        local expected = Path.joinpath(config.dir, string.format("%s.md", os.date("%Y%m")))
        assert.are.same(
            expected,
            Journal()
        )
    end)

    it("project", function()
        local project_name = "journal-test"
        local project_dir = Path.joinpath(Path.tempdir(), "journal-test")

        Project.create(project_name, project_dir)

        local expected = Path.joinpath(
            project_dir,
            config.project_dir,
            string.format("%s.md", os.date("%Y%m"))
        )

        assert.are.same(
            expected,
            Journal({project = project_name})
        )

        Path.rmdir(project_dir, true)
        Registry():remove_entry(project_name)
    end)
end)
