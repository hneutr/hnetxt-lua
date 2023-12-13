local Track = require("htl.track")

return {
    description = "touch and return a tracking path.",
    {
        "date",
        description = "date (YYYYMMDD); default today",
        default = os.date('%Y%m%d'),
    },
    action = function(args)
        local date = args.date
        if type(date) == "string" then
            if date:startswith('m') then
                date = tonumber(os.date('%Y%m%d')) - tonumber(date:removeprefix('m'))
            end
        end

        print(Track():touch(date))
    end,
}
