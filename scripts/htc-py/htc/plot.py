from datetime import datetime, timedelta, date
import itertools
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.offsetbox import OffsetImage, AnnotationBbox
from matplotlib.font_manager import FontProperties

import hnelib.runner
import hnelib as hl
import hnelib.plt.scatter
import hnelib.plt.color

import htc.track
import htc.config
import htc.dashboard
from htc.datatype import TimeDelta, Time

def add_sections(
    parent_ax,
    sections,
    by='col',
    x=0,
    y=0,
    width=1,
    height=1,
    x_pad=0,
    y_pad=0,
    facecolor=None,
):
    dynamic_key = 'width' if by == 'col' else 'height'

    for default, key, pad in zip([width, height], ['width', 'height'], [x_pad, y_pad]):
        for section in sections:
            section[key] = section.get(key, default)

        if key == dynamic_key:
            available = default - (pad * (len(sections) - 1))
            scale = sum([s[key] for s in sections]) / available

            for section in sections:
                section[key] /= scale

    insets = {}
    for i, section in enumerate(sections):
        name = section.get('name')

        if 'layout' in section:
            subinsets = add_sections(
                parent_ax,
                x=x,
                y=y,
                width=section['width'],
                height=section['height'],
                **{
                    **{
                        'x_pad': x_pad,
                        'y_pad': y_pad,
                        'facecolor': facecolor,
                    },
                    **section['layout'],
                },
            )

            if name:
                insets[name] = subinsets
            else:
                insets.update(subinsets)
        else:
            inset = parent_ax.inset_axes(
                (
                    x,
                    y,
                    section['width'],
                    section['height'],
                )
            )

            if facecolor:
                inset.set_facecolor(facecolor)

            hl.plt.axes.hide_ticks(inset)
            inset.spines.top.set_visible(True)
            inset.spines.right.set_visible(True)

            insets[name or i] = inset

        if by == 'col':
            x += x_pad + section['width']
        else:
            y += y_pad + section['height']

    return insets

def get_dashboard_layout(
    sections=[
        {
            'width': 1.5,
            'layout': {
                'by': 'row',
                'y_pad': .05,
                'sections': [
                    {'name': 'quote-of-the-day'},
                    {'name': 'week'},
                ],
            },
        },
        {
            'layout': {
                'by': 'row',
                'sections': [
                    {
                        'name': 'text',
                        'height': 2,
                        'layout': {
                            'by': 'row',
                            'sections': [
                                {'name': 'misc'},
                                {'name': 'writing'},
                            ],
                        },
                    },
                ],
            }
        },
    ],
):
    config = htc.track.dashboard_config()
    fig, page_ax = plt.subplots(figsize=config['page']['size'])
    fig.set_facecolor(config['colors']['page'])
    hl.plt.axes.hide(page_ax)

    x_margin = config['page']['margin']
    y_margin = scale_y(x_margin)

    return fig, add_sections(
        page_ax,
        x=x_margin,
        y=y_margin,
        width=1 - 2 * x_margin,
        height=1 - 2 * y_margin,
        x_pad=x_margin,
        y_pad=y_margin,
        sections=sections,
        facecolor=config['colors']['background'],
    )


def scale_y(y):
    config = htc.track.dashboard_config()
    page_width, page_height = config['page']['size']
    xy_scale = page_height / page_width
    return y / xy_scale


def weekly_dashboard():
    fig, axes = get_dashboard_layout()

    weekly_time_spent(axes['week'])

    writing_stats(axes['text']['writing'])
    misc_stats(axes['text']['misc'])

    quote_of_the_day(axes['quote-of-the-day'])

def quote_of_the_day(ax):
    today = datetime.today().strftime("%Y%m%d")
    quote_path = htc.constants.QUOTE_OF_THE_DAY_DIR / today
    question_path = htc.constants.QUESTION_OF_THE_DAY_DIR / today

    htc.dashboard.plot.add_annotate_group(
        ax=ax,
        elements=[
            htc.dashboard.plot.Header(question_path.read_text()),
            htc.dashboard.plot.Header(
                "quote of the day",
                color=htc.track.dashboard_config()['colors']['highlight'],
                elements=[
                    htc.dashboard.plot.Quote(text=quote_path.read_text())
                ],
            ),
        ]
    )



def misc_stats(ax):
    htc.dashboard.plot.add_annotate_group(
        ax=ax,
        elements=[
            htc.dashboard.plot.Header(
                "sleep",
                color=htc.track.activity_configs()['day']['color'],
                elements=htc.dashboard.stats.sleep_stats(),
            ),
            htc.dashboard.plot.Header(
                "exercise",
                color=htc.track.activity_configs()['exercise']['color'],
                elements=htc.dashboard.stats.days_week_stat('exercise'),
            ),
            htc.dashboard.plot.Header(
                "alcohol",
                color=htc.track.activity_configs()['alcohol']['color'],
                elements=htc.dashboard.stats.days_week_stat('alcohol'),
            ),
            htc.dashboard.plot.Header(
                "journal",
                color=htc.track.activity_configs()['journal']['color'],
                elements=htc.dashboard.stats.days_week_stat('journal'),
            ),
        ]
    )


