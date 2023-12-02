from fontforge import *

from pathlib import Path
OUT_DIR = Path(__file__).parent / 'data' / 'emojis' / 'images'
FONTS_DIR = Path("/System/Library/Fonts")
FONT_PATH = FONTS_DIR / "Apple Symbols.ttf"
# FONT_PATH = FONTS_DIR / "Apple Color Emoji.ttc"

font = open(str(FONT_PATH))
names = [font[glyph].glyphname for glyph in font]
# for n in sorted(names):
#     print(n)

for glyph in font:
    p = OUT_DIR / f"{font[glyph].glyphname}.png"
    if font[glyph].isWorthOutputting():
        font[glyph].export(str(p))
    elif p.exists():
        print(font[glyph].glyphname)
        p.unlink()

# https://github.com/tmm1/emoji-extractor/blob/master/emoji_extractor.rb
