table = require("hl.table")
local stub = require('luassert.stub')
local Path = require("hl.path")

local Project = require("htl.project")
local Operator = require("htl.operator")
local Operation = require("htl.operator.operation")
local FileOperation = require("htl.operator.operation.file")
local DirOperation = require("htl.operator.operation.dir")
local MarkOperation = require("htl.operator.operation.mark")

local project_root_from_path
local operation_class_to_test
local operation_to_test

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")

local function setup_paths(paths)
    for _, path in ipairs(paths) do
        if Path.is_file_like(path) then
            Path.touch(path)
        elseif Path.is_dir_like(path) then
            Path.mkdir(path)
        end
    end
end

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

local function make_spec_paths_relative_to_test_dir(spec)
    if spec.make then
        spec.make = make_relative_to_test_dir(spec.make)
    end

    if spec.source then
        spec.source = make_relative_to_test_dir(spec.source)
    end

    if spec.target then
        spec.target = make_relative_to_test_dir(spec.target)
    end

    if spec.transformed_target then
        spec.transformed_target = make_relative_to_test_dir(spec.transformed_target)
    end

    if spec.map then
        spec.map = make_relative_to_test_dir(spec.map, {transform_keys = true, transform_values = true})
    end

    if spec.results then
        spec.results = make_relative_to_test_dir(spec.results, {transform_keys = true})
    end

    return spec
end

local function run_move_operation_test(spec)
    local source = spec.source
    local target = spec.target

    assert.are.same(
        Operator.source_type_to_operation_class[spec.operation_class],
        Operator.get_operation_class(source)
    )

    local operation = Operator.get_operation(source, target)

    assert.are.same(spec.operation_name, operation.operation_name)

    target = operation.transform_target(target, source)

    if spec.transformed_target then
        assert.are.same(spec.transformed_target, target)
    end

    local map = operation.map_source_to_target(source, target)

    if spec.map then
        assert.are.same(spec.map, map)
    end

    local mirrors_map = operation.map_mirrors(map)

    if spec.mirrors_map then
        assert.are.same(spec.mirrors_map, mirrors_map)
    end

    if spec.results then
        operation.move(map, mirrors_map)

        for k, fn in pairs(spec.results) do
            fn(k)
        end
    end
end

local function run_remove_operation_test(spec)
    local source = spec.source

    assert.are.same(
        Operator.source_type_to_operation_class[spec.operation_class],
        Operator.get_operation_class(source)
    )

    local operation = Operator.get_operation(source)

    assert.are.same(spec.operation_name, operation.operation_name)

    if spec.results then
        operation.remove(source)

        for k, fn in pairs(spec.results) do
            fn(k)
        end
    end
end

local function run_operation_test(spec, subtest_name)
    local test_name = string.format("%s.%s", spec.operation_class, spec.operation_name)

    if subtest_name then
        test_name = string.format("%s: %s", test_name, subtest_name)
    end

    if spec.subtests ~= nil then
        for subtest_name, subtest_spec in pairs(spec.subtests) do
            local subspec = table.default({}, subtest_spec, spec)
            subspec.subtests = nil
            run_operation_test(subspec, subtest_name)
        end
    else
        it(test_name, function()
            spec = make_spec_paths_relative_to_test_dir(spec)
            setup_paths(spec.make)

            if spec.operator_action == 'move' then
                run_move_operation_test(spec)
            elseif spec.operator_action == 'remove' then
                run_remove_operation_test(spec)
            end
        end)
    end
end

