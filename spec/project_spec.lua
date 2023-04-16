local Path = require("hneutil.path")
local lyaml = require("lyaml")

local Project = require("hnetxt.project")



local test_project_dir = Path.joinpath(Path.tempdir(), "test-project")
local test_project_name = "test-project"

local function create_project()
    Project.create({dir = test_project_dir, metadata = {name = test_project_name}})
end

before_each(function()
    Path.rmdir(test_project_dir, true)
end)

after_each(function()
    Path.rmdir(test_project_dir, true)
end)



describe("constants_path", function()
    it("checks that the config gets loaded", function()
        assert.are.same({filename = ".project"}, Project.load_constants())
    end)
end)

describe("get_config_path", function()
    it("in dir", function()
        assert.are.same(Path.joinpath(test_project_dir, ".project"), Project.get_config_path(test_project_dir))
    end)

    it("no dir", function()
        assert.are.same(Path.joinpath(Path.cwd(), ".project"), Project.get_config_path())
    end)
end)

describe("create", function()
    it("no start date", function()
        local expected = {
            name = test_project_name,
            start_date = os.date("%Y%m%d")
        }

        Project.create({dir = test_project_dir, metadata = {name = test_project_name}})
        assert.are.same(expected, lyaml.load(Path.read(Project.get_config_path(test_project_dir))))
    end)

    it("start date", function()
        local expected = {
            name = test_project_name,
            start_date = os.date("20230414")
        }

        Project.create({dir = test_project_dir, metadata = expected})
        assert.are.same(expected, lyaml.load(Path.read(Project.get_config_path(test_project_dir))))
    end)
end)

-- describe("in_project", function()
--     it("not in project", function()
--         assert.falsy(Project.in_project())
--     end)
-- end)
