local M = {}
M.command_str = "/bin/mv -v"
M.separator = " -> "

function M.run(args)
    local source = args.source
    local target = args.target

    local moves = List()
    io.list_command(M:command(source, target)):filter(function(line)
        return M:line_is_valid(line)
    end):foreach(function(line)
        moves:extend(M:handle_dir_move(M:parse_line(line)))
    end)

    M:update(moves)
end

function M:command(source, target)
    return List({M.command_str, Path(source), Path(target)}):join(" ")
end

function M:line_is_valid(line)
    return line:match(string.escape(M.separator))
end

function M:parse_line(line)
    local source, target = unpack(line:split(M.separator, 1))
    return Dict({
        source = Path(source),
        target = Path(target),
    })
end

function M:handle_dir_move(move)
    local moves = List()
    if move.target:is_dir() then
        M:update_projects(move)
        move.target:iterdir({dirs = false}):foreach(function(target)
            moves:append({
                source = move.source:join(target:relative_to(move.target)),
                target = target,
            })
        end)
    else
        moves:append(move)
    end

    return moves
end

function M:update_projects(move)
    DB.projects:get({contains = {path = string.format("%s*", move.source)}}):foreach(function(project)
        local path = move.target / project.path:relative_to(move.source)
        DB.projects:update({
            where = {title = project.title},
            set = {path = tostring(path)},
        })
    end)
end

function M:update(moves)
    moves:foreach(function(move)
        DB.urls:move(move.source, move.target)
    end)
end

return M
