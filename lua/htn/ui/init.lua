local Link = require("htl.text.Link")
local Document = require("htl.text.Document")
local Mirrors = require("htl.Mirrors")

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
function M.get_cursor(args)
    args = args or {}

    local c = {}
    c.row, c.col = unpack(vim.api.nvim_win_get_cursor(args.window or 0))
    return c
end

function M.set_cursor(args)
    args = Dict(
        args,
        {
            buffer = 0,
            row = 1,
            col = 0,
            center = true,
            insert = false,
        }
    )

    local cur_pos = M.get_cursor()

    if args.row ~= cur_pos.row or args.col ~= cur_pos.col then
        vim.api.nvim_win_set_cursor(args.buffer, {args.row, args.col})
    end

    if args.center then
        vim.cmd("normal zz")
    end
end

function M.get_cursor_line()
    local row = M.get_cursor().row
    return vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
end

function M.set_cursor_line(lines)
    local row = M.get_cursor().row
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, List.as_list(lines):transform(tostring))
end

function M.get_selection(args)
    return List(vim.api.nvim_buf_get_lines(unpack(M._get_selection_args(args))))
end

function M.set_selection(args)
    vim.api.nvim_buf_set_lines(unpack(M._get_selection_args(args)))
end

function M._get_selection_args(args)
    args = Dict(args or {}, {buffer = 0, strict_indexing = false})
    local start, stop

    if args.mode == 'v' then
        vim.api.nvim_input('<esc>')
        start = math.max(0, vim.api.nvim_buf_get_mark(args.buffer, '<')[1] - 1)
        stop = vim.api.nvim_buf_get_mark(args.buffer, '>')[1]
    else
        stop = M.get_cursor().row
        start = stop - 1
    end

    return {args.buffer, start, stop, args.strict_indexing, args.lines}
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
    local buffer = vim.api.nvim_get_current_buf()
    M.sections.clear(buffer)

    vim.b.htn_modified = true

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
        DB.Metadata.record(DB.urls.get_file(path))
    end

    vim.b.htn_modified = false

    -- vim.cmd("noautocmd silent! mkview")
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
    elseif DB.urls.get_file(path) then
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
        vim.b.url_id = DB.urls:insert({path = path})
    end
end

function M.goto_map_fn(open_cmd)
    return function()
        local col = M.get_cursor().col
        local line = vim.fn.getline('.')
        local path = Path.from_cli(line:strip())

        if path:exists() then
            path:open(open_cmd)
        else
            local url = Link:get_nearest(line, col).url

            if url then
                if Path.is_url(url) then
                    os.execute(string.format("open %s", url))
                else
                    url = DB.urls:where({id = url})
                    if url and url.path ~= Path.this() then
                        url.path:open(open_cmd)
                    end
                end
            end
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
    local lines = M.get_selection({mode = mode})
    M.set_selection({mode = mode, lines = {}})

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

function M.quote(page_number)
    local text = Conf.snippets.quote.template

    local path = Path.this():parent() / Conf.paths.dir_file
    local source = DB.urls:get_reference(DB.urls.get_file(path))

    text = text:gsub("$1", source and tostring(source) or "")
    text = text:gsub("$2", page_number or "")
    text = text:rstrip():gsub("$3", "")

    local lines = text:split("\n")

    local line
    line = not source and 2
    line = line or not page_number and 3
    line = line or #lines

    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

    M.set_cursor({row = line})
    vim.api.nvim_input("A")
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

function M.copy_wordcount()
    vim.fn.setreg("+", Document({path = Path.this()}).wordcount)
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

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 treesitter                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.ts = {}

function M.ts.get_root(language)
    language = language or 'markdown'

    local root
    vim.treesitter.get_parser():for_each_tree(function(tree, language_tree)
        if not root and language_tree:lang() == language then
            root = tree:root()
        end
    end)

    return root
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  sections                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.sections = {}

function M.sections.clear(buffer)
    M.sections[buffer] = nil
end

function M.sections.get()
    local query = vim.treesitter.query.parse(
        "markdown",
        [[
            [
                (atx_heading)
                (thematic_break)
            ] @hne_section
        ]]
    )

    local sections = List({1})
    for _, node in query:iter_captures(M.ts.get_root()) do
        sections:append(node:start() + 1)
    end

    return sections:append(vim.fn.line('$'))
end

function M.sections.goto(direction)
    local buffer = vim.api.nvim_get_current_buf()
    M.sections[buffer] = M.sections[buffer] or M.sections.get()

    local sections = M.sections[buffer]

    local row = M.get_cursor().row

    if direction == 1 then
        sections = sections:filter(function(hi) return hi > row end)
    else
        sections = sections:filter(function(hi) return hi < row end):reverse()
    end

    if #sections > 0 then
        M.set_cursor({row = sections[1]})
    end
end

function M.sections.next() M.sections.goto(1) end
function M.sections.prev() M.sections.goto(-1) end

return M
