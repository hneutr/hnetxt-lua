local stub = require('luassert.stub')
local Project = require("htl.project")

local Path = require("hl.Path")
local Dict = require("hl.Dict")
local Set = require("pl.Set")

local Metadata = require("htl.metadata")
local Tag = Metadata.Tag
local Field = Metadata.Field
local MReference = Metadata.MReference
local BlankField = Metadata.BlankField
local File = Metadata.File
local Files = Metadata.Files

local dir = Path.tempdir:join("metadata-test")

before_each(function()
    dir:rmdir(true)
    stub(Project, 'root_from_path')
    Project.root_from_path.returns(dir)
end)

after_each(function()
    dir:rmdir(true)
    Project.root_from_path:revert()
end)


describe("Field", function()
    describe("is_a", function()
        it("+", function()
            assert(Field.is_a("a: b")) 
        end)
        it("-: non field", function()
            assert.falsy(Field.is_a("a")) 
        end)

        it("-: tag", function()
            assert.falsy(Field.is_a("@a")) 
        end)
    end)

    describe("init", function()
        it("parses", function()
            local f = Field("a: b")
            assert.are.same("a", f.key)
            assert.are.same("b", f.val)
        end)
    end)

    describe("add_to_metadata", function()
        it("works", function()
            local metadata = Dict()
            Field("a: b"):add_to_metadata(metadata)

            local expected = Dict()
            expected:default_dict("fields")
            expected.fields.a = "b"
            assert.are.same(expected, metadata)
        end)

        it("doesn't overwrite", function()
            local metadata = Dict()
            metadata:default_dict("fields")
            metadata.fields.a = "b"
            Field("c: d"):add_to_metadata(metadata)

            local expected = Dict()
            expected:default_dict("fields")
            expected.fields.a = "b"
            expected.fields.c = "d"
            assert.are.same(expected, metadata)
        end)
    end)

    describe("check_metadata", function()
        it("+", function()
            local field = Field("a: b")
            local metadata = Dict()
            field:add_to_metadata(metadata)
            assert(field:check_metadata(metadata))
        end)

        it("-", function()
            local f1 = Field("a: b")
            local f2 = Field("a: c")
            local metadata = Dict()
            f1:add_to_metadata(metadata)
            assert.falsy(f2:check_metadata(metadata))
        end)
    end)

    describe("gather", function()
        it("works", function()
            local m1 = Dict({fields = Dict({a = "b"})})
            local m2 = Dict({fields = Dict({a = "c"})})
            local metadata = Dict()
            Field.gather(metadata, m1)
            Field.gather(metadata, m2)
            assert.are.same(
                Dict({fields = Dict({a = Set({"b", "c"})})}),
                metadata
            )
        end)
    end)
end)

describe("Tag", function()
    describe("is_a", function()
        it("+", function()
            assert(Tag.is_a("@a")) 
        end)

        it("+: multitag", function()
            assert(Tag.is_a("@a.b")) 
        end)

        it("-: field", function()
            assert.falsy(Tag.is_a("a: b")) 
        end)
    end)

    describe("init", function()
        it("+", function()
            assert.are.same(List({"a"}), Tag("@a").val)
        end)

        it("+: multitag", function()
            assert.are.same(List({"a", "b"}), Tag("@a.b").val)
        end)
    end)

    describe("add_to_metadata", function()
        it("works", function()
            local metadata = Dict()
            Tag("@a.b"):add_to_metadata(metadata)

            local expected = Dict()
            expected:default_dict("tags", "a", "b")
            assert.are.same(expected, metadata)
        end)
    end)

    describe("check_metadata", function()
        it("+", function()
            local t = Tag("@a.b.c")
            local metadata = Dict()
            t:add_to_metadata(metadata)
            assert(t:check_metadata(metadata))
        end)

        it("+: less specific tag condition", function()
            local metadata = Dict()
            Tag("@a.b.c"):add_to_metadata(metadata)
            assert(Tag("@a.b"):check_metadata(metadata))
        end)

        it("-: more specific tag condition", function()
            local metadata = Dict()
            Tag("@a.b"):add_to_metadata(metadata)
            assert.falsy(Tag("@a.b.c"):check_metadata(metadata))
        end)

        it("-: no tag", function()
            local metadata = Dict()
            assert.falsy(Tag("@a.b.c"):check_metadata(metadata))
        end)
    end)

    describe("gather", function()
        it("works", function()
            local metadata = Dict()
            Tag.gather(metadata, Dict({tags = {a = { b = {}}}}))
            Tag.gather(metadata, Dict({tags = {a = { c = {}}}}))
            assert.are.same(
                {tags = {a = {b = {}, c = {}}}},
                metadata
            )
        end)
    end)
end)

