local Object = require("hneutil.object")

local Path = require("hneutil.path")

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
        to_dir = {
            check_target = Operation.could_be_dir,
            transform_target = Operation.dir_file_of,
        },
        to_mark = {
            check_target = Operation.is_mark,
            map_mirrors = FileOperation.to_mark.map_mirrors,
            process = FileOperation.to_mark.process,
            update_references = FileOperation.to_mark.update_references,
            -- does:
            -- - appends source content to target:mark content
            -- - appends source mirrors to target mirrors
            -- - points source references at target:mark
        },
    },
    dir = {
        rename = {check_target = Operation.could_be_dir},
        move = {
            check_target = Operation.dir_is_not_parent_of,
            transform_target = Operation.make_parent_of,
        },
        to_files = {
            check_target = Operation.is_parent_of,
            map_source_to_target = DirOperation.to_files.map_source_to_target,
        },
    },
    mark = {
        -- does:
        -- - removes source:mark content from source
        -- - appends source:mark content to target
        -- - points source:mark references at target
        move = {check_target = Operation.is_mark},
        to_file = {check_target = Operation.could_be_file},
        to_dir = {
            check_target = Operation.could_be_dir,
            transform_target = Operation.dir_file_of,
        },
        to_dir_file = {
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

        for action, action_args in pairs(actions) do
            if action_args.check_target(target, source) then
                return OperationClass(action_args)
            end
        end
    end

    return nil
end

function M.operate(source, target, args)
    M.get_action(source, target):operate(source, target, args)
end

return M
