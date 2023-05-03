local stub = require('luassert.stub')
local Path = require("hneutil.path")
local yaml = require("hneutil.yaml")

local Registry = require("hnetxt-lua.project.registry")
local Project = require("hnetxt-lua.project")
local config = require("hnetxt-lua.config").get("journal")

local Journal = require("hnetxt-lua.journal")

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
