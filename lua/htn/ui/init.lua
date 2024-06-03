local fzf = require("fzf-lua")

local Link = require("htl.text.Link")
local Line = require("htl.text.Line")
local URLDefinition = require("htl.text.URLDefinition")
local Mirrors = require("htl.Mirrors")
local TaxonomyParser = require("htl.Taxonomy.Parser")
local Fold = require("htl.text.Fold")

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

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   utils                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.set_cursor(args)
    args = args or {}

    vim.api.nvim_win_set_cursor(
        args.buffer or 0,
        {
            args.row or 1,
            args.col or 0,
        }
    )
    
    if args.center then
        vim.cmd("normal zz")
    end
end

function M.get_cursor(args)
    args = args or {}
    
    local c = {}
    c.row, c.col = unpack(vim.api.nvim_win_get_cursor(args.window or 0))
    return c
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   events                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.start()
    local path = Path.this()
    local project = DB.projects.get_by_path(path)

    if project then
        vim.opt_local.spellfile:append(M.spellfile(project.title))
        vim.b.htn_project_path = tostring(project.path)

        M.set_file_url(path)
    end

    vim.cmd([[
        normal zR
        noautocmd silent! loadview
    ]])
end

function M.change()
    vim.b.htn_modified = true
    M.set_foldlevels()
end

function M.enter()
    vim.opt_local.statusline = M.get_statusline()
end

function M.leave()
    if vim.b.htn_modified then
        local path = Path.this()
        
        local update_link_urls = true

        if Mirrors:is_mirror(path) then
            path = Mirrors:get_source(path)
            update_link_urls = false
        end
        
        M.set_file_url(path)

        TaxonomyParser:record(DB.urls:get_file(path))
        
        if update_link_urls then
            DB.urls:update_link_urls(path, BufferLines.get())
        end
    end
    
    vim.b.htn_modified = false
    
    vim.cmd("noautocmd silent! mkview")
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  helpers                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.get_statusline()
    local path = Path.this()
    local pre = ""
    local post = ""
    local relative_to = vim.b.htn_project_path
    
    if Mirrors:is_mirror(path) then
        post = "%=mirror: " .. Conf.mirror[Mirrors:get_kind(path)].statusline_str

        local source = Mirrors:get_source(path)

        if source.project then
            local project = DB.projects:where({title = source.project})
            pre = string.format("[%s] ", project.title)
            relative_to = project.path
        end

        path = source.path
    elseif DB.urls:get_file(path) then
        post = Mirrors:get_strings(path)

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
    if path:exists() and DB.urls.should_track(path) then
        DB.urls:insert({path = path})
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

    if url.type == 'link' then
        for line_number, line in ipairs(BufferLines.get()) do
            local link = URLDefinition:from_str(line)
            if link and tonumber(link.url) == url.id then
                M.set_cursor({row = line_number, center = true})
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

    return vim.b.htn_project_path and Path(vim.b.htn_project_path) or Path.this():parent()
end

function M.fuzzy_put(selection, scope)
    local path = selection[1]
    vim.api.nvim_put({M.get_fuzzy_reference(path, scope)} , 'c', 1, 0)
end

function M.fuzzy_insert(selection, scope)
    local path = selection[1]
    local reference = M.get_fuzzy_reference(path, scope)

    local cursor = vim.fn.getpos('.')
    local col = cursor[3]

    local line = vim.fn.getline('.')
    line, cursor[3] = Line.insert_at_pos(line, col, reference)
    
    vim.fn.setline('.', line)

    vim.fn.setpos('.', cursor)
    vim.api.nvim_input(cursor[3] > #line and 'a' or 'i')
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
        Conf.mirror:keys():foreach(function(kind)
            M.suffix_to_open_cmd:foreach(function(suffix, open_cmd)
                mappings[vim.g.htn_mirror_prefix .. Conf.mirror[kind].mapkey .. suffix] = function()
                    Mirrors:get_path(Path.this(), kind):open(open_cmd)
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

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                             folds and headers                              --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.jump_to_header(direction)
    return function()
        local row = M.get_cursor().row
        local header_indexes = List(vim.b.header_indexes)
        header_indexes:put(1)
        header_indexes:append(vim.fn.line('$'))

        local candidates

        if direction == 1 then
            candidates = header_indexes:filter(function(hi) return hi > row end)
        else
            candidates = header_indexes:filter(function(hi) return hi < row end):reverse()
        end

        if #candidates > 0 then
            M.set_cursor({row = candidates[1], center = true})
        end
    end
end

function M.set_foldlevels()
    local lines = BufferLines.get()
    vim.b.fold_levels = Fold.get_fold_levels(lines)
    vim.b.header_indexes = Fold.get_header_indexes(lines)
end

function M.get_foldlevel(row)
    if not vim.b.fold_levels then
        M.set_foldlevels()
    end

    return vim.b.fold_levels[row]
end

function M.fold_operation(operation)
    return function()
        local cursor = M.get_cursor()
        local lines_from_lower = Fold.get_lower_distance()

        if lines_from_lower then
            cursor.row = cursor.row + lines_from_lower
            M.set_cursor(cursor)
        end

        vim.opt_local.foldmethod = vim.opt_local.foldmethod:get()
		vim.cmd("normal! " .. operation)

        if lines_from_lower then
            cursor.row = cursor.row - lines_from_lower
            M.set_cursor(cursor)
        end        
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  scratch                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.scratch(mode)
    local lines = BufferLines.selection.get({mode = mode})
    BufferLines.selection.set({mode = mode})

    if lines[#lines] ~= "" then
        lines:append("")
    end

    local path = Path:this()
    M.set_file_url(path)

    local scratch_path = Mirrors:get_path(path, "scratch")

    if scratch_path then
        if scratch_path:exists() then
            lines:append(scratch_path:read())
        end

        scratch_path:write(lines)
    end
end

M.scratch_map_fn = function() M.scratch('n') end
M.scratch_map_visual_cmd = [[:'<,'>lua require('htn.ui').scratch('v')<cr>]]

M.fuzzy_operation_actions = {
    goto = {
        default = M.fuzzy_goto_map_fn("edit"),
        ["ctrl-j"] = M.fuzzy_goto_map_fn("split"),
        ["ctrl-l"] = M.fuzzy_goto_map_fn("vsplit"),
        ["ctrl-t"] = M.fuzzy_goto_map_fn("tabedit"),
    },
    put = {default = M.fuzzy_put},
    insert = {default = M.fuzzy_insert},
}

return M
