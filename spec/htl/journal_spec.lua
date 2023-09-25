local stub = require('luassert.stub')
local Path = require("hl.path")
local yaml = require("hl.yaml")

local Registry = require("htl.project.registry")
local Project = require("htl.project")
local config = require("htl.config").get("journal")

local Journal = require("htl.journal")

describe("get_path", function()
    it("no project", function()
        assert.are.same(
            config.global_dir,
            Path.parent(Journal())
        )
    end)

    it("project", function()
        local project_name = "journal-test"
        local project_dir = Path.joinpath(tostring(Path.tempdir), "journal-test")

        Project.create(project_name, project_dir)

        local expected = Path.joinpath(project_dir, config.project_dir)

        assert.are.same(
            expected,
            Path.parent(Journal(Project(project_name).root))
        )

        Path.rmdir(project_dir, true)
        Registry():remove_entry(project_name)
    end)
end)
