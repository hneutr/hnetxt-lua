local Mirrors = require("htl.Mirrors")

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
    
    local projects = DB.projects:get({contains = {path = string.format("%s*", tostring(dir))}})
    
    if #projects > 0 then
        DB.projects:remove({title = projects:col('title')})
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
    if DB.urls:get_file(path) then
        Mirrors:get_paths(path):values():foreach(function(p) p:unlink() end)
    end

    DB.urls:remove({path = path})

    path:unlink()
end

return M
