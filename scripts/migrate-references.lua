local Path = require("hl.path")
local List = require("hl.List")

local Reference = require("htl.text.reference")
local db = require("htl.db")
local LLink = require("htl.text.link")
local NLink = require("htl.text.NLink")
local Link = NLink.Link
local DefinitionLink = NLink.DefinitionLink

local projects = db.get().projects
local urls = db.get().urls

--[[
- use `Reference.get_referenced_locations` to find referenced locations
  - if the ref is a:
    - `file`: point the reference to the file's url
    - `mark`:
      1. make a new link
      2. point the reference to it
      3. update the mark
]]
function is_uuid(loc)
    return urls:where({id = loc}) ~= nil
end

-- function is_link_loc(loc, project)
--     if loc:match(urls.path_label_delimiter) then
--         local url, label = unpack(loc:match(urls.path_label_delimiter))
--         local path = project.path:join(loc)

--         if path:exists() then
--             return true
--         end
--     end
-- end
local caps_case = List({
    "context/people/bulgeyh-tarkenanof.md",
    "context/people/dierdre-faolain.md",
    "context/people/fennessez-janjur.md",
    "context/people/ham-knutson.md",
    "context/people/iola-yanez.md",
    "context/people/jai-janjur.md",
    "context/people/orane-cail.md",
    "context/people/walter-eisen.md",
    "context/people/yueo-heishu.md",
    "context/people/yva-cail.md",
})

function make_path(str, project)
    if str:match("%./") then
        str = str:gsub("%./", "")
    end

    if str:match("%.%./") then
        str = str:gsub("%.%./", "")
    end
    if caps_case:contains(str) then
        local p = Path(str)
        local stem = p:stem():split("-"):transform(function(s)
            return s:sub(1, 1):upper() .. s:sub(2)
        end):join("-")
        
        str = tostring(p:with_stem(stem))
    end

    return project.path:join(str)
end

function parse_link(str, url, before)
    local link = Link:from_str(str)
    link.before = link.before .. (before or "")

    if link.url == url then
        return link
    else
        str = link.after
        link.after = ""
        return parse_link(str, url, tostring(link))
    end
end

--------------------------------------------------------------------------------
--                                   worse                                    --
--------------------------------------------------------------------------------
function parse_path_loc(loc, project)
    if not loc:match(urls.path_label_delimiter) then
        local path = make_path(loc, project)
        if path:exists() then
            return path
        end
    end
end

function handle_path_locs(locs, project)
    locs:keys():sorted():foreach(function(loc)
        local url = urls:where({path = parse_path_loc(loc, project)})
        
        if url then
            Dict(locs[loc]):foreach(function(ref_path, ref_line_numbers)
                ref_path = Path(ref_path)
                local lines = ref_path:readlines()

                List(ref_line_numbers):foreach(function(line_number)
                    local link = parse_link(lines[line_number], loc)
                    link.url = url.id

                    print("before: " .. lines[line_number])
                    print("after: " .. tostring(link))

                    lines[line_number] = tostring(link)
                end)

                ref_path:write(lines)
            end)
        else
            print(string.format("couldn't find a file for: %s", loc))
        end
    end)
end

--------------------------------------------------------------------------------
--                                   better                                   --
--------------------------------------------------------------------------------
function parse_loc(loc, project)
    local l = {path = loc, raw = loc}
    if loc:match(urls.path_label_delimiter) then
        l.path, l.label = unpack(loc:split(urls.path_label_delimiter, 1))
    end

    l.path = make_path(l.path, project)

    if l.path:exists() then
        return l
    end
end

function get_loc_url(loc)
    local q = {path = loc.path}

    if loc.label ~= nil then
        q.label = loc.label
        q.resource_type = "link"
    end

    if not urls:where(q) then
        urls:insert(q)
    end

    return urls:where(q)
end

function set_link_definition(loc, url)
    local lines = loc.path:readlines()
    local definition_ln = LLink.find_label(loc.label, lines)

    local link
    if definition_ln then
        link = Link:from_str(lines[definition_ln])
    else
        link = Link({label = loc.label})
        lines:append("")
        definition_ln = #lines
    end

    link.url = ":" .. url.id .. ":"
    lines[definition_ln] = tostring(link)
    loc.path:write(lines)
end

function handle_link_loc(loc, refs)
    local url = get_loc_url(loc)
    set_link_definition(loc, url)
    
    Dict(refs):foreach(function(ref_path, ref_line_numbers)
        ref_path = Path(ref_path)
        print(ref_path)
        local lines = ref_path:readlines()

        List(ref_line_numbers):foreach(function(line_number)
            print("before: " .. lines[line_number])
            local link = parse_link(lines[line_number], loc.raw)
            link.url = url.id
            print("after: " .. tostring(link))
            lines[line_number] = tostring(link)
        end)

        ref_path:write(lines)
    end)
end

function print_and_update_tally(filtered, label, old_count)
    local new_count = #filtered:keys()
    local print_count = new_count
    if old_count then
        print_count = old_count - print_count
    end
    print(string.format("%s: %d", label, print_count))
    return new_count
end

local ps = {where = {title = "chasefeel"}}
-- ps = {}
projects:get(ps):foreach(function(project)
    local references = List()
    local definitions = List()

    local referenced_locs = Dict(Reference.get_referenced_locations(project.path))
    local n = print_and_update_tally(referenced_locs, "start")

    referenced_locs:filterk(function(loc) return not is_uuid(loc) end)
    n = print_and_update_tally(referenced_locs, "uuid", n)

    referenced_locs:filterk(function(loc)
        if loc:endswith(":") then
            return not is_uuid(loc:removesuffix(":"))
        end
        return true
    end)
    n = print_and_update_tally(referenced_locs, "uuid", n)

    referenced_locs:filterk(function(loc) return not loc:startswith("http") end)
    n = print_and_update_tally(referenced_locs, "http", n)

    local referenced_path_locs = Dict()
    referenced_locs:foreach(function(loc, refs)
        if parse_path_loc(loc, project) then
            referenced_path_locs[loc] = refs
            referenced_locs[loc] = nil
        end
    end)

    local unhandled = handle_path_locs(referenced_path_locs, project)

    n = print_and_update_tally(referenced_locs, "path", n)

    referenced_locs:keys():sorted():foreach(function(loc)
        local link_loc = parse_loc(loc, project)
        if link_loc then
            handle_link_loc(link_loc, referenced_locs[loc])
            referenced_locs[loc] = nil
        end
    end)

    n = print_and_update_tally(referenced_locs, "link", n)

    print(require("inspect")(n))
    -- referenced_locs:keys():foreach(print)
    referenced_locs:keys():sorted():foreach(function(k)
        print(k)
        print(require("inspect")(referenced_locs[k]))
    end)

    -- path_locs:sorted(function(a, b) return tostring(a) < tostring(b) end):foreach(print)
    -- print(require("inspect")(definitions))
    -- print(string.format("%s:", project.title))
    -- print(string.format("  references: %d", #references))
    -- print(string.format("  definitions: %d", #definitions))
end)
