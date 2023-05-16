table = require("hl.table")
local Object = require("hl.object")

local Path = require("hl.path")

local Project = require("htl.project")
local Operation = require("htl.operator.operation")
local FileOperation = require("htl.operator.operation.file")
local DirOperation = require("htl.operator.operation.dir")
local MarkOperation = require("htl.operator.operation.mark")

local M = {}

M.operation_classes = {
    FileOperation,
    DirOperation,
    MarkOperation,
}

M.source_type_to_operation_class = {
    file = FileOperation,
    dir = DirOperation,
    mark = MarkOperation,
}

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 operations                                 --
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
M.operations = {
    file = {
        remove = {check_target = Operation.is_nil},
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
            move = FileOperation.to_mark.move,
            update_references = FileOperation.to_mark.update_references,
        },
    },
    dir = {
        remove = {check_target = Operation.is_nil},
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
        remove = {check_target = Operation.is_nil},
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

function M.get_operation_class(source)
    for _, OperationClass in ipairs(M.operation_classes) do
        if OperationClass.check_source(source) then
            return OperationClass
        end
    end
end

function M.get_operation(source, target)
    local OperationClass = M.get_operation_class(source)

    if target then
        for operation_name, operation_args in pairs(M.operations[OperationClass.type]) do
            local operation = table.default(
                {operation_name = operation_name},
                operation_args,
                OperationClass
            )

            if operation.check_target(target, source) then
                return operation
            end
        end
    else
        return table.default(
            {operation_name = 'remove'},
            {},
            OperationClass
        )
    end

    return nil
end

function M.move(source, target)
    local operation = M.get_operation(source, target)
    local dir = Project.root_from_path(source)

    target = operation.transform_target(target, source)
    local map = operation.map_source_to_target(source, target)

    -- local entries_map = operation.map_entries(map)
    local mirrors_map = operation.map_mirrors(map)

    operation.move(map, mirrors_map)
    operation.update_references(map, mirrors_map, dir)
end

function M.remove(source)
    local operation = M.get_operation_class(source)
    local dir = Project.root_from_path(source)

    -- local entries = operation.get_entries()
    operation.remove(source)
end

return M
