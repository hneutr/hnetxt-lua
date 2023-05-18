local stub = require('luassert.stub')
local Path = require("hl.path")

local Project = require("htl.project")
local Registry = require("htl.project.registry")
local Config = require("htl.config")

local Notes = require("htl.notes")

local test_data_dir = Path.joinpath(Path.tempdir(), "test-project-data-dir")
local test_project_config = table.default({data_dir = test_data_dir}, Config.get('project'))
local test_project_dir = Path.joinpath(Path.tempdir(), "test-project")
local test_project_name = "test-project"
local registry

-- function setup_project()
--     registry = Registry()
--     Project.create(test_project_name, test_project_dir)
-- end

-- before_each(function()
--     Path.rmdir(test_data_dir, true)
--     stub(Config, 'get')
--     Config.get.on_call_with('project').returns(test_project_config)

--     Registry.config = Config.get("project")
-- end)

-- after_each(function()
--     Config.get:revert()
--     Path.rmdir(test_data_dir, true)
--     Registry.config = Config.get("project")
-- end)
