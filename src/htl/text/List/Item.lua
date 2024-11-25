local Line = require("htl.text.Line")

local M = class(Line)
M.name = "item"
M.confs = Conf.list
M.confs_by_sigil_len = M.confs:filter(function(c)
    return c.sigil
end):sort(function(a, b)
    return #a.sigil > #b.sigil
end)

function M:__tostring()
    return List({
        self.quote,
        self.indent,
        self.sigil,
        " ",
        self.text,
    }):join()
end

function M.get_conf(key, val)
    for conf in M.confs:iter() do
        if conf[key] == val then
            return conf
        end
    end
end

function M.parse(str)
    local p = Line.parse(str)

    for conf in M.confs_by_sigil_len:iter() do
        if p.text:startswith(conf.sigil .. " ") then
            p.sigil = conf.sigil
            p.text = p.text:sub(#conf.sigil + 2)
            p.conf = conf
            return p
        end
    end

    return p
end

function M.str_is_a(s)
    return M.parse(s).sigil and true or false
end

function M.transform(lines, sigil)
    sigil = sigil or M.confs[1].sigil
    return lines:transform(function(l)
        l.sigil = sigil
        return l
    end)
end

return M
