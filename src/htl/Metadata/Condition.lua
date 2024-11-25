local M = Class()

function M:new(conf)
    local instance = setmetatable(conf or {}, self)
    instance.predicates = instance.predicates or List()
    instance.objects = instance.objects or List()

    return instance
end

function M:is_empty()
    return #self.predicates == 0 and #self.objects == 0
end

function M.default_predicates(c)
    c.predicates = #c.predicates > 0 and c.predicates or List({"*"})
    return true
end

function M.set_fields(c, fields)
    Dict.foreach(fields, function(key, val) c[key] = val end)
    return true
end

function M:parse_element(element)
    local path = Path.from_cli(element)
    local url = path:exists() and DB.urls.get_file(path)

    if not url and self.taxonomy then
        url = {id = DB.Metadata.Taxonomy.get_url(element, {insert = false})}
    end

    if url then
        element = url.id
        self:default_predicates()
    else
        element = element:gsub("%++", "*")
    end

    return element
end

function M.add(c, element)
    element = c:parse_element(element)

    local key

    if c.expect then
        key = #c.objects == 0 and "predicates" or "objects"
        c.expect = nil
    elseif #c.predicates == 0 then
        key = "predicates"
    elseif #c.objects == 0 then
        key = "objects"
    end

    if key then
        c[key]:append(element)
    end

    return key ~= nil
end

function M.apply(c, action)
    local type_to_fn = {["function"] = action, ["table"] = M.set_fields}
    local fn = type_to_fn[type(action)] or M.add
    return fn(c, action)
end

function M.format_objects(c)
    local by_type = Dict():set_default(List)
    c.objects:foreach(function(obj) by_type[type(obj)]:append(obj) end)

    -- things get weird when we have both string and url.id objects
    -- we're just going to do one or the other for now
    if #by_type.number > 0 then
        c.objects = by_type.number
    elseif #by_type.string > 0 then
        c.predicates = c.predicates:map(function(p)
            return c.objects:map(function(o)
                return p .. DB.Metadata.conf.subpredicate_sep .. o
            end)
        end):reduce(List.extend)
        c.objects = List()
    end

    if #c.predicates == 1 and c.predicates[1] == "*" then
        c.predicates:pop()
    end

    return c
end

function M.get(c)
    -- this nonsense is because we can't do both `where` and `contains` at the same time
    local objects = #c.objects > 0 and DB.Metadata:get({where = {object = c.objects}})
    local predicates = #c.predicates > 0 and DB.Metadata:get({contains = {predicate = c.predicates}})

    local rows = objects or predicates

    if objects and predicates then
        local ids = Set(predicates:col('id'))
        rows = rows:filter(function(r) return ids:has(r.id) end)
    end
    -- end nonsense

    if c.recurse then
        local subjects = rows:col('subject')

        while #subjects > 0 do
            local subrows = DB.Metadata:get({where = {object = subjects}})
            rows:extend(subrows)
            subjects = subrows:col('subject')
        end
    end

    return rows
end

return M
