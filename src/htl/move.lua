io = require("hl.io")
string = require("hl.string")

local class = require("pl.class")

local Path = require("hl.path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local db = require("htl.db")

class.Move()
Move.command_str = "/bin/mv -v"
Move.separator = " -> "

function Move:_init(source, target)
    self.moves = self:run(source, target)
    self.update(self.moves)
end

function Move:command(source, target)
    return List({
        self.command_str,
        Path(source):resolve(),
        Path(target):resolve(),
    }):join(" ")
end

function Move:run(source, target)
    local moves = List()

    io.list_command(self:command(source, target)):filter(function(line)
        return self:line_is_valid(line)
    end):foreach(function(line)
        moves:extend(self:handle_dir_move(self:parse_line(line)))
    end)

    return moves
end

function Move:line_is_valid(line)
    return line:match(string.escape(self.separator))
end

function Move:parse_line(line)
    local source, target = unpack(line:split(self.separator, 1))
    return Dict({
        source = Path(source),
        target = Path(target),
    })
end

function Move:handle_dir_move(move)
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

function Move:update(moves)
    local urls = db.get()['urls']
    moves:foreach(function(move)
        urls:move(move.source, move.target)
    end)
end

return Move
