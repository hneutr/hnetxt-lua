table = require("hneutil.table")
local Object = require("hneutil.object")

local Path = require("hneutil.path")

local Project = require("hnetxt-lua.project")
local Operation = require("hnetxt-lua.project.move.operation")
local FileOperation = require("hnetxt-lua.project.move.operation.file")
local DirOperation = require("hnetxt-lua.project.move.operation.dir")
local MarkOperation = require("hnetxt-lua.project.move.operation.mark")

local M = {}

M.source_type_to_operation_class = {
    file = FileOperation,
    dir = DirOperation,
    mark = MarkOperation,
}

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  actions                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
-- notation:
--     - `a.md`: there is a file named "a.md"
--     - `a`: there is a directory named "a"
--     - `a!`: a doesn't exist
--     - `a?`: exists or doesn't
-- behaviors:
--     file:
--         - rename:      a.md     → b.md?   = b.md
--         - move:        a.md     → b       = b/a.md
--         - to dir:      a.md     → b!      = b/@.md
--         - to mark:     a.md     → b.md:c? = b.md:c
--     dir:
--         - rename:      a        → b!      = b
--         - move:        a        → b       = b/a
--         - to files:    a/b      → a       = a/*
--                        a/b/@.md           = a/b.md
--                        a/b/c.md           = a/c.md
--     mark:
--         - move:        a.md:b   → c.md:d? = c.md:d
--         - to file:     a.md:b   → c.md?   = c.md
--         - to dir:      a.md:b   → c!      = c/@.md
--         - to dir file: a.md:b   → c       = c/b.md
--------------------------------------------------------------------------------
M.actions = {
    file = {
        rename = {check_target = Operation.could_be_file},
        move = {
            check_target = Path.is_dir,
            transform_target = Operation.make_parent_of,
        },
        ["to dir"] = {
            check_target = Operation.could_be_dir,
            transform_target = Operation.dir_file_of,
        },
        ["to mark"] = {
            check_target = Operation.is_mark,
            map_mirrors = FileOperation.to_mark.map_mirrors,
            process = FileOperation.to_mark.process,
            update_references = FileOperation.to_mark.update_references,
        },
    },
    dir = {
        rename = {check_target = Operation.could_be_dir},
        move = {
            check_target = Operation.dir_is_not_parent_of,
            transform_target = Operation.make_parent_of,
        },
        ["to files"] = {
            check_target = Operation.is_parent_of,
            map_source_to_target = DirOperation.to_files.map_source_to_target,
        },
    },
    mark = {
        move = {check_target = Operation.is_mark},
        ["to file"] = {check_target = Operation.could_be_file},
        ["to dir"] = {
            check_target = Operation.could_be_dir,
            transform_target = Operation.dir_file_of,
        },
        ["to dir file"] = {
            check_target = Path.is_dir,
            transform_target = MarkOperation.to_dir_file.transform_target,
        },
    },
}

function M.get_action_by_name(source_type, action_name)
    local OperationClass = M.source_type_to_operation_class[source_type]
    return OperationClass(OperationClass.actions[action_name])
end

function M.get_operation_class_name(source)
    for name, OperationClass in pairs(M.source_type_to_operation_class) do
        if OperationClass.check_source(source) then
            return name
        end
    end

    return nil
end

function M.get_operation_class(source)
    local name = M.get_operation_class_name(source)
    if name then
        return M.source_type_to_operation_class[name]
    end

    return nil
end

function M.get_action(source, target)
    local operation_class_name = M.get_operation_class_name(source)

    if operation_class_name then
        local OperationClass = M.source_type_to_operation_class[operation_class_name]
        local actions = M.actions[operation_class_name]

        for action_name, action_args in pairs(actions) do
            local action = table.default(
                {action_name = action_name, operation_name = operation_name},
                action_args,
                OperationClass
            )

            if action.check_target(target, source) then
                return action
            end
        end
    end

    return nil
end

function M.operate(source, target)
    local action = M.get_action(source, target)

    local dir = Project.root_from_path(source)

    target = action.transform_target(target, source)
    local map = action.map_source_to_target(source, target)

    local mirrors_map = action.map_mirrors(map)

    action.process(map, mirrors_map)
    action.update_references(map, mirrors_map, dir)
end

return M
