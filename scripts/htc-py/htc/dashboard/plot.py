from matplotlib.font_manager import FontProperties

import htc.config


FONTPROPERTIES = {
    'header': FontProperties(
        size=24,
    ),
    'stat': FontProperties(
        size=16,
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


def stat_group(
    ax,
    header,
    stats,
    xycoords=None,
    xy=(.02, .98),
    post_header_xy=(.2, -.1),
    post_stat_xy=(0, -.05),
    color=None,
):
    xycoords = ax.annotate(
        header,
        xy=xy,
        fontproperties=FONTPROPERTIES['header'],
        color=color,
        xycoords=xycoords or 'axes fraction',
        ha='left',
        va='top',
    )

    xy = post_header_xy

    for stat, value in stats.items():
        xycoords = ax.annotate(
            stat + ": ",
            xy=xy,
            xycoords=xycoords,
            va='top',
            fontproperties=FONTPROPERTIES['stat'],
            color=htc.config.get('colors')['text'],
        )

        ax.annotate(
            value,
            xy=(1, 0),
            xycoords=xycoords,
            va='bottom',
            fontproperties=FONTPROPERTIES['stat'],
            color=color,
        )

        xy = post_stat_xy
