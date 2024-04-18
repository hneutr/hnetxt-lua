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

describe("is_taxonomy_file", function()
    it("+: global taxonomy file", function()
        assert(M.is_taxonomy_file(Conf.paths.global_taxonomy_file))
    end)
    
    it("+: project taxonomy file", function()
        assert(M.is_taxonomy_file(d1 / Conf.paths.taxonomy_file))
    end)
    
    it("-", function()
        assert.is_false(M.is_taxonomy_file(d1))
    end)
end)

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
    
    describe("make_taxonomy", function()
        it("existing subject missing object", function()
            assert.are.same(
                Tree({a = {b = {c = {}}}}),
                M.make_taxonomy(List({
                    {subject = "a"},
                    {subject = "b", object = "a"},
                    {subject = "b"},
                    {subject = "c", object = "b"},
                }))
            )
        end)
    end)

    describe("get_entity", function()
        local urls_by_id = Dict({
            a = Dict({
                id = "a",
                label = "has label",
                path = Conf.paths.global_taxonomy_file,
                created = 1,
                project = "test",
            }),
            b = Dict({
                id = "b",
                label = "",
                path = Path("b"),
                created = 2,
                project = "test",
            }),
        })

        it("no url", function()
            assert.are.same(
                {from_taxonomy = false},
                M.get_entity(
                    {subject_url = "c"},
                    "subject",
                    urls_by_id
                )
            )
        end)
        
        it("subject from taxonomy", function()
            assert.are.same(
                {
                    id = "a",
                    label = "relation label",
                    path = Conf.paths.global_taxonomy_file,
                    created = 1,
                    project = "test",
                    from_taxonomy = true,
                },
                M.get_entity(
                    {
                        subject_url = "a",
                        subject_label = "relation label",
                        relation = "test",
                    },
                    "subject",
                    urls_by_id
                )
            )
            
            assert.are.same(
                {
                    id = "a",
                    label = "has label",
                    path = Conf.paths.global_taxonomy_file,
                    created = 1,
                    project = "test",
                },
                urls_by_id.a
            )
        end)
    end)
    
    describe("get_priority", function()
        local ps = M.conf.label_priority
        local p = Dict({
            role = {min = ps.role[1], max = ps.role[#ps.role]},
            relation = {min = ps.relation[1], max = ps.relation[#ps.relation]},
        })

        it("works", function()
            assert(M.get_priority(p.role.min, p.relation.max) < M.get_priority(p.role.max, p.relation.min))
        end)
    end)
    
    describe("get_label_map", function()
        it("'instance of' > 'subset of' > 'other'", function()
            assert.are.same(
                {a = {label = "a", id = "instance of"}},
                M.get_label_map(List({
                    {
                        relation = "subset of",
                        subject = {label = "a", id = "subset of"},
                    },
                    {
                        relation = "instance of",
                        subject = {label = "a", id = "instance of"},
                    },
                    {
                        relation = "instance taxon",
                        subject = {label = "a", id = "instance taxon"},
                    }
                }))
            )
        end)
        it("'subject' > 'object'", function()
            assert.are.same(
                {a = {label = "a", id = "subject"}},
                M.get_label_map(List({
                    {
                        relation = "other",
                        object = {label = "a", id = "object"},
                    },
                    {
                        relation = "other",
                        subject = {label = "a", id = "subject"},
                    },
                    {
                        relation = "instance of",
                        object = {label = "a", id = "object"},
                    }
                }))
            )
        end)
    end)
    
    describe("get_instance_taxon", function()
        local parents = {a = "b", b = "c"}

        it("taxon has taxon_to_instance_taxon", function()
            assert.are.same(
                "a instance taxon",
                M.get_instance_taxon("a", parents, {a = "a instance taxon"})
            )
        end)
        
        it("taxon parent taxon_to_instance_taxon", function()
            assert.are.same(
                "b instance taxon",
                M.get_instance_taxon("a", parents, {b = "b instance taxon", c = "c instance taxon"})
            )
        end)
        
        it("taxon ancestor has taxon_to_instance_taxon", function()
            assert.are.same(
                "c instance taxon",
                M.get_instance_taxon("a", parents, {c = "c instance taxon"})
            )
        end)
        
        it("no taxon_to_instance_taxon", function()
            assert.are.same(
                "instance",
                M.get_instance_taxon("d", parents, {})
            )
        end)
        
    end)
end)
