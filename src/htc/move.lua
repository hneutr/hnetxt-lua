local M = {}
M.command_str = "/bin/mv -v"
M.separator = " -> "

function M.run(args)
    local moves = List()
    io.list_command(
        M.command(args.source, args.target)
    ):filter(
        M.line_is_valid
    ):transform(
        M.parse_line
    ):foreach(function(l)
        moves:extend(M:handle_dir_move(l))
    end)

    moves:foreach(DB.urls.move)
end

function M.command(source, target)
    return List({M.command_str, Path(source), Path(target)}):join(" ")
end

function M.line_is_valid(line)
    return line:match(string.escape(M.separator))
end

function M.parse_line(line)
    local source, target = unpack(line:split(M.separator, 1):map(Path))
    return Dict({source = source, target = target})
end

function M:handle_dir_move(move)
    if move.target:is_dir() then
        DB.projects.move(move)

        return move.target:iterdir({dirs = false}):transform(function(target)
            return Dict({
                source = move.source / target:relative_to(move.target),
                target = target,
            })
        end)
    end

    return List({move})
end

return M
