return {
    colors = {
        {
            group_name = "markview_h1",
            value = { bg = "#453244", fg = "#f38ba8" }
        },
        {
            group_name = "markview_h1_icon",
            value = { bg = "#453244", fg = "#f38ba8" }
        },
        {
            group_name = "markview_h2",
            value = { bg = "#46393E", fg = "#fab387" }
        },
        {
            group_name = "markview_h2_icon",
            value = { bg = "#46393E", fg = "#fab387" }
        },
        {
            group_name = "markview_h3",
            value = { bg = "#464245", fg = "#f9e2af" }
        },
        {
            group_name = "markview_h3_icon",
            value = { bg = "#464245", fg = "#f9e2af" }
        },
        {
            group_name = "markview_h4",
            value = { bg = "#374243", fg = "#a6e3a1" }
        },
        {
            group_name = "markview_h4_icon",
            value = { bg = "#374243", fg = "#a6e3a1" }
        },
        {
            group_name = "markview_h5",
            value = { bg = "#2E3D51", fg = "#74c7ec" }
        },
        {
            group_name = "markview_h5_icon",
            value = { bg = "#2E3D51", fg = "#74c7ec" }
        },
        {
            group_name = "markview_h6",
            value = { bg = "#393B54", fg = "#b4befe" }
        },
        {
            group_name = "markview_h6_icon",
            value = { bg = "#393B54", fg = "#b4befe" }
        },
        {
            group_name = "code_block",
            value = { bg = "#181825" }
        },
        {
            group_name = "code_block_border",
            value = { bg = "#181825", fg = "#1e1e2e" }
        },
        {
            group_name = "inline_code_block",
            value = { bg = "#303030", fg = "#B4BEFE" }
        },
    },
    signs = {
        header = {
            {
                style = "padded_icon",
                line_hl = "markview_h1",

                icon = "󰼏 ",
                icon_hl = "markview_h1_icon",
            },
            {
                style = "padded_icon",
                line_hl = "markview_h2",

                icon = "󰎨 ",
                icon_hl = "markview_h2_icon",
            },
            {
                style = "padded_icon",
                line_hl = "markview_h3",

                icon = "󰼑 ",
                icon_hl = "markview_h3_icon",
            },
            {
                style = "padded_icon",
                line_hl = "markview_h4",

                icon = "󰎲 ",
                icon_hl = "markview_h4_icon",
            },
            {
                style = "padded_icon",
                line_hl = "markview_h5",

                icon = "󰼓 ",
                icon_hl = "markview_h5_icon",
            },
            {
                style = "padded_icon",
                line_hl = "markview_h6",

                icon = "󰎴 ",
                icon_hl = "markview_h6_icon",
            }
        },

        code_block = {
            style = "language",
            block_hl = "code_block",

            padding = " ",

            top_border = {
                language = true,
                language_hl = "Bold",
            },
        },

        inline_code = {
            before = "",
            after = "",
            hl = "inline_code_block"
        },

        block_quote = {
            default = {
                border = "▋",
                border_hl = {
                    "Glow_0",
                    "Glow_1",
                    "Glow_2",
                    "Glow_3",
                    "Glow_4",
                    "Glow_5",
                    "Glow_6",
                    "Glow_7",
                }
            },

            callouts = {
                {
                    match_string = "[!NOTE]",
                    callout_preview = "  Note",
                    callout_preview_hl = "rainbow5",

                    border = "▋ ",
                    border_hl = "rainbow5"
                },
                {
                    match_string = "[!IMPORTANT]",
                    callout_preview = "󰀨  Important",
                    callout_preview_hl = "rainbow2",

                    border = "▋ ",
                    border_hl = "rainbow2"
                },
                {
                    match_string = "[!WARNING]",
                    callout_preview = "  Warning",
                    callout_preview_hl = "rainbow1",

                    border = "▋ ",
                    border_hl = "rainbow1"
                },
                {
                    match_string = "[!TIP]",
                    callout_preview = " Tip",
                    callout_preview_hl = "rainbow4",

                    border = "▋ ",
                    border_hl = "rainbow4"
                },
                {
                    match_string = "[!CUSTOM]",
                    callout_preview = "󰠳 Custom",
                    callout_preview_hl = "rainbow3",

                    border = "▋ ",
                    border_hl = "rainbow3"
                }
            }
        },

        horizontal_rule = {
            border_char = "─",
            border_hl = "Comment",
        },

        hyperlink = {
            icon = " ",
            hl = "Label"
        },

        image = {
            icon = "abc ",
            hl = "Label"
        },

        list_item = {
            marker_plus = {
                add_padding = true,

                marker = "•",
                marker_hl = "rainbow2"
            },
            marker_minus = {
                add_padding = true,

                marker = "•",
                marker_hl = "rainbow4"
            },
            marker_star = {
                add_padding = true,

                marker = "•",
                marker_hl = "rainbow2"
            },
        },

        checkbox = {
            checked = {
                marker = " ✔ ",
                marker_hl = "@markup.list.checked"
            },
            unchecked = {
                marker = " ✘ ",
                marker_hl = "@markup.list.unchecked"
            }
        }
    }
}
