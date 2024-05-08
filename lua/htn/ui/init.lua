local Link = require("htl.text.Link")
local URLDefinition = require("htl.text.URLDefinition")
local mirrors = require("htl.db.mirrors")
local TaxonomyParser = require("htl.Taxonomy.Parser")

local fzf = require("fzf-lua")

local BufferLines = require("hn.buffer_lines")

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
            local project = DB.projects:where({title = source.project})
            pre = string.format("[%s] ", project.title)
            relative_to = project.path
        end

        path = source.path
    elseif DB.urls:get_file(path) then
        post = mirrors:get_strings(path)

        if #post > 0 then
            post = "%=mirrors: " .. post
        end
    end

    return pre .. M.get_statusline_path(path, relative_to) .. post
end

function M.get_statusline_path(path, relative_to)
    if path:name() == tostring(Conf.paths.dir_file) then
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
        DB.urls:insert({path = path})
    end
end

function M.save_metadata()
    if vim.b.htn_modified then
        local path = Path.this()
        M.set_file_url(path)
        TaxonomyParser:record(DB.urls:get_file(path))
    end
end

function M.update_link_urls()
    if vim.b.htn_modified then
        DB.urls:update_link_urls(Path.this(), List(BufferLines.get()))
    end
end

function M.spellfile(project)
    return tostring(Conf.paths.spell_dir / string.format("%s.%s", project, Conf.paths.spell_file:name()))
end

function M.goto_url(open_command, url)
    if not url then
        return
    end

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

function M.goto(open_command)
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local url_id = Link:get_nearest(vim.fn.getline('.'), cursor_col).url

    if url_id then
        if Path(url_id):is_url() then
            os.execute(string.format("open %s", url_id))
        else
            M.goto_url(open_command, DB.urls:where({id = url_id}))
        end
    end
end

function M.goto_map_fn(open_cmd) return function() M.goto(open_cmd) end end




function M.bind_fuzzy_scope(fn, scope)
    return function(selection)
        fn(selection, scope)
    end
end

function M.fuzzy_goto_map_fn(open_command)
    return function(selection, scope)
        local dir = M.get_dir_from_fuzzy_scope(scope)
        local url = DB.urls:get_from_fuzzy_path(selection[1], dir)
        M.goto_url(open_command, url)
    end
end

function M.get_dir_from_fuzzy_scope(scope)
    if scope == "global" then
        return Path.home
    end

    return vim.b.htn_project and Path(vim.b.htn_project.path) or Path.this():parent()
end

function M.fuzzy_put(selection, scope)
    local path = selection[1]
    vim.api.nvim_put({M.get_fuzzy_reference(path, scope)} , 'c', 1, 0)
end

function M.fuzzy_insert(selection, scope)
    local path = selection[1]
    local content = M.get_fuzzy_reference(path, scope)

    local line = BufferLines.cursor.get()
    local line_number, column = unpack(vim.api.nvim_win_get_cursor(0))

    local insert_command = 'i'

    if column == #line - 1 then
        column = column + 1
        insert_command = 'a'
    elseif column == 0 then
        insert_command = 'a'
    end

    local new_line = line:sub(1, column) .. content .. line:sub(column + 1)
    local new_column = column + #content

    BufferLines.cursor.set({replacement = {new_line}})

    vim.api.nvim_win_set_cursor(0, {line_number, new_column})
    vim.api.nvim_input(insert_command)
end

function M.get_fuzzy_reference(path, scope)
    local dir = M.get_dir_from_fuzzy_scope(scope)
    local url = DB.urls:get_from_fuzzy_path(path, dir)
    return tostring(DB.urls:get_reference(url))
end

function M.map_fuzzy(operation, scope)
    return function()
        local dir = tostring(M.get_dir_from_fuzzy_scope(scope))
        
        local actions = {}
        for key, fn in pairs(M.fuzzy_operation_actions[operation]) do
            actions[key] = M.bind_fuzzy_scope(fn, scope)
        end
        
        fzf.fzf_exec(DB.urls:get_fuzzy_paths(dir), {actions = actions})
    end
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

function M.taxonomy_mappings(prefix)
    return Dict.from_list(
        Dict(Conf.Taxonomy.relations):keys(),
        function(key) return prefix .. key:sub(1, 1), Conf.Taxonomy.relations[key].symbol end
    )
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

    local source = DB.urls:get_reference(DB.urls:where({path = Path.this():parent():join(Conf.paths.dir_file)}))
    if source then
        vim.api.nvim_input(tostring(source))
        vim.api.nvim_input("<C-f>")
    end
end

function M.set_time()
    local line_number = vim.api.nvim_win_get_cursor(0)[1] - 1

    local args = List({0, line_number, line_number + 1, false})
    local line = vim.api.nvim_buf_get_lines(unpack(args))[1]
    local new_line = line:gsub("TT", tostring(os.date("%H:%M")), 1)

    args:append({new_line})

    vim.api.nvim_buf_set_lines(unpack(args))
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

--     local old_url_id = DB.urls:where({path = Path.this(), resource_type = "file"}).id
    
--     DB.urls:remove({id = old_url_id})
--     DB.urls:update({
--         where = {id = url_id},
--         set = {resource_type = "file", label = ""}
--     })
-- end

-- function M.FileToLink()
--     print("this doesn't work yet")
--     local path = Path.this()
--     local file_q = {path = path, resource_type = "file"}
--     local url = DB.urls:where(file_q)

--     DB.urls:update({
--         where = {id = url.id},
--         set = {
--             resource_type = "link",
--             label = url.path:stem():gsub("-", " "),
--         }
--     })

--     DB.urls:insert({path = path})

--     vim.api.nvim_put({tostring(DB.urls:get_reference(url))} , 'c', 1, 0)
-- end

M.scratch_map_fn = function() M.scratch('n') end
M.scratch_map_visual_cmd = [[:'<,'>lua require('htn.ui').scratch('v')<cr>]]

M.fuzzy_operation_actions = {
    goto = {
        default = M.fuzzy_goto_map_fn("edit"),
        ["ctrl-j"] = M.fuzzy_goto_map_fn("split"),
        ["ctrl-l"] = M.fuzzy_goto_map_fn("vsplit"),
        ["ctrl-t"] = M.fuzzy_goto_map_fn("tabedit"),
        -- ["ctrl-j"] = M.fuzzy_goto_map_fn("split"),
        -- ["ctrl-l"] = M.fuzzy_goto_map_fn("vsplit"),
        -- ["ctrl-t"] = M.fuzzy_goto_map_fn("tabedit"),
    },
    put = {default = M.fuzzy_put},
    insert = {default = M.fuzzy_insert},
}

return M
