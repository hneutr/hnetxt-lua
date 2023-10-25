local Track = require("htl.track")

return {
    description = "touch and return a tracking path.",
    {
        "date",
        description = "date (YYYYMMDD); default today",
        default = os.date('%Y%m%d'),
    },
    action = function(args)
        -- local tracker = Track()
        -- local word_log_path = require("htl.config").data_dir:join('logs', 'word-count.md')
        -- local lines = word_log_path:readlines()
        -- -- lines = List({lines[1]})
        -- lines:foreach(function(l)
        --     if #l > 0 then
        --         local date, count = unpack(l:removeprefix("- "):split(": "))
        --         date = tonumber(date)
        --         count = tonumber(count)
        --         tracker:list_path(date):write({tracker:activity_to_list_line("word count", count)})
        --     end
        -- end)

        -- Track():create_csv()
        print(Track():touch(args.date))
    end,
}
