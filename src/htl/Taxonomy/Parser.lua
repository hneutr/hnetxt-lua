local M = {}
M.conf = Dict(Conf.Taxonomy)
M.conf.relations = Dict(M.conf.relations)
M.conf.indent_size = "  "

function M:record_is_a(url, line)
    DB.Relations:remove({subject_url = url})

    local object, relation = M:parse_predicate(line)

    DB.Relations:insert({
        subject_url = url,
        object = object,
        relation = relation or "instance of",
    })
    
    return tostring(object)
end

function M:parse_taxonomy_file(path)
    local url = DB.urls:get_file(path)
    
    DB.Relations:remove({subject_url = url.id})

    M:parse_taxonomy_lines(path:readlines()):foreach(function(r)
        r.subject_url = url.id
        DB.Relations:insert(r)
    end)
end

function M:parse_taxonomy_lines(lines)
    local indent_to_parent = Dict()

    local relations = List()
    lines:foreach(function(l)
        local indent, l = l:match("(%s*)(.*)")
        local parse = M:parse_line(l)
        indent_to_parent[indent .. M.conf.indent_size] = parse.subject_label
        
        relations:append({
            subject_label = parse.subject_label,
            object = indent_to_parent[indent],
            relation = "subset of",
        })
        
        if parse.object and #parse.object > 0 and parse.relation then
            relations:append(parse)
        end
    end)
    
    return relations
end

function M:parse_line(s, subject)
    if not subject then
        subject, s = M:parse_subject(s)
    end

    local object, relation = M:parse_predicate(s)

    return Dict({
        subject_label = subject,
        object = object,
        relation = relation,
    })
end

function M:parse_subject(s)
    s = s or ""
    local subject, s = unpack(s:split(":", 1):mapm("strip"))
    return subject, s
end

function M.parse_link(s)
    local link = Link:from_str(s)
    if link then
        s = tonumber(link.url)
    end
    return s
end

function M:parse_predicate(s)
    s = s or ""
    s = s:strip()
    for relation, symbol in pairs(self.conf.relations) do
        local prefix = string.format("%s(", symbol)
        local suffix = ")"
        if s:startswith(prefix) and s:endswith(suffix) then
            s = s:removeprefix(prefix):removesuffix(suffix)
            
            -- local link = Link:from_str(s)
            -- if link then
            --     s = tonumber(link.url)
            -- end
            
            return M.parse_link(s), relation
        end
    end

    return M.parse_link(s)
end

return M
