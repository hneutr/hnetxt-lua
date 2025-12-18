local M = class()

M.conf = Conf.text.heading

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Levels                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.levels = List.range(1, 6):map(function(level)
    return {
        n = level,
        hl_group = ("markdownH%d"):format(level),
        bg_hl_group = ("RenderMarkdownH%dBg"):format(level),
        marker = ("#"):rep(level),
        selector = ("(atx_h%d_marker)"):format(level),
        indent = ("  "):format(level - 1),
    }
end)

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    Meta                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Meta = class()
M.Meta = Meta

function Meta.init_conf(conf)
    local groups = Dict()
    local display_groups = List()
    local vals = Dict()

    for i, group in ipairs(conf.groups) do
        group.index = i
        groups[group.label] = group

        if not group.hide then
            display_groups:append(group.label)
        end

        for j, val in ipairs(group.vals) do
            val.index = j
            val.group = group.label
            val.hide = group.hide
            vals[val.flag] = val
        end
    end

    return {
        pattern = conf.pattern,
        groups = groups,
        display_groups = display_groups,
        vals = vals,
    }
end

Meta.conf = Meta.init_conf(M.conf.meta)

function Meta.get_display_defaults()
    local display = Dict():set_default(Set)

    Meta.conf.display_groups:foreach(function(group)
        if Meta.conf.groups[group].collapse then
            display.collapse:add(group)
        end
    end)

    return display
end

function Meta.parse(str)
    local text, meta = str:match(Meta.conf.pattern)
    return text or str, Meta(List(meta or {}))
end

function Meta:_init(vals)
    self.vals = Set(vals)
    self.groups = Set(vals:map(function(val) return self.conf.vals[val].group end))
    self.hide = self.groups:has("hidden")
end

function Meta:filter(groups_to_filter)
    local intersection = groups_to_filter * self.groups
    return groups_to_filter:isempty() or not intersection:isempty()
end

function Meta.get_displayable_signs(display)
    local signs = List()

    Meta.conf.display_groups:foreach(function(group_name)
        local group = Meta.conf.groups[group_name]

        local show = display.filter:has(group_name)

        if display.collapse:has(group_name) then
            signs:append(show and group.sign or " ")
        else
            signs:extend(group.vals:map(function(val) return show and val.sign or " " end))
        end
    end)

    return signs
end

function Meta:get_signs(groups_to_collapse)
    local signs = List()

    Meta.conf.display_groups:foreach(function(group_name)
        local group = Meta.conf.groups[group_name]

        if groups_to_collapse:has(group_name) then
            signs:append(self.groups:has(group_name) and group.sign or " ")
        else
            signs:extend(group.vals:map(function(val) return self.vals:has(val.flag) and val.sign or " " end))
        end
    end)

    return signs
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Heading                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M:_init(str, level, line)
    self.str = str
    self.level = self.levels[level]
    self.line = line

    self.text, self.meta = Meta.parse(self.str)
end

function M:__tostring()
    return ("%s %s"):format(self.level.marker, self.str)
end

function M.str_is_a(str)
    return str and str:match("^#+%s.*")
end

function M.from_str(str, line)
    local level, str = str:match("(#+)%s(.*)")
    return M(str, #level, line)
end

return M
