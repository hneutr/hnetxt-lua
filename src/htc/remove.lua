local Path = require("hl.Path")

local db = require("htl.db")
local urls = require("htl.db.urls")
local mirrors = require("htl.db.mirrors")

local M = {}

function M.run(args)
    local path = args.path

    if path:is_dir() then
        M:remove_dir(path, args)
    else
        M:remove_file(path)
    end
end

function M:error(path, error)
    if path:is_relative_to(Path.cwd()) then
        path = path:relative_to(Path.cwd())
    end
    print(string.format("rm: %s %s", path, error))
end

function M:remove_dir(dir, args)
    if not args.directories and not args.recursive then
        return M:error(dir, "is a directory")
    end

    local files = dir:iterdir({dirs = false})

    if args.recursive then
        files:foreach(function(p)
            M:remove_file(p)
        end)

        files = {}
    end

    if #files > 0 then
        return M:error(dir, "is not empty")
    end

    dir:rmdir(true)
end

function M:remove_file(path)
    if urls:get_file(path) then
        mirrors:get_paths(path):values():foreach(function(p)
            p:unlink()
        end)
    end

    urls:remove({path = path})

    path:unlink()
end

return M
