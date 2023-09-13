require("approot")("/Users/hne/lib/hnetxt-cli/")

local Path = require("hl.path")
local Registry = require("htl.project.registry")

local M = {}

function M.default_project()
    return Registry():get_entry_name(Path.cwd())
end

function M.key_val_parse(args, args_key, key_val_list)
    for _, key_val in ipairs(key_val_list) do
        local key, val

        if key_val:find("%=") then
            key, val = unpack(key_val:split('='))

            if val:find(",") then
                val = val:split(',')
            end

            if val == 'true' then
                val = true
            elseif val == 'false' then
                val = false
            end
        else
            key = key_val

            if key:endswith('-') then
                key = key:removesuffix('-')
                val = false
            elseif key:endswith('+') then
                key = key:removesuffix('+')
                val = true
            end
        end
        
        if val then
            args[args_key][key] = val
        else
            table.insert(args[args_key], key)
        end
    end
end

function M.store(value)
    return function(args, args_key)
        args[args_key] = value
    end
end

function M.store_to(value, key)
    return function(args)
        args[key] = value
    end
end

function M.store_default(value)
    return function(args, args_key)
        if not args[args_key] then
            args[args_key] = value
        end
    end
end

return M
