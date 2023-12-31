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
    TEXT_COLOR = htc.config.get('colors')['text']
    BACKGROUND_COLOR = htc.track.dashboard_config()['colors']['background']
    ANNOTATE_KWARGS = {}

    def __init__(self, label, elements=None, color=None, indent=0):
        self.label = label
        self.color = color or self.TEXT_COLOR
        self.indent = 0

        if elements:
            if isinstance(elements, dict):
                self.elements = [self.get_elements(k, v) for k, v in elements.items()]
            else: self.elements = elements
        else:
            self.elements = []

    def get_elements(self, key, val):
        if isinstance(val, dict):
            return Subheader(
                label=key,
                elements=val,
                color=self.color,
                indent=self.indent + 1,
            )
        else:
            return Stat(
                label=key,
                value=val,
                color=self.color,
                indent=self.indent + 1,
            )


    @property
    def indented_label(self):
        return " " * 4 * self.indent + self.label

    def annotate(self, ax, previous_element=None):
        x, y = 0, 1

        if previous_element:
            bbox = previous_element.get_tightbbox()
            previous_y = min(bbox.y0, bbox.y1)
            _, y = ax.transAxes.inverted().transform((0, previous_y))
           
        previous_element = ax.annotate(
            self.indented_label,
            xy=(x + self.X_PAD, y + self.Y_PAD),
            fontproperties=self.FONTPROPERTIES,
            color=self.color,
            xycoords="axes fraction",
            ha='left',
            va='top',
            **self.ANNOTATE_KWARGS,
        )

        if self.elements:
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

    def __init__(self, label, elements=None, color=None, indent=1):
        self.label = label
        self.color = color or self.TEXT_COLOR
        self.indent = indent

        if elements:
            self.elements = [self.get_elements(k, v) for k, v in elements.items()]
        else:
            self.elements = []

        self.color = self.TEXT_COLOR

    @property
    def indented_label(self):
        return " " * 4 * self.indent + self.label + ":"

class Quote(Header):
    FONTPROPERTIES = FONTPROPERTIES['quote']
    Y_PAD = -.02
    ANNOTATE_KWARGS = {
        'wrap': True,
    }

    def __init__(self, text, indent=1):
        self.parse(text)
        self.indent = indent
        self.color = self.TEXT_COLOR

    def parse(self, text):
        self.label, attribution = text.rsplit("\n", 1)
        self.elements = [Attribution(text=attribution)]

class Attribution(Header):
    FONTPROPERTIES = FONTPROPERTIES['attribution']
    Y_PAD = -.02

    def __init__(self, text, indent=2):
        self.label = text
        self.indent = indent
        self.color = self.TEXT_COLOR
        self.elements = []

class Question(Header):
    X_PAD = .02
    Y_PAD = -.02

    def __init__(self, label):
        self.label = label
        self.color = self.TEXT_COLOR
        self.indent = 0
        self.elements = []

class Stat(Header):
    FONTPROPERTIES = FONTPROPERTIES['stat']
    STAT_START_XY = (0, -.1)

    def __init__(self, label, value, color=None, indent=2):
        self.label = label
        self.value = value
        self.color = color or self.TEXT_COLOR
        self.indent = indent
        self.first = False

    @property
    def indented_label(self):
        return " " * 6 * self.indent + self.label + ": "

    def annotate_for_alignment(self, ax, previous_element=None):
        return ax.annotate(
            self.indented_label,
            xy=self.STAT_START_XY,
            color=self.BACKGROUND_COLOR,
            xycoords=previous_element,
            fontproperties=self.FONTPROPERTIES,
            va='top',
        )

    def annotate(self, ax, previous_element=None):
        xy = (1, 1) if self.first else (1, -.05)

        element = ax.annotate(
            self.indented_label,
            xy=xy,
            xycoords=previous_element,
            va='top',
            ha='right',
            fontproperties=self.FONTPROPERTIES,
            color=self.TEXT_COLOR,
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

class AnnotationGroup(object):
    def __init__(self, elements):
        self.elements = elements

    def annotate(self, ax):
        previous_element = None

        for element in self.elements:
            previous_element = element.annotate(ax, previous_element=previous_element)
