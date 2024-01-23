local Path = require("hl.path")
local yaml = require("hl.yaml")

local Project = require("htl.project")
local Registry = require("htl.project.registry")
local Config = require("htl.config")

local temp_registry_path = Path.tempdir:join("test-registry.yaml")
local registry_path = Registry.path

local test_dir = Path.tempdir:join("test-dir")
local test_project_dir = Path.tempdir:join("test-project")
local test_project_file = test_project_dir:join("test-file.md")
local test_project_name = "test-project"

local project

function get_project()
    Project.create(test_project_name, test_project_dir)
    project = Project(test_project_name)
end

before_each(function()
    temp_registry_path:unlink()
    Registry.path = temp_registry_path

    test_dir:rmdir(true)
    test_project_dir:rmdir(true)
    Project.config = Config.get("project")
end)

after_each(function()
    test_dir:rmdir(true)
    test_project_dir:rmdir(true)

    Registry.path = registry_path
end)

describe("get_metadata_path", function()
    it("in dir", function()
        assert.are.same(test_project_dir:join(".project"), Project.get_metadata_path(test_project_dir))
    end)

    it("no dir", function()
        assert.are.same(Path.cwd():join(".project"), Project.get_metadata_path())
    end)
end)

describe("create", function()
    it("no start date", function()
        local expected = {
            name = "test project",
            date = tonumber(os.date("%Y%m%d"))
        }

        Project.create(test_project_name, test_project_dir)
        assert.are.same(expected, yaml.read(Project.get_metadata_path(test_project_dir)))
        assert.are.same(test_project_dir, Registry.get_entry_dir(test_project_name))
    end)

    it("start date", function()
        local date = tonumber(os.date("20230414"))
        local expected = {
            name = "test project",
            date = date,
        }

        Project.create(test_project_name, test_project_dir, {date = date})
        assert.are.same(expected, yaml.read(Project.get_metadata_path(test_project_dir)))
        assert.are.same(test_project_dir, Registry.get_entry_dir(test_project_name))
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
