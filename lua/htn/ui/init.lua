local fzf = require("fzf-lua")

local TermColor = require("htl.Color")
local VimColor = require("hn.Color")

local Link = require("htl.text.Link")
local Line = require("htl.text.Line")
local Heading = require("htl.text.Heading")
local Mirrors = require("htl.Mirrors")
local TaxonomyParser = require("htl.Taxonomy.Parser")

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

function M.get_cursor_line()
    local row = M.get_cursor().row
    return vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
end

function M.set_cursor_line(lines)
    local row = M.get_cursor().row
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, List.as_list(lines))
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
    
    -- currently not using folds and this is slow
    -- vim.cmd([[noautocmd silent! loadview]])
end

function M.change()
    vim.b.htn_modified = true
    M.unset_headings()
    M.set_modified_date()
end

function M.enter()
    vim.opt_local.statusline = M.get_statusline()
end

function M.leave()
    if vim.b.htn_modified then
        local path = Path.this()
        
        if Mirrors:is_mirror(path) then
            path = Mirrors:get_source(path).path
        end
        
        M.set_file_url(path)

        TaxonomyParser:record(DB.urls:get_file(path))
    end
    
    vim.b.htn_modified = false
    
    vim.cmd("noautocmd silent! mkview")
end

--------------------------------------------------------------------------------
--                                 statusline                                 --
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
        local parent = path:parent()

        if relative_to and parent == Path(relative_to) then
            relative_to = Path(relative_to):parent()
        end

        path = parent
    end

    if relative_to and path:is_relative_to(relative_to) then
        path = path:relative_to(relative_to)
    end
    
    return Path.contractuser(tostring(path:with_suffix("")))
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  helpers                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.set_file_url(path)
    path = path or Path.this()
    if path and path:exists() and DB.urls.should_track(path) then
        DB.urls:insert({path = path})

        local url = DB.urls:get_file(path) or {}

        vim.b.url_id = url.id
    end
end

function M.goto_url(open_command, url)
    if not url then
        return
    end

    if url.path ~= Path.this() then
        url.path:open(open_command)
    end
end

function M.goto_map_fn(open_cmd)
    return function()
        local url = Link:get_nearest(vim.fn.getline('.'), M.get_cursor().col).url

        if url then
            if Path(url):is_url() then
                os.execute(string.format("open %s", url))
            else
                M.goto_url(open_cmd, DB.urls:where({id = url}))
            end
        end
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   fuzzy                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
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
            actions[key] = function(selection) fn(selection, scope) end
        end
        
        fzf.fzf_exec(DB.urls:get_fuzzy_paths(dir), {actions = actions})
    end
end

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

function M.fuzzy_headings()
    M.set_headings()

    fzf.fzf_exec(
        vim.b.headings,
        {
            actions = {
                default = function(s)
                    M.set_cursor({row = vim.b.heading_lines[s[1]:strip()], center = true})
                end
            },
        }
    )
end

function M.jump_to_division(direction)
    return function()
        M.set_headings()
        local row = M.get_cursor().row
        local heading_indexes = List(vim.b.heading_indexes)
        heading_indexes:put(1)
        heading_indexes:append(vim.fn.line('$'))

        local candidates

        if direction == 1 then
            candidates = heading_indexes:filter(function(hi) return hi > row end)
        else
            candidates = heading_indexes:filter(function(hi) return hi < row end):reverse()
        end

        if #candidates > 0 then
            M.set_cursor({row = candidates[1]})
        end
    end
end

function M.set_headings()
    if vim.b.headings then
        return
    end
    
    local headings = List()
    local heading_lines = Dict()
    local heading_indexes = List()
    for i, line in ipairs(BufferLines.get()) do
        if Heading.str_is_a(line) then
            local heading = Heading.from_str(line, i)
            
            headings:append(heading:fuzzy_str())
            heading_lines[heading.str] = i
            heading_indexes:append(i)
        elseif line == "---" then
            heading_indexes:append(i)
        end
    end
    
    vim.b.headings = headings
    vim.b.heading_lines = heading_lines
    vim.b.heading_indexes = heading_indexes
end

function M.unset_headings()
    vim.b.headings = nil
    vim.b.heading_lines = nil
    vim.b.heading_indexes = nil
end

function M.change_heading_level(change)
    return function()
        local line = M.get_cursor_line()
        
        if Heading.str_is_a(line) then
            local heading = Heading.from_str(line)
            heading.level = heading.level + change
            M.set_cursor_line(tostring(heading))
        end
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   folds                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.get_foldlevel()
    return 0
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

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    misc                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.spellfile(project)
    return tostring(Conf.paths.spell_dir / string.format("%s.%s", project, Conf.paths.spell_file:name()))
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

function M.quote(page_number)
    vim.api.nvim_input("iquote<tab>")

    local path = Path.this():parent() / Conf.paths.dir_file
    local source = DB.urls:get_reference(DB.urls:where({path = path}))

    if source then
        vim.api.nvim_input(tostring(source))
        vim.api.nvim_input("<C-f>")
        
        if page_number then
            vim.api.nvim_input(tostring(page_number))
            vim.api.nvim_input("<C-f>")
        end
    end
end

function M.set_time_or_calculate_sum()
    local row = M.get_cursor().row
    local args = List({0, row - 1, row, false})

    local line = vim.api.nvim_buf_get_lines(unpack(args))[1]
    local new_line
    
    if line:match("TT") then
        new_line = line:gsub("TT", tostring(os.date("%H:%M")), 1)
    else
        local key, val = utils.parsekv(line)
        
        local fn = string.format([[return function() return %s end]], val)

        if pcall(function() val = loadstring(fn)()() or val end) then
            new_line = string.format("%s: %s", key, tostring(val))
        end
    end

    if new_line then
        args:append({new_line})
        vim.api.nvim_buf_set_lines(unpack(args))
    end
end

function M.copy_wordcount_to_clipboard()
    local words = vim.fn.wordcount()['cursor_words']
    vim.fn.setreg("+", words)
end

function M.set_modified_date()
    local id = vim.b.url_id

    if id then
        local today = os.date("%Y%m%d")

        local modified_date = vim.b.url_modified_date

        if not modified_date or modified_date ~= today then
            DB.urls:update({
                where = {id = id},
                set = {modified = today}
            })
        end
        
        vim.b.url_modified_date = today
    end
end

return M
