table = require("hl.table")
local Path = require("hl.path")

local Project = require("htl.project")
local Operator = require("htl.project.move.operator")
local Operation = require("htl.project.move.operation")
local FileOperation = require("htl.project.move.operation.file")
local DirOperation = require("htl.project.move.operation.dir")
local MarkOperation = require("htl.project.move.operation.mark")

local project_root_from_path

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")
-- local operation_class_to_test = "file"
-- local action_to_test = "rename"

local function make_relative_to_test_dir(thing, args)
    args = table.default(args or {}, {transform_keys = false, transform_values = false})

    if type(thing) == 'string' then
        return Path.joinpath(test_dir, thing)
    elseif type(thing) == 'table' then
        local new_thing = {}
        if table.is_list(thing) then
            for i, v in ipairs(thing) do 
                new_thing[i] = Path.joinpath(test_dir, v)
            end
        else
            for k, v in pairs(thing) do
                if args.transform_keys then
                    k = Path.joinpath(test_dir, k)
                end

                if args.transform_values then
                    v = Path.joinpath(test_dir, v)
                end
                new_thing[k] = v
            end
        end

        return new_thing
    end
    return nil
end

local function run_action_test(spec, subtest_name)
    local test_name = string.format("%s.%s", spec.operation_class, spec.action)

    if subtest_name then
        test_name = string.format("%s: %s", test_name, subtest_name)
    end

    if spec.subtests ~= nil then
        for subtest_name, subtest_spec in pairs(spec.subtests) do
            local subspec = table.default({}, subtest_spec, spec)
            subspec.subtests = nil
            run_action_test(subspec, subtest_name)
        end
    else
        it(test_name, function()
            for _, path in ipairs(make_relative_to_test_dir(spec.make)) do
                if Path.is_file_like(path) then
                    Path.touch(path)
                elseif Path.is_dir_like(path) then
                    Path.mkdir(path)
                end
            end

            local source = make_relative_to_test_dir(spec.source)
            local target = make_relative_to_test_dir(spec.target)

            local OperationClass = Operator.get_operation_class(source)

            assert.are.same(
                Operator.source_type_to_operation_class[spec.operation_class],
                OperationClass
            )

            local action = Operator.get_action(source, target)

            assert.are.same(spec.action, action.action_name)

            target = action.transform_target(target, source)

            if spec.transformed_target then
                assert.are.same(
                    make_relative_to_test_dir(spec.transformed_target),
                    target
                )
            end

            local map = action.map_source_to_target(source, target)

            if spec.map then
                assert.are.same(
                    make_relative_to_test_dir(spec.map, {transform_keys = true, transform_values = true}),
                    map
                )
            end

            local mirrors_map = action.map_mirrors(map)

            if spec.mirrors_map then
                assert.are.same(
                    make_relative_to_test_dir(spec.mirrors_map, {transform_keys = true, transform_values = true}),
                    mirrors_map
                )
            end

            if spec.processing_results then
                action.process(map, mirrors_map)

                for k, fn in pairs(make_relative_to_test_dir(spec.processing_results, {transform_keys = true})) do
                    fn(k)
                end
            end

            -- TODO: finish with process and update_references
        end)
    end
end

