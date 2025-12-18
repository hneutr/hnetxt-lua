inspect = require("inspect")

local M = {}

function M.suite(test_fn, tests, opts)
    opts = opts or {}

    local fn = opts.pack_output and function(input) return {test_fn(input)} end or test_fn

    setfenv(1, getfenv(2))
    Dict(tests):foreach(function(name, test)
        it(name, function()
            local assert_fn = test.assert or assert.are.same

            local actual = opts.unpack_input and fn(unpack(test.input)) or fn(test.input)

            if test.expected ~= nil then
                assert_fn(test.expected, actual)
            else
                assert.is_nil(actual)
            end
        end)
    end)
end

return M
