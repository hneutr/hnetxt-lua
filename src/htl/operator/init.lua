local Path = require("hl.path")

local db = require("htl.db")

local Operation = require("htl.operator.operation")
local FileOperation = require("htl.operator.operation.file")
local DirOperation = require("htl.operator.operation.dir")

local M = {}

M.operation_classes = {
    FileOperation,
    DirOperation,
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
            local operation = Dict.from(
                {operation_name = operation_name},
                operation_args,
                OperationClass
            )

            if operation.check_target(target, source) then
                return operation
            end
        end
    else
        return OperationClass
    end

    return nil
end

function M.move(args)
    local source = args.source
    local target = args.target
    local operation = M.get_operation(source, target)
    local dir = db.get()['projects'].get_path(source)

    target = operation.transform_target(target, source)
    local map = operation.map_source_to_target(source, target)
    local mirrors_map = operation.map_mirrors(map)

    operation.move(map, mirrors_map)
    operation.update_references(map, mirrors_map, dir)

    local urls = db.get()['urls']
    for source, target in pairs(map) do
        urls:move(source, target)
    end

    db.clean()
end

function M.remove(args)
    local source = args.source
    if Path.exists(source) then
        local operation = M.get_operation_class(source)
        operation.remove(source)
    end

    db.clean()
end

return M