local action_tests = {
    ------------------------------------[ file ]------------------------------------
    {
        operation_class = "file", 
        action = "rename",
        subtests = {
            ["Path.exists(target)"] = {make = {"a.md", "b.md"}},
            ["! Path.exists(target)"] = {make = {"a.md"}},
        },
        source = "a.md",
        target = "b.md",
        transformed_target = "b.md",
        map = {["a.md"] = "b.md"},
        processing_results = {
            ["a.md"] = function(p) assert.falsy(Path.exists(p)) end,
            ["b.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operation_class = "file", 
        action = "move",
        make = {"a.md", "b"},
        source = "a.md",
        target = "b",
        transformed_target = "b/a.md",
        map = {["a.md"] = "b/a.md"},
        processing_results = {
            ["a.md"] = function(p) assert.falsy(Path.exists(p)) end,
            ["b/a.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operation_class = "file", 
        action = "to dir",
        make = {"a.md"},
        source = "a.md",
        target = "b",
        transformed_target = "b/@.md",
        map = {["a.md"] = "b/@.md"},
        processing_results = {
            ["a.md"] = function(p) assert.falsy(Path.exists(p)) end,
            ["b/@.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operation_class = "file", 
        action = "to mark",
        subtests = {
            ["Path.exists(target)"] = {make = {"a.md", "b.md"}},
            ["! Path.exists(target)"] = {make = {"a.md"}},
        },
        source = "a.md",
        target = "b.md:c",
        transformed_target = "b.md:c",
        map = {["a.md"] = "b.md:c"},
        -- processing_results = {},
    },
    --------------------------------------[ dir ]-------------------------------------
    {
        operation_class = "dir", 
        action = "rename",
        source = "a",
        target = "b",
        make = {"a", "a/c.md"},
        transformed_target = "b",
        map = {["a/c.md"] = "b/c.md"},
        processing_results = {
            a = function(p) assert.falsy(Path.exists(p)) end,
            b = function(p) assert(Path.is_dir(p)) end,
            ["b/c.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operation_class = "dir", 
        action = "move",
        source = "a",
        target = "b",
        make = {"a", "b", "a/c.md"},
        transformed_target = "b/a",
        map = {["a/c.md"] = "b/a/c.md"},
        processing_results = {
            a = function(p) assert.falsy(Path.exists(p)) end,
            ["b/a/c.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operation_class = "dir", 
        action = "to files",
        source = "a/b",
        target = "a",
        make = {"a", "a/b", "a/b/@.md", "a/b/c.md"},
        transformed_target = "a",
        map = {["a/b/@.md"] = "a/b.md", ["a/b/c.md"] = "a/c.md"},
        processing_results = {
            ["a/b"] = function(p) assert.falsy(Path.exists(p)) end,
            ["a/b.md"] = function(p) assert(Path.is_file(p)) end,
            ["a/c.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    ------------------------------------[ mark ]------------------------------------
    {
        operation_class = "mark", 
        action = "move",
        source = "a.md:b",
        target = "c.md:d",
        subtests = {
            ["Path.exists(target)"] = {make = {"a.md", "c.md"}},
            ["! Path.exists(target)"] = {make = {"a.md"}},
        },
        transformed_target = "c.md:d",
        map = {["a.md:b"] = "c.md:d"},
    },
    {
        operation_class = "mark", 
        action = "to file",
        source = "a.md:b",
        target = "c.md",
        subtests = {
            ["Path.exists(target)"] = {make = {"a.md", "c.md"}},
            ["! Path.exists(target)"] = {make = {"a.md"}},
        },
        transformed_target = "c.md",
        map = {["a.md:b"] = "c.md"},
    },
    {
        operation_class = "mark", 
        action = "to dir",
        source = "a.md:b",
        target = "c",
        make = {"a.md"},
        transformed_target = "c/@.md",
        map = {["a.md:b"] = "c/@.md"},
    },
    {
        operation_class = "mark", 
        action = "to dir file",
        source = "a.md:b",
        target = "c",
        make = {"a.md", "c"},
        transformed_target = "c/b.md",
        map = {["a.md:b"] = "c/b.md"},
    }
}

before_each(function()
    Path.rmdir(test_dir, true)
    project_root_from_path = Project.root_from_path
    Project.root_from_path = function() return test_dir end
end)

after_each(function()
    Path.rmdir(test_dir, true)
    Project.root_from_path = project_root_from_path
end)

describe("actions", function()
    for _, spec in ipairs(action_tests) do
        if not operation_class_to_test or operation_class_to_test == spec.operation_class then
            if not action_to_test or action_to_test == spec.action then
                run_action_test(spec)
            end
        end
    end
end)
