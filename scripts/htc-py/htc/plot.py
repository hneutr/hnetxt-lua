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

DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
N_DAYS = len(DAYS)

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
                x_pad=x_pad,
                y_pad=y_pad,
                facecolor=facecolor,
                **section['layout'],
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
            'name': 'week',
            'width': 1.5,
            'layout': {
                'by': 'row',
                'sections': [
                    {'name': 'did/not'},
                    {'name': 'time'},
                ],
            },
        },
        {
            'layout': {
                'by': 'row',
                'sections': [
                    {'name': 'month-comparison'},
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
    df = htc.dashboard.data.get()
    df = df[
        df['DeltaWeeks'] == 0
    ]

    fig, axes = get_dashboard_layout()

    weekly_time_spent(axes['week']['time'])
    # weekly_habits(df, axes['week']['did/not'])

    compare_months(axes['month-comparison'])
    writing_stats(axes['text']['writing'])
    misc_stats(axes['text']['misc'])

    # hl.plt.axes.hide(axes['text']['misc'])

def misc_stats(
    ax,
):
    df = htc.dashboard.data.get()
    sleep_df = htc.dashboard.data.get_sleep_data(df)

    stats = {}
    label_to_key = {
        'went to bed': 'Start',
        'got up': 'End',
        'hours': 'Duration',
    }

    for label, key in label_to_key.items():
        stats[label] = htc.dashboard.datatype.Time.to_string(sleep_df[key].mean(), round_minutes_to=15)

    ex_df = df.copy()[
        df['Activity'] == 'exercise'
    ]
    total_days = len(ex_df)
    ex_days = len(ex_df[ex_df['Value']])
    ex_rate = ex_days / total_days
    ex_days = round(ex_rate * 7)
    remainder = ex_rate * 7 - ex_days
    exercised_per_week = ex_days + (round(remainder * 100 / 25) / 100 * 25)

    htc.dashboard.plot.AnnotationGroup(
        elements=[
            htc.dashboard.plot.Header(
                "sleep",
                color=htc.config.get('colors')['blue'],
                elements=stats,
            ),
            htc.dashboard.plot.Header(
                "exercise",
                color=htc.config.get('colors')['green'],
                elements={
                    "days per week": exercised_per_week
                }
            ),
        ]
    ).annotate(ax)


def writing_stats(
    ax,
    weeks_previous=0,
    months_previous=0,
):
    df = htc.dashboard.data.get()

    stat_names = [
        'Words',
        'Days',
        'Hours',
    ]

    weekly_df = htc.dashboard.stats.writing_stats(df, groupby_cols=['DeltaWeeks'])
    this_week = weekly_df[
        weekly_df['DeltaWeeks'] == weeks_previous
    ]

    monthly_df = htc.dashboard.stats.writing_stats(df, groupby_cols=['DeltaMonths'])
    this_month = monthly_df[
        monthly_df['DeltaMonths'] == months_previous
    ]

    ny_date = datetime(year=2023, month=8, day=18)
    new_york_df = htc.dashboard.stats.writing_stats(df[df['Date'] > ny_date])

    label_to_df = {
        'this week': this_week,
        # 'this month': this_month,
        'in NY': new_york_df,
    }

    stats = {}
    for label, df in label_to_df.items():
        row = {} if df.empty else df.iloc[0]
        stats[label] = {s.lower(): row.get(s, 0) for s in stat_names}

    htc.dashboard.plot.AnnotationGroup(
        elements=[
            htc.dashboard.plot.Header(
                "writing",
                color=htc.config.get('colors')['flamingo'],
                elements=stats,
            ),
        ]
    ).annotate(ax)



def weekly_habits(
    df,
    ax=None,
    activity_height=1,
):
    color = hl.plt.color.cycle[2]
    if not ax:
        fig, ax = plt.subplots(figsize=hl.plt.dims[1, 1])

    activities = htc.track.activity_configs(datatype='boolean')
    activity_categories = {activity['category'] for activity in activities.values()}
    categories = {c: conf for c, conf in htc.track.category_configs().items() if c in activity_categories}
    categories_list = list(categories)

    activities_list = []
    for category, config in categories.items():
        activities_list += [a for a in config['activities'] if a in activities]

    df = df.copy()[
        df['Activity'].isin(activities.keys())
    ]

    df['Category'] = df['Activity'].apply(lambda a: activities[a]['category'])
    df['CategoryIndex'] = df['Category'].apply(lambda c: categories_list.index(c))
    df['ActivityIndex'] = df['Activity'].apply(lambda a: activities_list.index(a))

    df['ActivityOrder'] = df['CategoryIndex'] * activity_height
    df['ActivityOrder'] += df['ActivityIndex'] * activity_height
    df['Emoji'] = df['Activity'].apply(lambda a: activities[a]['emoji'])
    df['Height'] = activity_height
    df['Bar'] = [i for i in range(len(df))]
    df['Color'] = color

    df['MarkerFaceColor'] = df['Value'].apply(lambda v: 'w' if v else hl.plt.color.set_alpha(color))
    df['FaceColor'] = df['Value'].apply(lambda v: hl.plt.color.set_alpha(color) if v else 'w')
    df['Marker'] = df['Value'].apply(lambda v: 'o' if v else 'X')

    set_week_x_axis(ax)

    ax.barh(
        df['ActivityOrder'],
        df['Height'],
        left=df['Weekday'] - .5,
        color=df['FaceColor'],
        edgecolor=df['Color'],
    )

    for marker, rows in df.groupby('Marker'):
        ax.scatter(
            rows['Weekday'],
            rows['ActivityOrder'],
            marker=marker,
            edgecolor=rows['Color'],
            color=rows['MarkerFaceColor'],
            s=500,
        )

    ax.set_ylim(0 - activity_height / 2, df['ActivityOrder'].max() + (activity_height / 2))

    activities_df = df[
        [
            'Activity',
            'ActivityOrder',
            'Emoji',
        ]
    ].drop_duplicates().sort_values(by='ActivityOrder')

    ax.set_yticks(list(activities_df['ActivityOrder']))
    ax.set_yticklabels(activities_df['Activity'])

    for _, row in activities_df.iterrows():
        htc.dashboard.plot.add_emoji(
            ax,
            row['Emoji'],
            x=ax.get_xlim()[0],
            y=row['ActivityOrder'],
            ha='left',
        )


def weekly_time_spent(
    ax=None,
    days=7,
):
    df = htc.dashboard.data.get()
    df = df[
        -1 * days < df['DeltaDays']
    ]

    if not ax:
        fig, ax = plt.subplots(figsize=hl.plt.dims[1, 1])

    set_week_axis_limits(ax, df)

    plot_day_lengths(ax, df)

    df = df.copy()[
        df['Activity'] == 'wrote'
    ]

    df['DurationFraction'] = df['EndFraction'] - df['StartFraction']
    df['Color'] = hl.plt.color.cycle[2]
    df['Facecolor'] = df['Color'].apply(hl.plt.color.set_alpha)

    ax.bar(
        df['DeltaDays'],
        height=df['DurationFraction'],
        bottom=df['StartFraction'],
        edgecolor=df['Color'],
        color=df['Facecolor'],
    )


def set_week_x_axis(
    ax,
    pad=.5,
    ticklen=None,
    offset=0,

):
    ticks = DAYS.copy()

    if ticklen:
        ticks = [t[:ticklen] for t in ticks]

    ax.set_xlim(offset - pad, offset + N_DAYS - pad)
    ax.set_xticks([i + offset for i in range(N_DAYS)])
    ax.set_xticklabels(ticks)


def set_week_axis_limits(
    ax,
    df,
    hour_tick_freq=3,
    grid_freq=6,
):
    step = htc.dashboard.datatype.Time.delta_to_fraction(timedelta(hours=hour_tick_freq))

    time_fractions = list(df['StartFraction']) + list(df['EndFraction'])
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
    yticklabels = [htc.dashboard.datatype.Time.to_string(t, noon_and_midnight=True) for t in yticks]

    # ax.set_ylim(start, end)
    # ax.set_yticks(yticks)
    # ax.set_yticklabels(yticklabels)

    htc.dashboard.plot.set_axis(
        ax=ax,
        which='y',
        ticks=list(yticks),
        lim=[start, end],
        labels=list(yticklabels),
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
        labels=list(df['WeekdayName']),
    )


def plot_day_lengths(
    ax,
    df,
    width=.85,
    height_in_minutes=10,
):
    text_color = htc.track.dashboard_config()['colors']['text']

    kwargs = {
        'color': hl.plt.color.named_grayscale['gray'],
        'linewidth': 1.5,
    }

    df = df.copy()[
        df['Activity'] == 'day'
    ]

    height = htc.dashboard.datatype.Time.delta_to_fraction(timedelta(minutes=height_in_minutes))

    xshift = width / 2
    for _, row in df.iterrows():
        x = htc.dashboard.data.delta_days(row['Date'])

        for prefix, multiplier in zip(['Start', 'End'], [1, -1]):
            xl = x - xshift
            xr = x + xshift

            y1 = row[f'{prefix}Fraction']
            y2 = y1 + height * multiplier

            ax.plot(
                [xl, xl, xr, xr],
                [y2, y1, y1, y2],
                **kwargs,
            )

        hours = htc.dashboard.datatype.Time.to_string(row['Duration'], minute=False, ampm=False)

        ax.annotate(
            f"{hours} hour day",
            xy=(x, row['EndFraction'] + height),
            ha='center',
            va='bottom',
            color=text_color,
        )

    for _, row in htc.dashboard.data.get_sleep_data(df).iterrows():
        hours = htc.dashboard.datatype.Time.to_string(row['Duration'], minute=False)
        ax.annotate(
            f"{hours} hours of sleep",
            xy=(
                htc.dashboard.data.delta_days(row['Date']),
                htc.dashboard.datatype.Time.time_to_fraction(row['End']) - height
            ),
            ha='center',
            va='top',
            color=text_color,
        )

def compare_months(
    ax=None,
    period_days=30,
):
    if not ax:
        fig, ax = plt.subplots(figsize=hl.plt.dims[1, 1])

    ax.set_facecolor(htc.config.get('colors')['surface1'])
    hl.plt.axes.hide_ticks(ax)
    x_margin = .05
    y_margin = scale_y(x_margin)
    ax = ax.inset_axes((x_margin, y_margin, 1 - 2 * x_margin, 1 - 2 * y_margin))

    df = htc.dashboard.data.get()

    start_of_current_period = datetime.today() - timedelta(days=period_days)
    start_of_previous_period = start_of_current_period - timedelta(days=period_days)

    df = df[
        df['Activity'].isin(htc.config.get('track')['comparison_activities'])
    ]

    df = df[
        df['Date'] >= start_of_previous_period
    ]

    df['Period'] = df['Date'] >= start_of_current_period

    df['Did'] = df.groupby(['Activity', 'Period'])['BooleanValue'].transform('sum')
    df['DidFraction'] = df['Did'] / period_days

    df = df[
        [
            'Activity',
            'Period',
            'Did',
            'DidFraction',
        ]
    ].drop_duplicates()

    df['Color'] = hl.plt.color.cycle[0]
    df['FaceColor'] = df.apply(lambda r: r['Color'] if r['Period'] else 'w', axis=1)

    bars_df = hl.plt.bar(
        ax=ax,
        df=df,
        size_col='Did',
        bar_edge_color_col='Color',
        bar_color_col='FaceColor',
        stack_col='Period',
        group_col='Activity',
        tick_label_col='Activity',
        separate_groups=False,
    )
    ax.set_ylim([0, period_days])

    ticklabels = np.arange(1, 8)
    ticks = [t / 7 * period_days for t in ticklabels]

    ax.set_yticks(ticks)
    ax.set_yticklabels(ticklabels)
    ax.set_ylabel(r"$\frac{days}{week}$")

    hl.plt.grid.on_ticks(ax, x=False)





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
    'compare-months': compare_months,
}

runner = hl.runner.PlotRunner(
    collection=COLLECTION,
    directory=htc.constants.FIGURES_DIR / 'track',
)
r = runner
