local M = {}

function M.suite(test_fn, tests, opts)
    opts = opts or {}
    setfenv(1, getfenv(2))
    Dict(tests):foreach(function(name, test)
        it(name, function()
            local assert_fn = test.assert or assert.are.same
            local actual = test_fn(test.input)

            if test.expected ~= nil then
                assert_fn(test.expected, actual)
            else
                assert.is_nil(actual)
            end
        end)
    end)
end

return M
