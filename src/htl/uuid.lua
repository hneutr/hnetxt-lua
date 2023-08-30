local Date = require("pl.Date")
local List = require("hl.List")
local socket = require("socket")

local M = {}

local CHARSET = {
    -- letters
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", 
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",

    -- numbers
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",

    -- greek
    "α", "β", "γ", "Γ", "δ", "Δ", "ϵ", "ζ", "η", "θ", "Θ", "ι", "κ", 
    "λ", "Λ", "μ", "ν", "ξ", "Ξ", "π", "Π", "ρ", "σ", "Σ", "τ", "υ",
    "ϒ", "ϕ", "Φ", "χ", "ψ", "Ψ", "ω", "Ω",

    -- subscripts
    "ₐ", "ᵦ", "ₑ", "ₕ", "ᵢ", "ⱼ", "ₖ", "ₗ", "ₘ", "ₙ", "ₒ", "ₚ", "ᵣ", "ₛ", "ₜ", "ᵤ", "ᵥ", "ₓ",
    "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉",

    -- superscripts
    "ᵃ", "ᵇ", "ᶜ", "ᵈ", "ᵉ", "ᶠ", "ᵍ", "ʰ", "ⁱ", "ʲ", "ᵏ", "ˡ", "ᵐ",
    "ⁿ", "ᵒ", "ᵖ", "ʳ", "ˢ", "ᵗ", "ᵘ", "ᵛ", "ʷ", "ˣ", "ʸ", "ᶻ",
    "ᴬ", "ᴮ", "ᴰ", "ᴱ", "ᴳ", "ᴴ", "ᴵ", "ᴶ", "ᴷ", "ᴸ", "ᴹ", "ᴺ", "ᴼ", "ᴾ", "ᴿ", "ᵀ", "ᵁ", "ⱽ", "ᵂ",
    "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"
}

function M.uuid()
    local n = socket.gettime() * 10000
    local base = #CHARSET

    n = math.floor(n)
    base = math.floor(base)

    local id = ""

    while n > 0 do
        id = CHARSET[math.floor(n % base)] .. id
        n = math.floor(n / base)
    end

    return id
end

return M
