io = require("hl.io")
string = require("hl.string")

local class = require("pl.class")

local Path = require("hl.path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local db = require("htl.db")
local Urls = require("htl.db.urls")

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

function M:update(moves)
    moves:foreach(function(move)
        Urls:move(move.source, move.target)
    end)
end

return M
