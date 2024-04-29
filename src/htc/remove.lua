local TaxonomyParser = require("htl.Taxonomy.Parser")
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
    if DB.urls:get_file(path) then
        mirrors:get_paths(path):values():foreach(function(p) p:unlink() end)
    end

    DB.urls:get({where = {path = path}}):foreach(M.remove_links_to_dead_url)
    DB.urls:remove({path = path})

    path:unlink()
end

function M.remove_links_to_dead_url(dead_url)
    local link = DB.urls:get_reference(dead_url)
    local link_s = tostring(link)
    local label = link.label

    DB.Elements:get({where = {url = dead_url.id}}):col('id'):foreach(function(url_element_id)
        DB.Relations:get({where = {object = url_element_id}}):col('subject'):foreach(function(element_id)
            local element = DB.Elements:where({id = element_id})
            local url = DB.urls:where({id = element.url})
            local path = url.path
            local content = path:read():gsub(link_s:escape(), label)
            path:write(content)
            TaxonomyParser:record(url)
        end)
    end)

end

return M
