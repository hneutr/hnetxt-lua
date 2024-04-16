local HTL = require("htl")
local M = require("htl.Taxonomy")

local taxonomy_file = Conf.paths.taxonomy_file
local d1 = HTL.test_dir / "taxonomy-test"
local d2 = d1 / "subdir"
local t1 = d1 / taxonomy_file
local t2 = d2 / taxonomy_file

local d_local = d1

local p_global
local p_local

before_each(function()
    HTL.before_test()

    p_global = {path = Conf.paths.global_taxonomy_file:parent(), title = "global"}
    p_local = {path = d1, title = "local"}

    DB.projects:insert(p_global)
    DB.projects:insert(p_local)
end)

after_each(HTL.after_test)

describe("read_tree", function()
    it("no path", function()
        Conf.paths.global_taxonomy_file:write({
            "a:",
            "  b:",
            "c:"
        })

        assert.are.same(
            {
                a = {
                    b = {},
                },
                c = {},
            },
            M.read_tree(d1)
        )
    end)
    
    it("path in parent", function()
        Conf.paths.global_taxonomy_file:write({
            "a:",
            "  b:",
            "c:"
        })

        t1:write({
            "a:",
            "  x:",
            "b:",
            "  y:",
        })

        assert.are.same(
            {
                a = {
                    b = {
                        y = {},
                    },
                    x = {},
                },
                c = {},
            },
            M.read_tree(d2)
        )
    end)
end)

describe("_M", function()
    local M = M._M
    
    describe("get_projects", function()
        it("global: +, local: -", function()
            assert.are.same({"global", "local"}, M.get_projects(d_local))
        end)

        it("global: +, local: -", function()
            DB.projects:remove(p_local)
            assert.are.same({"global"}, M.get_projects(d_local))
        end)
    end)

    describe("get_rows_by_relation", function()
        it("works", function()
            local f_global = p_global.path / Conf.paths.taxonomy_file
            f_global:touch()

            local f_local = p_local.path / Conf.paths.taxonomy_file
            f_local:touch()

            DB.urls:insert({path = f_global})
            DB.urls:insert({path = f_local})
            
            local u_global = DB.urls:where({path = f_global})
            local u_local = DB.urls:where({path = f_local})
            
            DB.Relations:insert({subject_url = u_local.id, relation = "a"})
            DB.Relations:insert({subject_url = u_global.id, relation = "a"})

            DB.Relations:insert({subject_url = u_global.id, relation = "b"})
            DB.Relations:insert({subject_url = u_local.id, relation = "b"})
            
            DB.Relations:insert({subject_url = u_global.id, relation = "c"})

            DB.Relations:insert({subject_url = u_local.id, relation = "d"})

            local rows_by_relation = M.get_rows_by_relation(List({"global", "local"}))

            rows_by_relation:foreach(function(relation, rows)
                rows_by_relation[relation] = rows:transform(function(r)
                    return r.subject_url.id
                end):sorted()
            end)

            assert.are.same(
                {
                    a = {u_global.id, u_local.id},
                    b = {u_global.id, u_local.id},
                    c = {u_global.id},
                    d = {u_local.id},
                },
                rows_by_relation
            )
        end)
    end)
end)
