local Path = require("hl.path")
local yaml = require("hl.yaml")

local Project = require("htl.project")
local Registry = require("htl.project.registry")
local Config = require("htl.config")

local test_project_data_dir = Path.joinpath(Path.tempdir(), "test-project-data-dir")
local test_project_dir = Path.joinpath(Path.tempdir(), "test-project")
local test_project_file = Path.joinpath(test_project_dir, "test-file.md")
local test_project_name = "test-project"

local project

function get_project()
    Project.create(test_project_name, test_project_dir)
    project = Project(test_project_name)
end

before_each(function()
    Path.rmdir(test_project_data_dir, true)
    Path.rmdir(test_project_dir, true)
    Project.config = Config.get("project")
    Registry.config = Config.get("project")
    Registry.config.data_dir = test_project_data_dir
end)

after_each(function()
    Path.rmdir(test_project_data_dir, true)
    Path.rmdir(test_project_dir, true)
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
            date = tonumber(os.date("%Y%m%d"))
        }

        Project.create(test_project_name, test_project_dir)
        assert.are.same(expected, yaml.read(Project.get_metadata_path(test_project_dir)))
        assert.are.same(test_project_dir, Registry():get_entry_dir(test_project_name))
    end)

    it("start date", function()
        local date = tonumber(os.date("20230414"))
        local expected = {
            name = test_project_name,
            date = date,
        }

        Project.create(test_project_name, test_project_dir, {date = date})
        assert.are.same(expected, yaml.read(Project.get_metadata_path(test_project_dir)))
        assert.are.same(test_project_dir, Registry():get_entry_dir(test_project_name))
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

describe("from_path", function()
    it("match", function()
        get_project()
        assert.are.same(project, Project.from_path(test_project_dir))
    end)

    it("no match", function()
        assert.falsy(Project.from_path(test_project_dir))
    end)
end)

describe("root_from_path", function()
    it("+", function()
        get_project()
        assert.are.same(test_project_dir, Project.root_from_path(test_project_dir))
    end)

    it("+: subfile", function()
        get_project()
        assert.are.same(test_project_dir, Project.root_from_path(test_project_file))
    end)

    it("-", function()
        assert.falsy(Project.root_from_path(test_project_dir))
    end)
end)


describe("root", function()
    it("gets", function()
        get_project()
        assert.are.same(test_project_dir, project.root)
    end)
end)
