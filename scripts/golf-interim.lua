require("htl")
local Parser = require("htl.Taxonomy.Parser")

local dir = Path.home / "golf-interim"
local year_list_dir = dir / "cetera" / "year-lists"

local parent_to_is_a = {
    ["year-lists"] = "year end list",
    ["playlists"] = "playlist",
}

local keys = List()
dir:iterdir({dirs = false}):sorted(function(a, b)
    return tostring(a) < tostring(b)
end):foreach(function(path)
    local p = path:relative_to(dir)
    local raw_meta = Parser.get_metadata_lines(path)
    local text = path:readlines():chop(1, #raw_meta):filter(function(l)
        return l:strip() ~= "---"
    end):join("\n"):strip()
    
    local meta = List()
    local tags = List()
    raw_meta:foreach(function(l)
        if l:match(": ") then
            local key, val = utils.parsekv(l)
            
            if key == "title" then
                meta:append(utils.formatkv("label", val))
            elseif key == "date" then
                val = val:gsub("%-", "")
            elseif key == "tags" then
                val:removeprefix("["):removesuffix("]"):split(","):mapm("strip"):foreach(function(tag)
                    tags:append(string.format("@%s", tag))
                end)
            else
                keys:append(key)
                meta:append(l)
            end
        elseif l:startswith("@") then
            tags:append(l)
        end
    end)
    
    meta = meta:filter(function(l) return not l:startswith("kind: ") end)
    tags = tags:filter(function(t) return t ~= "@year-end" end)
    
    tags:append("@dotgolf")
    
    if not meta[1]:startswith("is a") then
        local parent = tostring(path:parent():relative_to(dir))
        local is_a = parent_to_is_a[parent]
        
        if is_a then
            meta:put(utils.formatkv("is a", is_a))
        else
            print(p)
            os.exit()
        end
    end

    meta:extend(Set(tags):vals():sorted())

    text = List({meta:join("\n"), "", text}):join('\n') .. "\n"
    
    if text ~= path:read() then
        path:write(text)
    end
end)

local created_dates = Dict({
    ['cetera/thesis-slides.md'] = '20230719',
    ['cetera/year-lists/2014-music.md'] = '20150102',
    ['cetera/year-lists/2015-books.md'] = '20160104',
    ['cetera/year-lists/2015-music.md'] = '20160104',
    ['cetera/year-lists/2016-books.md'] = '20170101',
    ['cetera/year-lists/2016-music.md'] = '20170101',
    ['cetera/year-lists/2017-books.md'] = '20180101',
    ['cetera/year-lists/2017-music.md'] = '20180101',
    ['cetera/year-lists/2018-books.md'] = '20190101',
    ['cetera/year-lists/2018-music.md'] = '20190101',
    ['cetera/year-lists/2019-books.md'] = '20200101',
    ['cetera/year-lists/2019-music.md'] = '20200101',
    ['cetera/year-lists/2020-books.md'] = '20210101',
    ['cetera/year-lists/2020-music.md'] = '20210101',
    ['cetera/year-lists/2021-books.md'] = '20220101',
    ['cetera/year-lists/2021-music.md'] = '20220101',
    ['cetera/year-lists/2022-books.md'] = '20230101',
    ['cetera/year-lists/2022-music.md'] = '20230101',
    ['cetera/year-lists/2023-books.md'] = '20240101',
    ['cetera/year-lists/2023-music.md'] = '20240101',
    ['essays/Headphones-and-Honesty.md'] = '20140914',
    ['essays/The-Case-For-Groups.md'] = '20140908',
    ['essays/Want-and-the-Limits-of-Time.md'] = '20140829',
    ['essays/What-Makes-a-Big-Jump.md'] = '20141014',
    ['papers/Device-Agnostic-Wi-Fi-Positioning.md'] = '20150830',
    ['papers/Gender-and-retention-patterns-among-US-faculty.md'] = '20240110',
    ['papers/Labor-advantages-drive-the-greater-productivity-of-faculty-at-elite-universities.md'] = '20221118',
    ['papers/Quantifying-hierarchy-and-dynamics-in-US-faculty-hiring-and-retention.md'] = '20220921',
    ['papers/Subfield-prestige-and-gender-inequality-among-us-computing-faculty.md'] = '20221122',
    ['papers/webweb.md'] = '20190130',
    ['playlists/Above-the-Tropics.md'] = '20150805',
    ['playlists/August-Music.md'] = '20140829',
    ['playlists/Circle-Music.md'] = '20140919',
    ['playlists/Faster-Miles-an-Hour.md'] = '20180430',
    ['playlists/Fela-Kuti.md'] = '20180612',
    ['playlists/Nightingale-Music.md'] = '20141211',
    ['playlists/Parquet_Courts.md'] = '20180612',
    ['playlists/Sharp-Music.md'] = '20140815',
    ['playlists/Slappin-Music.md'] = '20140905',
    ['playlists/Washout-Music.md'] = '20151125',
    ['poetry/trainsway-1.md'] = '20150818',
    ['poetry/trainsway-2.md'] = '20230223',
    ['prose/A-Memory.md'] = '20150715',
    ['prose/Fog-Image.md'] = '20170101',
    ['prose/Retraining-Birdingdogs.md'] = '20191121',
    ['prose/The-Burnt/chapter-one.md'] = '20231022',
    ['prose/The-Burnt/chapter-two.md'] = '20231023',
})

created_dates:foreach(function(key, val)
    local path = dir / key
    local url = DB.urls:get_file(path)
    Dict.print(url)
    -- DB.urls:update({
    --     where = {id = url.id},
    --     set = {created = val, modified = val},
    -- })
end)
