local Track = require("htl.track")

local tracker = Track()
local word_log_path = require("htl.config").data_dir:join('logs', 'word-count.md')
local lines = word_log_path:readlines()
lines:foreach(function(l)
    if #l > 0 then
        local date, count = unpack(l:removeprefix("- "):split(": "))
        date = tonumber(date)
        count = tonumber(count)
        tracker:list_path(date):write({tracker:activity_to_list_line("word count", count)})
    end
end)
