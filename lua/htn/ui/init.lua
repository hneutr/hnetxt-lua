local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")

local Config = require("htl.Config")
local db = require("htl.db")
local Link = require("htl.text.Link")
local URLDefinition = require("htl.text.URLDefinition")

local BufferLines = require("hn.buffer_lines")

local urls = require("htl.db.urls")
local projects = require("htl.db.projects")
local mirrors = require("htl.db.mirrors")
local metadata = require("htl.db.metadata")

local M = {}

M.suffix_to_open_cmd = Dict({
    e = 'e',
    o = 'e',
    l = 'vs',
    v = 'vs',
    j = 'sp',
    s = 'sp'
})

function M.get_statusline()
    local path = Path.this()
    local pre = ""
    local post = ""
    local relative_to = vim.b.htn_project and vim.b.htn_project.path

    if mirrors:is_mirror(path) then
        post = "%=mirror: " .. mirrors.conf[mirrors:get_kind(path)].statusline_str

        local source = mirrors:get_source(path)

        if source.project then
            local project = projects:where({title = source.project})
            pre = string.format("[%s] ", project.title)
            relative_to = project.path
        end

        path = source.path
    elseif urls:get_file(path) then
        post = mirrors:get_strings(path)

        if #post > 0 then
            post = "%=mirrors: " .. post
        end
    end

    return pre .. M.get_statusline_path(path, relative_to) .. post
end

function M.get_statusline_path(path, relative_to)
    if path:name() == Config.paths.dir_file then
        path = path:parent()
    end

    if relative_to and path:is_relative_to(relative_to) then
        path = path:relative_to(relative_to)
    end

    return Path.contractuser(tostring(path:with_suffix("")))
end

function M.set_file_url(path)
    path = path and Path(path) or Path.this()
    if not mirrors:is_mirror(path) and path:suffix() == ".md" then
        urls:insert({path = path})
    end
end

function M.save_metadata(path)
    path = path and Path(path) or Path.this()
    M.set_file_url(path)
    metadata:save_file_metadata(path)
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
            if Path(url_id):is_url() then
                os.execute(string.format("open %s", url_id))
            else
                url = urls:where({id = url_id})
            end
        end
    end

    if url then
        if url.path ~= Path.this() then
            url.path:open(open_command)
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

function M.mirror_mappings()
    if not vim.g.htn_mirror_mappings then
        local mappings = Dict()
        mirrors.conf:foreach(function(kind, conf)
            M.suffix_to_open_cmd:foreach(function(suffix, open_cmd)
                mappings[vim.b.htn_mirror_prefix .. conf.mapkey .. suffix] = function()
                    mirrors:get_path(Path.this(), kind):open(open_cmd)
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

    local path = Path:this()
    M.set_file_url(path)

    local scratch_path = mirrors:get_path(path, "scratch")

    if scratch_path then
        if scratch_path:exists() then
            lines:append(scratch_path:read())
        end

        scratch_path:write(lines)
    end
end

function M.quote()
    vim.api.nvim_input("iquote<tab>")

    local source = urls:get_reference(urls:where({path = Path.this():parent():join(Config.paths.dir_file)}))
    if source then
        vim.api.nvim_input(tostring(source))
        vim.api.nvim_input("<C-f>")
    end
end

-- function M.LinkToFile()
--     print("this doesn't work yet")
--     local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
--     local url_id = URLDefinition:get_nearest(vim.fn.getline('.'), cursor_col).url

--     if url_id then
--         url_id = tonumber(url_id)
--     else
--         return
--     end

--     local old_url_id = urls:where({path = Path.this(), resource_type = "file"}).id
    
--     urls:remove({id = old_url_id})
--     urls:update({
--         where = {id = url_id},
--         set = {resource_type = "file", label = ""}
--     })
-- end

-- function M.FileToLink()
--     print("this doesn't work yet")
--     local path = Path.this()
--     local file_q = {path = path, resource_type = "file"}
--     local url = urls:where(file_q)

--     urls:update({
--         where = {id = url.id},
--         set = {
--             resource_type = "link",
--             label = url.path:stem():gsub("-", " "),
--         }
--     })

--     urls:insert({path = path})

--     vim.api.nvim_put({tostring(urls:get_reference(url))} , 'c', 1, 0)
-- end

M.scratch_map_fn = function() M.scratch('n') end
M.scratch_map_visual_cmd = [[:'<,'>lua require('htn.ui').scratch('v')<cr>]]

return M
