local Path = require("hl.Path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local class = require("pl.class")

class.DataFrame()

function DataFrame.to_csv(rows, path, args)
    args = Dict.from(args or {}, {cols = {}, sep = ','})

    rows = List(rows):clone()
    cols = args.cols
    sep = args.sep

    if #cols == 0 then
        cols = Dict(rows[1]):keys()
    end

    cols = List(cols)

    rows:put(Dict.fromlist(cols:map(function(c) return {[c] = c} end)))
    rows:transform(function(r) return cols:map(function(c) return r[c] end):join(sep) end)

    local col_row = rows:pop(1)
    rows:sort()
    rows:put(col_row)

    Path(path):write(rows)
end

return DataFrame