def writing_stats(
    ax,
    weeks_previous=0,
    months_previous=0,
):
    htc.dashboard.plot.add_annotate_group(
        ax=ax,
        elements=[
            htc.dashboard.plot.Header(
                "writing",
                color=htc.track.activity_configs()['wrote']['color'],
                elements=htc.dashboard.stats.writing_stats(),
            ),
        ]
    )



def weekly_time_spent(
    ax=None,
    days=7,
):
    df = htc.dashboard.data.get()
    df = df[
        -1 * days < df['DeltaDays']
    ]

    set_week_axis_limits(ax, df)
    plot_day_lengths(ax, df)
    plot_timespan_activities(ax, df)


def plot_timespan_activities(ax, df):
    exclusions = ['day']
    df = df.copy()[
        (df['Datatype'] == 'timespan')
        &
        (~df['Activity'].isin(exclusions))
    ]

    activity_configs = htc.track.activity_configs()
    for activity, rows in df.groupby('Activity'):
        rows = rows.copy()
        rows['Color'] = activity_configs[activity]['color']
        rows['Facecolor'] = rows['Color'].apply(hl.plt.color.set_alpha)

        ax.bar(
            rows['DeltaDays'],
            height=rows['Duration'],
            bottom=rows['Start'],
            edgecolor=rows['Color'],
            color=rows['Facecolor'],
        )


def set_week_axis_limits(
    ax,
    df,
    hour_tick_freq=6,
    grid_freq=6,
):
    step = TimeDelta.to_frac(hours=hour_tick_freq)

    time_fractions = list(df['Start']) + list(df['End'])
    time_fractions = [t for t in time_fractions if pd.notna(t)]
    earliest = min(time_fractions)
    latest = max(time_fractions)

    start = 0
    while start + step < earliest:
        start += step

    end = start
    while end < latest:
        end += step

    yticks = np.arange(start, end + step, step)

    htc.dashboard.plot.set_axis(
        ax=ax,
        which='y',
        ticks=list(yticks),
        lim=[start, end],
        labels=[Time.to_string(t, noon_and_midnight=True) for t in yticks],
    )

    hnelib.plt.grid.on_vals(ax, ys=np.arange(start, end + step, step * 2))

    set_day_x_axis(ax, df)


def set_day_x_axis(
    ax,
    df,
    x_col='DeltaDays',
    pad=.5,
    ticklen=None,
    offset=0,
):
    df = df.copy()[
        [
            'Date',
            x_col,
        ]
    ].drop_duplicates().sort_values(by=x_col)

    df['WeekdayName'] = df['Date'].dt.day_name()

    if ticklen:
        df['WeekdayName'] = df['WeekdayName'].apply(lambda s: s[:ticklen])

    ticks = list(df[x_col])
    htc.dashboard.plot.set_axis(
        ax,
        which='x',
        ticks=ticks,
        lim=[ticks[0] - pad, ticks[-1] + pad],
        labels=[l.lower() for l in df['WeekdayName']]
    )


def plot_day_lengths(
    ax,
    df,
    width=.85,
    height_in_minutes=25,
    text_pad_in_minutes=5,
):
    df = df.copy()[
        df['Activity'] == 'day'
    ]

    annotations = []

    xshift = width / 2
    for _, row in df.iterrows():
        x = htc.dashboard.data.delta_days(row['Date'])

        for field, multiplier in zip(['Start', 'End'], [1, -1]):
            xl = x - xshift
            xr = x + xshift

            y1 = row[field]
            y2 = y1 + multiplier * TimeDelta.to_frac(minutes=height_in_minutes)

            ax.plot(
                [xl, xl, xr, xr],
                [y2, y1, y1, y2],
                color=htc.track.dashboard_config()['colors']['ticks'],
                linewidth=2,
                alpha=1,
            )

        annotations.append({
            'label': 'awake',
            'x': x,
            'y': row['End'],
            'value': row['Duration'],
        })

    for _, row in htc.dashboard.data.get_sleep_data(df).iterrows():
        annotations.append({
            'label': 'asleep',
            'x': htc.dashboard.data.delta_days(row['Date']),
            'y': row['End'] - 1,
            'value': row['Duration'],
        })

    text_pad = TimeDelta.to_frac(minutes=text_pad_in_minutes)
    for annotation in annotations:
        ax.annotate(
            f"{TimeDelta.to_string(val=annotation['value'])}h {annotation['label']}",
            xy=(annotation['x'], annotation['y'] + text_pad),
            ha='center',
            va='bottom',
            color=htc.track.dashboard_config()['colors']['text'],
            fontproperties=htc.dashboard.plot.FONTPROPERTIES['annotation'],
        )


#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #
#                                  collection                                  #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#
COLLECTION = {
    # 'field': track,
    # 'substances': substances_plot,
    'weekly-dashboard': weekly_dashboard,
}

runner = hl.runner.PlotRunner(
    collection=COLLECTION,
    directory=htc.constants.FIGURES_DIR / 'track',
    # suffix='.pdf',
)
r = runner
