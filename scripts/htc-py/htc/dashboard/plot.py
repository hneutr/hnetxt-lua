from matplotlib.font_manager import FontProperties

import hnelib as hl

import htc.config


FONTPROPERTIES = {
    'header': FontProperties(
        size=32,
    ),
    'subheader': FontProperties(
        size=24,
    ),
    'ticks': FontProperties(
        size=20,
    ),
    'stat': FontProperties(
        size=16,
    ),
    'annotation': FontProperties(
        size=10,
    ),
    'quote': FontProperties(
        size=16,
    ),
    'attribution': FontProperties(
        size=12,
    ),
}

def add_emoji(
    ax,
    emoji_name,
    x,
    y,
    width=.5,
    height=.5,
    ha='center',
    va='center',
):
    if ha == 'right':
        x -= width
    elif ha == 'center':
        x -= width / 2

    if va == 'top':
        y -= height
    elif va == 'center':
        y -= height / 2

    ax.imshow(
        htc.config.get_emoji(emoji_name),
        aspect='auto',
        extent=(x, x + width, y,  y + height),
        transform=ax.transData,
        zorder=1,
    )

def set_axis(ax, which, ticks, lim=None, labels=None):
    if lim:
        getattr(ax, f"set_{which}lim")(lim[0], lim[-1])

    if hl.util.as_list(ticks):
        getattr(ax, f"set_{which}ticks")(ticks)

        if hl.util.as_list(labels):
            getattr(ax, f"set_{which}ticklabels")(
                labels,
                fontproperties=FONTPROPERTIES['ticks'],
                color=htc.track.dashboard_config()['colors']['ticks'],
            )


class Header(object):
    X_PAD = .02
    Y_PAD = -.02
    FONTPROPERTIES = FONTPROPERTIES['header']
    BACKGROUND_COLOR = htc.track.dashboard_config()['colors']['background']
    ANNOTATE_KWARGS = {}

    FIXED_COLOR = False
    FIXED_INDENT = True

    DEFAULT_COLOR = htc.config.get('colors')['text']
    DEFAULT_INDENT = 0

    INDENT_SIZE = 4

    def __init__(self, text, elements=None, color=None, indent=None):
        self.color = color
        self.indent = indent
        self.text = text
        self.elements = elements

    @property
    def color(self):
        return self._color

    @color.setter
    def color(self, val):
        self.raw_color = val

        if self.FIXED_COLOR:
            val = None

        self._color = val or self.DEFAULT_COLOR

    @property
    def indent(self):
        return self._indent

    @indent.setter
    def indent(self, val):
        if self.FIXED_INDENT:
            val = None

        self._indent = val or self.DEFAULT_INDENT

    @property
    def text(self):
        return self._text

    @text.setter
    def text(self, val):
        self._text = " " * self.INDENT_SIZE * self.indent + val

    @property
    def elements(self):
        return self._elements

    @elements.setter
    def elements(self, elements):
        if not elements:
            elements = []

        if isinstance(elements, dict):
            elements = [self.get_elements(k, v) for k, v in elements.items()]

        self._elements = elements

    def get_elements(self, key, val):
        if isinstance(val, dict):
            return Subheader(
                text=key,
                elements=val,
                color=self.raw_color,
                indent=self.indent + 1,
            )
        else:
            return Stat(
                text=key,
                value=val,
                color=self.raw_color,
                indent=self.indent + 1,
            )

    def annotate(self, ax, previous_element=None):
        x, y = 0, 1

        if previous_element:
            bbox = previous_element.get_tightbbox()
            previous_y = min(bbox.y0, bbox.y1)
            _, y = ax.transAxes.inverted().transform((0, previous_y))
           
        previous_element = ax.annotate(
            self.text,
            xy=(x + self.X_PAD, y + self.Y_PAD),
            fontproperties=self.FONTPROPERTIES,
            color=self.color,
            xycoords="axes fraction",
            ha='left',
            va='top',
            **self.ANNOTATE_KWARGS,
        )

        first_stat = True
        for element in self.elements:
            if isinstance(element, Stat) and first_stat:
                previous_element = self.get_alignment_element(ax, previous_element)
                element.first = True
                first_stat = False

            previous_element = element.annotate(ax, previous_element=previous_element)

        return previous_element

    def get_alignment_element(self, ax, previous_element=None):
        stats = [e for e in self.elements if isinstance(e, Stat)]
        text_elements = [e.annotate_for_alignment(ax, previous_element=previous_element) for e in stats]
        return max(text_elements, key=lambda t: t.get_tightbbox().x1)


class Subheader(Header):
    FONTPROPERTIES = FONTPROPERTIES['subheader']
    Y_PAD = .01

    FIXED_COLOR = True
    FIXED_INDENT = False

    DEFAULT_INDENT = 1

    def __init__(self, text, **kwargs):
        super().__init__(text=text + ":", **kwargs)

class Quote(Header):
    FONTPROPERTIES = FONTPROPERTIES['quote']
    Y_PAD = 0
    X_PAD = .05
    LINE_LENGTH = 90
    ANNOTATE_KWARGS = {
        'wrap': True,
    }

    FIXED_COLOR = True

    def __init__(self, text, elements=None, color=None, indent=None):
        self.color = color
        self.indent = indent
        self.text, self.elements = self.parse(text)

    def parse(self, text):
        text, attribution = text.rsplit("\n", 1)

        lines = [""]
        for word in text.split():
            if len(lines[-1] + word) > self.LINE_LENGTH:
                lines.append("")

            if lines[-1]:
                word = " " + word

            lines[-1] += word

        elements = [Line(line, indent=self.indent) for line in lines[1:]] + [Attribution(text=attribution)]
        return lines[0], elements

class Line(Header):
    FONTPROPERTIES = FONTPROPERTIES['quote']
    X_PAD = .05
    Y_PAD = .01

    FIXED_COLOR = True

class Attribution(Header):
    FONTPROPERTIES = FONTPROPERTIES['attribution']
    Y_PAD = -.02
    X_PAD = .075

    FIXED_COLOR = True

class Stat(Header):
    FONTPROPERTIES = FONTPROPERTIES['stat']
    STAT_START_XY = (0, -.1)

    FIXED_COLOR = False
    FIXED_INDENT = False

    DEFAULT_INDENT = 2
    INDENT_SIZE = 6

    def __init__(self, text, value, **kwargs):
        super().__init__(text=text + ": ", **kwargs)
        self.value = value
        self.first = False

    def annotate_for_alignment(self, ax, previous_element=None):
        return ax.annotate(
            self.text,
            xy=self.STAT_START_XY,
            color=self.BACKGROUND_COLOR,
            xycoords=previous_element,
            fontproperties=self.FONTPROPERTIES,
            va='top',
        )

    def annotate(self, ax, previous_element=None):
        xy = (1, 1) if self.first else (1, -.05)

        element = ax.annotate(
            self.text,
            xy=xy,
            xycoords=previous_element,
            va='top',
            ha='right',
            fontproperties=self.FONTPROPERTIES,
            color=self.DEFAULT_COLOR,
        )

        ax.annotate(
            self.value,
            xy=(1, 0),
            xycoords=element,
            va='bottom',
            fontproperties=self.FONTPROPERTIES,
            color=self.color,
        )

        return element

def add_annotate_group(ax, elements):
    previous_element = None
    for element in elements:
        previous_element = element.annotate(ax, previous_element=previous_element)
