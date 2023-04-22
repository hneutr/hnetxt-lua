local Path = require("hneutil.path")
local lyaml = require("lyaml")

local Project = require("hnetxt-lua.project")
local Registry = require("hnetxt-lua.project.registry")
local Config = require("hnetxt-lua.config")

local test_project_data_dir = Path.joinpath(Path.tempdir(), "test-project-data-dir")
local test_project_dir = Path.joinpath(Path.tempdir(), "test-project")
local test_project_name = "test-project"

local project

function get_project()
    Project.create(test_project_name, test_project_dir)
    project = Project({name = test_project_name, dir = test_project_dir})
end

before_each(function()
    Path.rmdir(test_project_data_dir, true)
    Path.rmdir(test_project_dir, true)
    Project.config = Config.get("project")
    Registry.config = Config.get("project")
    Registry.config.data_dir = test_project_data_dir
end)

describe("get_metadata_path", function()
    it("in dir", function()
        assert.are.same(Path.joinpath(test_project_dir, ".project"), Project.get_metadata_path(test_project_dir))
    end)

    it("no dir", function()
        assert.are.same(Path.joinpath(Path.cwd(), ".project"), Project.get_metadata_path())
    end)
end)

describe("create", function()
    it("no start date", function()
        local expected = {
            name = test_project_name,
            start_date = os.date("%Y%m%d")
        }

        Project.create(test_project_name, test_project_dir)
        assert.are.same(expected, lyaml.load(Path.read(Project.get_metadata_path(test_project_dir))))
        assert.are.same(test_project_dir, Registry():get_entry(test_project_name))
    end)

    it("start date", function()
        local start_date = os.date("20230414")
        local expected = {
            name = test_project_name,
            start_date = start_date,
        }

        Project.create(test_project_name, test_project_dir, {start_date = start_date})
        assert.are.same(expected, lyaml.load(Path.read(Project.get_metadata_path(test_project_dir))))
        assert.are.same(test_project_dir, Registry():get_entry(test_project_name))
    end)
end)

describe("in_project", function()
    it("not in project", function()
        Path.mkdir(test_project_dir)
        assert.falsy(Project.in_project(test_project_dir))
    end)

    it("in project", function()
        get_project()
        assert(Project.in_project(test_project_dir))
    end)
    it("in project subdir", function()
        get_project()
        local path = Path.joinpath(test_project_dir, "test")
        Path.mkdir(path)
        assert(Project.in_project(path))
    end)
end)

describe("root", function()
    it("gets", function()
        get_project()
        assert.are.same(test_project_dir, project.root)
    end)
end)

describe("get_journal_path", function()
    it("gets", function()
        get_project()
        local expected = Path.joinpath(test_project_dir, Config.get("project").journal_dir, os.date("%Y%m") .. ".md")
        assert.are.same(expected, project:get_journal_path())
    end)
end)
