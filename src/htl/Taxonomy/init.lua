local lyaml = require("lyaml")

local Tree = require("hl.Tree")
local List = require("hl.List")

local Taxonomy = require("pl.class")()

Taxonomy.Parser = require("htl.Taxonomy.Parser")

function Taxonomy.path_is_taxonomy(path)
    return path:name() == tostring(Conf.paths.taxonomy_file) or path == Conf.paths.global_taxonomy_file
end

function Taxonomy:_init(path)
    self.tree = self.read_tree(path)
    self:solidify()
end

function Taxonomy:solidify()
    List({
        "parents",
        "ancestors",
        "generations",
        "descendants",
        "children",
    }):foreach(function(key)
        self[key] = self.tree[key](self.tree)
    end)
end

function Taxonomy.read_tree(path)
    local paths = List()
    if path then
        paths = path:parents()

        if path:is_dir() then
            paths:append(path)
        end

        paths = paths:transform(function(p)
            return p:join(Conf.paths.taxonomy_file)
        end):filter(function(p)
            return p:exists()
        end)
    end

    paths:put(Conf.paths.global_taxonomy_file)

    local tree = Tree()

    paths:foreach(function(path)
        tree:add(Tree(lyaml.load(path:read())))
    end)

    return tree
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  testing                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local _M = require("pl.class")()
_M.conf = Dict(Conf.Taxonomy)
_M.conf.relations = Dict(_M.conf.relations)
_M.conf.all_relation_key = "__all"

--[[
To construct a taxonomy:
1. start by constructing the global taxonomy
2. modify it with the local taxonomy

constructing a taxonomy from Relation rows:
- just add them all iteratively to the tree
- then set the attributes for the relations directly?

TODO:
1. build taxonomies as described above (filtering by project, etc)

-----------------------------------[ steps ]------------------------------------
1. get rows for a given project
    - get `strings` for each row
2. handle row by relation:
    ✓ subset of
    - instance taxon:
    - attribute of:
    - instance of:
]]
function _M:_init(path)
    self.instance_taxa = Dict()
    
    self.projects = self:get_projects(path)
    self.rows_by_relation = self.get_rows_by_relation(self.projects)

    self.taxonomy = self.add_subsets(self.rows_by_relation["subset of"])
    -- TODO:
    self.instance_taxonomy = self.add_instance_taxa(self.taxonomy, self.rows_by_relation["instance taxon"])
end

--[[
what's the issue?
1. we want to retain information about which things are urls (links) and which are strings
2. we need to have a consistent lookup for (url, string) pairs
]]
function _M.add_subsets(rows)
    local tree = Tree()
    rows:foreach(function(row)
        tree:add_edge(_M.get_label(row, "object"), _M.get_label(row, "subject"))
    end)
    
    return tree
end

function _M.add_instance_taxa(taxonomy, rows)
    local instances_taxonomy = self.taxonomy:pop("instances") or Tree()
end

function _M.get_label(row, role)
    local string_key = string.format("%s_string", role)
    local url_key = string.format("%s_url", role)
    
    local label = row[string_key] or row[url_key] and DB.urls:get_label(row[url_key])
    
    if label and #label == 0 then
        return
    end
    
    return label
end

function _M.get_projects(path)
    return List({
        Conf.paths.global_taxonomy_file,
        path,
    }):map(DB.projects.get_by_path):filter(function(p)
        return p
    end):col('title')
end

function _M.get_rows_by_relation(projects)
    local rows_by_relation = Dict()
    DB.Relations:get_annotated():foreach(function(row)
        row.i = projects:index(row.subject_url.project)

        if row.i then
            rows_by_relation:default(row.relation, List())
            rows_by_relation[row.relation]:append(row)
        end
    end)
    
    rows_by_relation:foreach(function(relation, rows)
        rows_by_relation[relation] = rows:sorted(function(a, b) return a.i < b.i end)
    end)
    
    return rows_by_relation
end

function _M:add_row()
end

Taxonomy._M = _M

return Taxonomy
