local lyaml = require("lyaml")

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

relation types handled:
    ✓ subset of
    ✓ instance taxon
    ✓ instance of
    ⨉ attribute of
]]
function _M:_init(path)
    self.projects = self.get_projects(path)
    self.rows = self.get_rows(self.projects)

    self.rows_by_relation = self.get_rows_by_relation(self.projects)
    self.taxonomy = self.add_subsets(self.rows_by_relation["subset of"])

    self.instance_taxonomy = self.get_instances_taxonomy(
        self.taxonomy,
        self.rows_by_relation
    )
end

function _M.get_projects(path)
    return List({
        Conf.paths.global_taxonomy_file,
        path,
    }):map(DB.projects.get_by_path):filter(function(p)
        return p
    end):col('title')
end

function _M.get_rows(projects)
    local project_to_index = Dict.from_list(projects, function(p) return p, projects:index(p) end)
    
    return DB.Relations:get_annotated():filter(function(r)
        return project_to_index[r.subject_url.project]
    end):sorted(function(a, b)
        return project_to_index[a.subject_url.project] < project_to_index[b.subject_url.project]
    end)
end

function _M.get_rows_by_relation(projects)
    local rows_by_relation = Dict()
    _M.get_rows(projects):foreach(function(row)
        rows_by_relation:default(row.relation, List())
        rows_by_relation[row.relation]:append(row)
    end)
    
    return rows_by_relation
end

function _M.add_subsets(rows)
    local tree = Tree()
    rows:foreach(function(row)
        tree:add_edge(row.object_label, row.subject_label)
    end)
    
    return tree
end

-- TODO:
-- weird stuff will happen if a child comes in before a parent
-- buuuuut we're going to leave it for now.
-- (should probably sort by `generation`)
function _M.get_instances_taxonomy(taxonomy, rows_by_relation)
    local tree = taxonomy:pop("instance") or Tree()
    
    rows_by_relation["instance taxon"]:foreach(function(row)
        tree:pop(row.subject_label)
        tree:add({
            [row.object_label] = {
                [row.subject_label] = taxonomy:get(row.subject_label) or Tree()
            }
        })
    end)
    
    rows_by_relation["instance of"]:foreach(function(row)
        tree:add_edge(row.object_label, row.subject_label)
    end)
    
    return tree
end

Taxonomy._M = _M

return Taxonomy
