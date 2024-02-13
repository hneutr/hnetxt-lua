local Parser = require("htl.metadata.Parser")

--[[
examples:

----------------------------------------

a: [label](url)

↓

a:
    value: "[label](url)"

----------------------------------------

a:
    b: c

↓

a:
    value: ""
    subvalues:
        b:
            value: c

----------------------------------------

a: b
    c: d
    e: f

↓

a:
    value: b
    subvalues:
        c:
            value: d
        e:
            value: f

----------------------------------------

a: b
    @c

↓

a:
    value: b
    tags:
        - c
]]

describe("1", function()
    
end)
