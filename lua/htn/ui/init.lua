local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")

local db = require("htl.db")
local Link = require("htl.text.Link")
local URLDefinition = require("htl.text.URLDefinition")

local BufferLines = require("hn.buffer_lines")

local urls = require("htl.db.urls")
local mirrors = require("htl.db.mirrors")

local M = {}

M.suffix_to_open_cmd = Dict({
    e = 'e',
    o = 'e',
    l = 'vs',
    v = 'vs',
    j = 'sp',
    s = 'sp'
})

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

function M.statusline()
    vim.g.blah = 1
    local path = Path.this()
    local project_root = Path(vim.b.htn_project.path)
    local statusline = M.get_statusline_path_string(path, project_root)
    local mirrors_string = mirrors:get_mirrors_string(path)

    if #mirrors_string > 0 then 
        statusline = statusline .. "%=mirrors: " .. mirrors_string
    end
    
    return statusline
end

function M.set_file_url(path)
    path = path or Path.this()
    if mirrors:is_source(path) then
        urls:add_if_missing(path)
    end
end

function M.update_link_urls()
    urls:update_link_urls(Path.this(), List(BufferLines.get()))
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

function M.goto_map_fn(open_cmd) return function() M.goto(open_cmd) end end

function M.get_reference(fuzzy_path)
    local project = vim.b.htn_project or {}
    local url = urls:get_from_fuzzy_path(fuzzy_path, project.path)
    return tostring(urls:get_reference(url))
end

function M.LinkToFile()
    print("this doesn't work yet")
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local url_id = URLDefinition:get_nearest(vim.fn.getline('.'), cursor_col).url

    if url_id then
        url_id = tonumber(url_id)
    else
        return
    end

    local old_url_id = urls:where({path = Path.this(), resource_type = "file"}).id
    
    if mirrors:where({url = old_url_id}) then
        mirrors:update({
            where = {url = old_url_id},
            set = {url = url_id}
        })
    end

    urls:remove({id = old_url_id})
    urls:update({
        where = {id = url_id},
        set = {resource_type = "file", label = ""}
    })
end

function M.FileToLink()
    print("this doesn't work yet")
    local path = Path.this()
    local file_q = {path = path, resource_type = "file"}
    local url = urls:where(file_q)

    urls:update({
        where = {id = url.id},
        set = {
            resource_type = "link",
            label = url.path:stem():gsub("-", " "),
        }
    })

    urls:add_if_missing(path)

    if mirrors:where({url = url.id}) then
        mirrors:update({
            where = {url = url.id},
            set = {url = urls:where(file_q).id}
        })
    end
    
    vim.api.nvim_put({tostring(urls:get_reference(url))} , 'c', 1, 0)
end

function M.mirror_mappings()
    if not vim.g.htn_mirror_mappings then
        local mappings = Dict()
        db.get().mirrors.configs.generic:foreach(function(kind, conf)
            M.suffix_to_open_cmd:foreach(function(suffix, open_cmd)
                mappings[vim.b.htn_mirror_prefix .. conf.mapkey .. suffix] = function()
                    db.get().mirrors:get_mirror_path(Path.this(), kind):open(open_cmd)
                end
            end)
        end)

        vim.g.htn_mirror_mappings = mappings
    end

    return Dict(vim.g.htn_mirror_mappings)
end

function M.scratch(mode)
    local lines = List(BufferLines.selection.get({mode = mode}))
    BufferLines.selection.cut({mode = mode})

    if lines[#lines] ~= "" then
        lines:append("")
    end

    local path = db.get().mirrors:get_mirror_path(Path.this(), "scratch")

    if path:exists() then
        lines:append(path:read())
    end

    path:write(lines)
end

M.scratch_map_fn = function() M.scratch('n') end
M.scratch_map_visual_cmd = [[:'<,'>lua require('htn.ui').scratch('v')<cr>]]

return M