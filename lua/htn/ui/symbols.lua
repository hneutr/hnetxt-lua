return function ()
    return {
        greek = {
            {"α", "alpha"},

            {"β", "beta"},

            {"Γ", "Gamma"},
            {"γ", "gamma"},

            {"Δ", "Delta"},
            {"δ", "delta"},

            {"ε", "epsilon"},

            {"ζ", "zeta"},

            {"η", "eta"},

            {"Θ", "Theta"},
            {"θ", "theta"},

            {"ι", "iota"},

            {"κ", "kappa"},

            {"Λ", "Lambda"},
            {"λ", "lambda"},

            {"μ", "mu"},

            {"ν", "nu"},

            {"Ξ", "Xi"},
            {"ξ", "xi"},

            {"Π", "Pi"},
            {"π", "pi"},

            {"ρ", "rho"},

            {"Σ", "Sigma"},
            {"σ", "sigma"},
            {"ς", "sigma"},

            {"τ", "tau"},

            {"υ", "upsilon"},

            {"Φ", "Phi"},
            {"φ", "phi"},

            {"χ", "chi"},

            {"Ψ", "Psi"},
            {"ψ", "psi"},

            {"Ω", "Omega"},
            {"ω", "omega"},
        },
        logic = {
            {"≔", ":="},

            {"Ɐ", "all"},
            {"Ǝ", "exists"},
            {"∈", "in"},

            {"∧", "and"},
            {"¬", "not"},

            {"⊣", "T ←"},
            {"⊢", "T →"},
            {"⊤", "T ↓"},
            {"⊥", "T ↑"},

            {"⊨", "TT →"},
            {"⫤", "TT left"},

            {"⊃", "cup ← subset"},
            {"⊂", "cup → superset"},
            {"⋂", "cup ↓"},
            {"⋃", "cup ↑"},

            {"⪾", "cup . ← subset"},
            {"⪽", "cup . → superset"},
            {"⩀", "cup . ↓"},
            {"⊍", "cup . ↑"},

            {"⋯", ".-"},
            {"⋮", ".|"},
            {"⋰", "./"},
            {"⋱", [[.\]]},

            {"∇", "inverted delta"},
        },

        -- https://en.wikipedia.org/wiki/Unicode_subscripts_and_superscripts
        superscripts = {
            -- numbers
            {"⁰", "0"},
            {"¹", "1"},
            {"²", "2"},
            {"³", "3"},
            {"⁴", "4"},
            {"⁵", "5"},
            {"⁶", "6"},
            {"⁷", "7"},
            {"⁸", "8"},
            {"⁹", "9"},

            -- symbols
            {"⁽", "("},
            {"⁾", ")"},
            {"⁻", "-"},
            {"⁼", "="},
            {"⁺", "+"},

            -- letters (lowercase)
            {"ᵃ", "a"},
            {"ᵇ", "b"},
            {"ᶜ", "c"},
            {"ᵈ", "d"},
            {"ᵉ", "e"},
            {"ᶠ", "f"},
            {"ᵍ", "g"},
            {"ʰ", "h"},
            {"ⁱ", "i"},
            {"ʲ", "j"},
            {"ᵏ", "k"},
            {"ˡ", "l"},
            {"ᵐ", "m"},
            {"ⁿ", "n"},
            {"ᵒ", "o"},
            {"ᵖ", "p"},
            {"ʳ", "r"},
            {"ˢ", "s"},
            {"ᵗ", "t"},
            {"ᵘ", "u"},
            {"ᵛ", "v"},
            {"ʷ", "w"},
            {"ˣ", "x"},
            {"ʸ", "y"},
            {"ᶻ", "z"},

            -- letters (uppercase)
            {"ᴬ", "A"},
            {"ᴮ", "B"},
            {"ᴰ", "D"},
            {"ᴱ", "E"},
            {"ᴳ", "G"},
            {"ᴴ", "H"},
            {"ᴵ", "I"},
            {"ᴶ", "J"},
            {"ᴷ", "K"},
            {"ᴸ", "L"},
            {"ᴹ", "M"},
            {"ᴺ", "N"},
            {"ᴼ", "O"},
            {"ᴾ", "P"},
            {"ᴿ", "R"},
            {"ᵀ", "T"},
            {"ᵁ", "U"},
            {"ⱽ", "V"},
            {"ᵂ", "W"},

            -- misc
            {"ᵅ", "alpha"},
        },

        -- https://en.wikipedia.org/wiki/Unicode_subscripts_and_superscripts
        subscript = {
            -- numbers
            {"₀", "0"},
            {"₁", "1"},
            {"₂", "2"},
            {"₃", "3"},
            {"₄", "4"},
            {"₅", "5"},
            {"₆", "6"},
            {"₇", "7"},
            {"₈", "8"},
            {"₉", "9"},

            -- symbols
            {"₍", "("},
            {"₎", ")"},
            {"₋", "-"},
            {"₌", "="},
            {"₊", "+"},

            -- letters (lowercase)
            {"ₐ", "a"},
            {"ₑ", "e"},
            {"ₕ", "h"},
            {"ᵢ", "i"},
            {"ⱼ", "j"},
            {"ₖ", "k"},
            {"ₗ", "l"},
            {"ₘ", "m"},
            {"ₙ", "n"},
            {"ₒ", "o"},
            {"ₚ", "p"},
            {"ᵣ", "r"},
            {"ₛ", "s"},
            {"ₜ", "t"},
            {"ᵤ", "u"},
            {"ᵥ", "v"},
            {"ₓ", "x"},

            {"ᵦ", "beta"},
        },

        math = {
            {"⨯", "x"},
            {"∞", "8"},
            {"∅", "null"},

            {"≃", "~="},
            {"≈", "~~="},
            {"≤", "<="},
            {"≥", ">="},
        },

        doublestruck = {
            {"𝔸", "A"},
            {"𝕒", "a"},

            {"𝔹", "B"},
            {"𝕓", "b"},

            {"ℂ", "C"},
            {"𝕔", "c"},

            {"𝔻", "D"},
            {"𝕕", "d"},

            {"𝔼", "E"},
            {"𝕖", "e"},

            {"𝔽", "F"},
            {"𝕗", "f"},

            {"𝔾", "G"},
            {"𝕘", "g"},

            {"ℍ", "H"},
            {"𝕙", "h"},

            {"𝕀", "I"},
            {"𝕚", "i"},

            {"𝕁", "J"},
            {"𝕛", "j"},

            {"𝕂", "K"},
            {"𝕜", "k"},

            {"𝕃", "L"},
            {"𝕝", "l"},

            {"𝕄", "M"},
            {"𝕞", "m"},

            {"ℕ", "N"},
            {"𝕟", "n"},

            {"𝕆", "O"},
            {"𝕠", "o"},

            {"ℙ", "P"},
            {"𝕡", "p"},

            {"ℚ", "Q"},
            {"𝕢", "q"},

            {"ℝ", "R"},
            {"𝕣", "r"},

            {"𝕊", "S"},
            {"𝕤", "s"},

            {"𝕋", "T"},
            {"𝕥", "t"},

            {"𝕌", "U"},
            {"𝕦", "u"},

            {"𝕍", "V"},
            {"𝕧", "v"},

            {"𝕎", "W"},
            {"𝕨", "w"},

            {"𝕏", "X"},
            {"𝕩", "x"},

            {"𝕐", "Y"},
            {"𝕪", "y"},

            {"ℤ", "Z"},
            {"𝕫", "z"},
        },
        arrows = {
            {"↖", "↑ ←"},
            {"↗", "↑ →"},
            {"↙", "↓ ←"},
            {"↘", "↓ →"},

            {"↔", "← →"},
            {"↕", "↑ ↓"},

            {"↤", "← bar"},
            {"↦", "→ bar"},
            {"↧", "↓ bar"},
            {"↥", "↑ bar"},
        },

        shapes = {
            triangles = {
                {"◀", "← closed"},
                {"▶", "→ closed"},
                {"▲", "↑ closed"},
                {"▼", "↓ closed"},

                {"◁", "← open"},
                {"▷", "→ open"},
                {"△", "↑ open"},
                {"▽", "↓ open"},

                {"◂", "← open mini"},
                {"▸", "→ open mini"},
                {"▴", "↑ open mini"},
                {"▾", "↓ open mini"},

                {"◃", "← closed mini"},
                {"▹", "→ closed mini"},
                {"▵", "↑ closed mini"},
                {"▿", "↓ closed mini"},

                {"◄", "← closed thin"},
                {"►", "→ closed thin"},

                {"◅", "← open thin"},
                {"▻", "→ open thin"},

                {"◤", "↑ ← corner closed"},
                {"◥", "↑ → corner closed"},
                {"◣", "↓ ← corner closed"},
                {"◢", "↓ → corner closed"},

                {"◸", "↑ ← corner open"},
                {"◹", "↑ → corner open"},
                {"◺", "↓ ← corner open"},
                {"◿", "↓ → corner open"},
            },

            diamonds = {
                {"◆", "closed"},
                {"◇", "open"},
                {"⟐", "."},
                {"◈", "box"},
                {"◊", "thin open"},
                {"⧫", "thin closed"},
            },

            circles = {
                {"●", "closed"},
                {"○", "open"},
                {"⨂", "x"},
                {"⊙", "."},
                {"◦", "open mini"},
                {"◯", "open low"},
                {"◉", "inset"},
                {"◐", "almost done"},
                {"◖", "left half"},
                {"◌", "dotted"},
                --[[
                    ◌ ◍ ◎ ◐ ◑ ◒ ◓ ◔ ◕ ◖ ◗
                    ◘ ◙ ◚ ◛
                    ◠ ◡
                    ◴ ◵ ◶ ◷ ⊕ ⊖ ⊗ ⍟ ⊘ ⊙ ⊚ ⊛ ⊜ ⊝ ⦰ ⦱ ⦲ ⦳ ⦴ ⦵ ⦶ ⦷ ⦸ ⦹ ⦺ ⦻ ⦼ ⦽ ⦾ ⦿ ⧀ ⧁ ⧂ ⧃ ⨶ ⨭ ⨮ ⨴ ⨵ ⨸ ⎉ ⎊
                    ⨀ ⨁ ⨂ ⨷ ⏼ ⌽ ⌾
                --]]
            },

            squares = {
                {"■", "closed"},
                {"□", "open"},
                {"◼", "closed small"},
                {"◻", "open small"},
                {"▪", "closed mini"},
                {"▫", "open mini"},
                {"⊡", '.'},
                {"▣", 'inset'},
                --[[
                ▢ ⎕
                ▤ ▥ ▦ ▧ ▨ ▩

                ▬ ▭
                ▮ ▯

                ▰ ▱
                ◧ ◨ ◩ ◪ ◫
                ◰ ◱ ◲ ◳
                ⧄ ⧅ ⧆ ⧇ ⧈ ⧉ ⧠ ⊞ ⊟ ⊠ ⊡ ⟤ ⟥
                --]]
            },
        },
    }
end