describe("MReference", function()
    describe("is_a", function()
        it("+", function()
            assert(MReference.is_a("a: [b](c)")) 
        end)

        it("-", function()
            assert.falsy(MReference.is_a("a: b")) 
        end)
    end)

    describe("init", function()
        it("+", function()
            local r = MReference("a: [b](c)")
            assert.are.same("a", r.key)
            assert.are.same("c", r.val)
        end)
    end)

    describe("add_to_metadata", function()
        it("works", function()
            local metadata = Dict()
            MReference("a: [b](c)"):add_to_metadata(metadata)

            local expected = Dict()
            expected:default_dict("references")
            expected.references.a = "c"
            assert.are.same(expected, metadata)
        end)
    end)

    describe("check_metadata", function()
        it("+", function()
            local reference = MReference("a: [b](c)")
            local metadata = Dict()
            reference:add_to_metadata(metadata)
            assert(reference:check_metadata(metadata))
        end)

        it("-", function()
            local metadata = Dict()
            MReference("a: [b](c)"):add_to_metadata(metadata)
            assert.falsy(MReference("e: [f](g)"):check_metadata(metadata))
        end)
    end)
end)

describe("File", function()
    local file = dir:join("test-file.md")

    describe("init", function()
        it("works", function()
            file:write({
                "a: b",
                "@c.d",
                "e: [f](g)",
                "",
                "xyz",
            })
            
            local expected = Dict()
            expected:default_dict("tags", "c", "d")
            expected:default_dict("fields")
            expected.fields.a = "b"
            expected:default_dict("references")
            expected.references.e = "g"

            assert.are.same(expected, File(file, dir).metadata)
        end)
    end)

    describe("set_references_list", function()
        it("works", function()
            file:write({
                "a: [b](c)",
                "d: [b](c)",
                "e: [f](g)",
                "",
                "xyz",
            })
            
            local expected = Set({tostring(dir:join("c")), tostring(dir:join("g"))})
            local actual = File(file, dir).references
            assert.are.same(expected, actual)
        end)
    end)
end)

describe("Files", function()
    local a = dir:join("a.md")
    local b = dir:join("b.md")
    local c = dir:join("c.md")

    describe("init", function()
        it("works", function()
            
            a:write({
                "z: [_](c.md)",
                "",
                "xyz",
            })
            b:write({
                "z: [_](a.md)",
                "",
                "xyz",
            })

            local filter_reference = c
            local files = Files({dir = dir})

            local expected = List({a, b}):transform(tostring)
            files:filter_by_reference(filter_reference)
            assert.are.same(expected, files.path_to_file:keys())
        end)
    end)    
end)

describe("Condition", function()
    describe("init", function()
        it("Tag", function()
            assert.are.same(Tag("a.b"), Condition("@a.b").parser)
        end)
        
        it("Field", function()
            assert.are.same(Field("a: b"), Condition("a: b").parser)
        end)
        
        it("BlankField", function()
            assert.are.same(BlankField("a"), Condition("a").parser)
        end)

        it("exclusion", function()
            local c = Condition("a!")
            assert.are.same(BlankField("a"), c.parser)
            assert(c.is_exclusion)
        end)
    end)
end)
