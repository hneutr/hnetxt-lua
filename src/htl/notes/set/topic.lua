local class = require("pl.class")
local List = require("hl.PList")
local Dict = require("hl.Dict")
local Path = require("hl.path")

local Config = require("htl.config")
local Fields = require("htl.notes.field")

local FileSet = require("htl.notes.set.file")
local File = require("htl.notes.note.file")
local Statement = require("htl.notes.note.statement")

class.TopicSet(FileSet)

TopicSet.type = 'topic'
TopicSet.dir_file = Config.get("directory_file")
TopicSet.iterdir_args = {recursive = false, dirs = false}
TopicSet.config_keys = List.from(FileSet.config_keys, {
    'statement',
    'file',
    'topics',
})
TopicSet.defaults = {
    statement = {fields = {}, filters = {}},
    file = {fields = {}, filters = {}},
}

function TopicSet:is_topic_dir(p)
    return p and #Path.suffix(p) == 0 and Path.parent(p) == self.path
end

function TopicSet:is_topic_statement(p)
    return p and Path.name(p) == self.dir_file.name and self:is_topic_dir(Path.parent(p))
end

function TopicSet:is_topic_file(p)
    return p and self:is_topic_dir(Path.parent(p)) and not self:is_topic_statement(p)
end

function TopicSet:is_topic(p)
    return self:is_topic_dir(p) or self:is_topic_statement(p)
end

function TopicSet:is_topic_content(p)
    return self:is_topic(p) or self:is_topic_file(p)
end

function TopicSet:as_topic_statement(path)
    if self:is_topic_statement(path) then
        return path
    elseif self:is_topic_file(path) then
        return Path.with_stem(path, self.dir_file.stem)
    elseif Path.parent(path) == self.path then
        path = Path.with_suffix(path, '')

        if self:is_topic_dir(path) then
            return Path.joinpath(path, self.dir_file.name)
        end
    end

    return nil
end

function TopicSet:path_topic(path)
    if self:is_topic_content(path) then
        path = self:as_topic_statement(path)
        path = Path.parent(path)
        return Path.relative_to(path, self.path)
    end
end

function TopicSet:path_config(path)
    local file_type

    if self:is_topic_statement(path) then
        file_type = 'statement'
    elseif self:is_topic_file(path) then
        file_type = 'file'
    end

    local config = self.topics[self:path_topic(path)] or self

    return config[file_type]
end

function TopicSet:path_file(path)
    local FileClass

    if self:is_topic_statement(path) then
        FileClass = Statement
    elseif self:is_topic_file(path) then
        FileClass = File
    end

    local config = self:path_config(path)
    return FileClass(path, config.fields, config.filters)
end

function TopicSet:get_topic_statements()
    local topic_statements = List()
    for _, topic_dir in ipairs(Path.iterdir(self.path, {recursive = false, files = false})) do
        local topic_statement = self:as_topic_statement(topic_dir)

        if Path.exists(topic_statement) then
            topic_statements:append(topic_statement)
        end
    end

    return topic_statements
end

function TopicSet:get_topic_files(path)
    local topic_files = List()
    if self:is_topic_content(path) then
        local topic_statement_path = self:as_topic_statement(path)
        local topic_dir_path = Path.parent(topic_statement_path)
        for _, topic_path in ipairs(Path.iterdir(topic_dir_path, {recursive = false, dirs = false})) do
            if topic_path ~= topic_statement_path then
                topic_files:append(topic_path)
            end
        end
    end

    return topic_files
end

function TopicSet:files(path)
    if self:is_topic_content(path) then
        return self:get_topic_files(path)
    end
    
    return self:get_topic_statements()
end

-- dir/topic/X.md → dir/topic/X.md
-- dir/topic/@.md → dir/topic/@.md
-- dir/topic.md   → dir/topic/@.md
-- dir/topic      → dir/topic/@.md
function TopicSet:get_path_to_touch(path, args)
    path = FileSet.get_path_to_touch(self, path, args)

    if self:is_topic_statement(path) or self:is_topic_file(path) then
        return path
    end

    if #Path.suffix(path) > 0 then
        path = Path.with_suffix(path, '')
    end

    if Path.parent(path) == self.path then
        return Path.joinpath(path, self.dir_file.name)
    end

    return nil
end

function TopicSet.format_topics(set)
    set = set or {}

    local topics = set.topics or {}
    for i, topic in ipairs(topics) do
        topics[topic] = {}
        topics[i] = nil
    end

    for key, topic in pairs(topics) do
        topic.statement = Dict(topic.statement, set.statement)
        topic.file = Dict(topic.file, set.file)
    end

    return topics
end

function TopicSet.format_fields(topic)
    topic.statement.fields = Fields.format(topic.statement.fields)
    topic.file.fields = Fields.format(topic.file.fields)
end

function TopicSet.format(set)
    set = set or {}
    set.statement = Dict(set.statement, TopicSet.defaults.statement)
    set.file = Dict(set.file, TopicSet.defaults.file)

    set.topics = TopicSet.format_topics(set)

    TopicSet.format_fields(set)

    for key, topic in pairs(set.topics) do
        TopicSet.format_fields(topic)
    end

    return {
        topics = set.topics,
        statement = set.statement,
        file = set.file,
    }
end

return TopicSet
