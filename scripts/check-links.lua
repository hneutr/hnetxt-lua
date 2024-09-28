require("htl")
local urls = DB.urls:get({where = {type = "link"}})

local paths = urls:col('path')
paths:transform(tostring)
paths:sorted():foreach(print)
