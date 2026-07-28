local M = {}

function M.open(args)
    if args and args.word then
        local word = args.word
        
        if word:startswith("-") and word:endswith("-") then
            word = word:removeprefix("-")
            word = "*" .. word
        end

        local url = Path("https://www.etymonline.com") / "word" / word
        os.execute(string.format("open %s", tostring(url)))
    end
end

return M