local operation_tests = {
    ------------------------------------[ file ]------------------------------------
    {
        operation_class = "file", 
        operation_name = "remove",
        operator_action = 'remove',
        make = {"a.md"},
        source = "a.md",
        results = {
            ["a.md"] = function(p) assert.falsy(Path.exists(p)) end,
        },
    },
    {
        operator_action = 'move',
        operation_class = "file", 
        operation_name = "rename",
        subtests = {
            ["Path.exists(target)"] = {make = {"a.md", "b.md"}},
            ["! Path.exists(target)"] = {make = {"a.md"}},
        },
        source = "a.md",
        target = "b.md",
        transformed_target = "b.md",
        map = {["a.md"] = "b.md"},
        results = {
            ["a.md"] = function(p) assert.falsy(Path.exists(p)) end,
            ["b.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operator_action = 'move',
        operation_class = "file", 
        operation_name = "move",
        make = {"a.md", "b"},
        source = "a.md",
        target = "b",
        transformed_target = "b/a.md",
        map = {["a.md"] = "b/a.md"},
        results = {
            ["a.md"] = function(p) assert.falsy(Path.exists(p)) end,
            ["b/a.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operator_action = 'move',
        operation_class = "file", 
        operation_name = "to dir",
        make = {"a.md"},
        source = "a.md",
        target = "b",
        transformed_target = "b/@.md",
        map = {["a.md"] = "b/@.md"},
        results = {
            ["a.md"] = function(p) assert.falsy(Path.exists(p)) end,
            ["b/@.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operator_action = 'move',
        operation_class = "file", 
        operation_name = "to mark",
        subtests = {
            ["Path.exists(target)"] = {make = {"a.md", "b.md"}},
            ["! Path.exists(target)"] = {make = {"a.md"}},
        },
        source = "a.md",
        target = "b.md:c",
        transformed_target = "b.md:c",
        map = {["a.md"] = "b.md:c"},
    },
    --------------------------------------[ dir ]-------------------------------------
    {
        operator_action = 'remove',
        operation_class = "dir", 
        operation_name = "remove",
        source = "a",
        make = {"a", "a/b.md"},
        results = {
            a = function(p) assert.falsy(Path.exists(p)) end,
        },
    },
    {
        operator_action = 'move',
        operation_class = "dir", 
        operation_name = "rename",
        source = "a",
        target = "b",
        make = {"a", "a/c.md"},
        transformed_target = "b",
        map = {["a/c.md"] = "b/c.md"},
        results = {
            a = function(p) assert.falsy(Path.exists(p)) end,
            b = function(p) assert(Path.is_dir(p)) end,
            ["b/c.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operator_action = 'move',
        operation_class = "dir", 
        operation_name = "move",
        source = "a",
        target = "b",
        make = {"a", "b", "a/c.md"},
        transformed_target = "b/a",
        map = {["a/c.md"] = "b/a/c.md"},
        results = {
            a = function(p) assert.falsy(Path.exists(p)) end,
            ["b/a/c.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    {
        operator_action = 'move',
        operation_class = "dir", 
        operation_name = "to files",
        source = "a/b",
        target = "a",
        make = {"a", "a/b", "a/b/@.md", "a/b/c.md"},
        transformed_target = "a",
        map = {["a/b/@.md"] = "a/b.md", ["a/b/c.md"] = "a/c.md"},
        results = {
            ["a/b"] = function(p) assert.falsy(Path.exists(p)) end,
            ["a/b.md"] = function(p) assert(Path.is_file(p)) end,
            ["a/c.md"] = function(p) assert(Path.is_file(p)) end,
        },
    },
    ------------------------------------[ mark ]------------------------------------
    {
        operator_action = 'remove',
        operation_class = "mark", 
        operation_name = "remove",
        source = "a.md:b",
        make = {"a.md"},
    },
    {
        operator_action = 'move',
        operation_class = "mark", 
        operation_name = "move",
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
        operator_action = 'move',
        operation_class = "mark", 
        operation_name = "to file",
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
        operator_action = 'move',
        operation_class = "mark", 
        operation_name = "to dir",
        source = "a.md:b",
        target = "c",
        make = {"a.md"},
        transformed_target = "c/@.md",
        map = {["a.md:b"] = "c/@.md"},
    },
    {
        operator_action = 'move',
        operation_class = "mark", 
        operation_name = "to dir file",
        source = "a.md:b",
        target = "c",
        make = {"a.md", "c"},
        transformed_target = "c/b.md",
        map = {["a.md:b"] = "c/b.md"},
    }
}

before_each(function()
    Path.rmdir(test_dir, true)
    stub(Project, 'root_from_path')
    Project.root_from_path.returns(test_dir)
end)

after_each(function()
    Path.rmdir(test_dir, true)
    Project.root_from_path:revert()
end)

describe("operations", function()
    for _, spec in ipairs(operation_tests) do
        if not operation_class_to_test or operation_class_to_test == spec.operation_class then
            if not operation_to_test or operation_to_test == spec.operation_name then
                run_operation_test(spec)
            end
        end
    end
end)
