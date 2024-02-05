local Path = require("hn.path")
local List = require("hl.List")
local db = require("htl.db")
local Link = require("htl.text.Link")
local URLDefinition = require("htl.text.URLDefinition")
local BufferLines = require("hn.buffer_lines")

local mirrors = db.get().mirrors
local urls = db.get().urls

local M = {}

function M.get_statusline_path_string(path, project_root)
    if mirrors:is_mirror(path) then
        local mirror = mirrors:get_mirror(path)
        path = mirrors:get_source(path).path
        path = path:with_name(path:name() .. ": " .. mirrors.get_kind_string(mirror))
    end

    if path:is_relative_to(project_root) then
        path = path:relative_to(project_root)
    end

    return tostring(path)
end

function M.statusline(path, project_root)
    local statusline = M.get_statusline_path_string(path, project_root)
    local mirrors_string = mirrors:get_mirrors_string(path)

    if #mirrors_string > 0 then 
        statusline = statusline .. "%=mirrors: " .. mirrors_string
    end
    
    return statusline
end

function M.spellfile(root)
    local spellfile = root:join(".spell", "en.utf-8.add")
    spellfile:parent():mkdir()
    return tostring(spellfile)
end

function M.goto(open_command, fuzzy_path)
    local url

    if fuzzy_path then
        local project = vim.b.htn_project or {}
        url = urls:get_from_fuzzy_path(fuzzy_path, project.path)
    else
        local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
        local url_id = Link:get_nearest(vim.fn.getline('.'), cursor_col).url

        if url_id then
            url = urls:where({id = url_id})
        end
    end

    if url then
        if url.path ~= Path.this() then
            Path.open(url.path, open_command)
        end

        if url.resource_type == 'link' then
            for line_number, line in ipairs(BufferLines.get()) do
                local link = URLDefinition:from_str(line)
                if link and tonumber(link.url) == url.id then
                    vim.api.nvim_win_set_cursor(0, {line_number, 0})
                    vim.cmd("normal zz")
                    return
                end
            end
        end
    end
end

function M.get_reference(fuzzy_path)
    local project = vim.b.htn_project or {}
    local url = urls:get_from_fuzzy_path(fuzzy_path, project.path)
    return tostring(urls:get_reference(url))
end

return M
