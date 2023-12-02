from datetime import datetime, timedelta, date
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
import htc.dashboard.data
import htc.dashboard.plot

DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
N_DAYS = len(DAYS)

def add_sections(
    parent_ax,
    sections,
    by='col',
    x_start=0,
    x_stop=1,
    x_pad=.05,
    y_start=0,
    y_stop=1,
    y_pad=.05,
):
    section_info = []

    width = x_stop - x_start
    height = y_stop - y_start

    dynamic_key = 'width' if by == 'col' else 'height'

    for default, key, pad in zip([width, height], ['width', 'height'], [x_pad, y_pad]):
        for section in sections:
            section[key] = section.get(key, default)

        if key == dynamic_key:
            available = default - pad * (len(sections) - 1)
            scale = sum([s[key] for s in sections]) / available
        else:
            scale = default

        for section in sections:
            section[key] /= scale

    x = x_start
    y = y_start

    insets = {}
    for i, section in enumerate(sections):
        inset = parent_ax.inset_axes(
            (
                x,
                y,
                section['width'],
                section['height'],
            )
        )

        if by == 'col':
            x += x_pad + section['width']
        else:
            y += y_pad + section['height']

        name = section.get('name')
        if 'layout' in section:
            hl.plt.axes.hide(inset)
            subinsets = add_sections(inset, **section['layout'])

            if name:
                insets[name] = subinsets
            else:
                insets.update(subinsets)
        else:
            insets[name or i] = inset

    return insets

def get_dashboard_layout(
    pagesize=(18, 11),
    page_margins={'left': .03, 'right': .03, 'top': .03, 'bottom': .03},
    layout={
        'sections': [
            {
                'name': 'week',
                'width': 1.5,
                'layout': {
                    'by': 'row',
                    'sections': [
                        {'name': 'time'},
                        {'name': 'did/not'},
                    ],
                },
            },
            {
                'layout': {
                    'by': 'row',
                    'sections': [
                        {'name': 'month-comparison'},
                        {'name': 'writing'},
                    ],
                }
            },
        ],
    },
):
    fig, page_ax = plt.subplots(figsize=pagesize)
    hl.plt.axes.hide(page_ax)

    dashboard_ax = page_ax.inset_axes(
        (
            page_margins['left'],
            page_margins['top'],
            1 - page_margins['left'] - page_margins['right'],
            1 - page_margins['top'] - page_margins['bottom'],
        )
    )
    hl.plt.axes.hide(dashboard_ax)

    return fig, add_sections(dashboard_ax, **layout)


def weekly_dashboard(
    x_margin=.03,
    y_margin=.03,
    week_width=2/3,
    week_stat_space=.05,
    pagesize=(18, 11),
):
    df = htc.dashboard.data.get()
    df = htc.dashboard.data.get_week_data(df)

    fig, axes = get_dashboard_layout()

    weekly_time_spent(df, axes['week']['time'])
    weekly_habits(df, axes['week']['did/not'])

    compare_months(axes['month-comparison'])
    writing_stats(axes['writing'])

def writing_stats(
    ax,
    last_week=False,
):
    df = htc.dashboard.data.get()
    print(df['Date'].min())
    print(df['Date'].max())
    df = htc.dashboard.data.get_week_data(df, last_week=last_week)
    print(df['Date'].min())
    print(df['Date'].max())
    import sys; sys.exit()

    ax.set_xticks([])
    ax.set_yticks([])

    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)

    ax.set_facecolor(htc.config.get('colors')['surface0'])

    x_margin = .02
    y_margin = -.02

    x = 0
    y = 1

    x += x_margin
    y += y_margin

    kwargs = {
        'xycoords': 'axes fraction',
        'ha': 'left',
        'va': 'top',
    }

    words_df = df.copy()[
        df['Activity'] == 'words'
    ]

    words_written = words_df['Value'].sum()
    days_written = len(words_df)

    wrote_df = df.copy()[
        df['Activity'] == 'wrote'
    ]

    hours_written = round(htc.track.fraction_to_hours(wrote_df['Duration'].sum()), 1)

    if words_written > 1000:
        words_written /= 1000
        words_written = round(words_written, 1)
        words_written = str(words_written) + "K"

    htc.dashboard.plot.stat_group(
        ax,
        header="writing",
        stats={
            "words this week": words_written,
            "days this week": days_written,
            "hours this week": hours_written,
        },
        color=htc.config.get('colors')['flamingo'],
    )


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
    df,
    ax=None,
):
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
        df['Weekday'],
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
    step = htc.track.timedelta_to_fraction(timedelta(hours=hour_tick_freq))

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
    yticklabels = []
    ygrid = []
    for tick in yticks:
        hour = int(htc.track.fraction_to_hours(tick))

        if not hour % grid_freq:
            ygrid.append(tick)

        hour = hour % 24

        if hour == 0:
            label = 'midnight'
        elif hour < 12:
            label = f"{hour} AM"
        elif hour == 12:
            label = 'noon'
        else:
            label = f"{hour - 12} PM"

        yticklabels.append(label)

    ax.set_ylim(start, end)
    ax.set_yticks(yticks)
    ax.set_yticklabels(yticklabels)

    hnelib.plt.grid.on_vals(ax, ys=ygrid)

    set_week_x_axis(ax)


def plot_day_lengths(
    ax,
    df,
    width=.85,
    height_in_minutes=20,
):
    kwargs = {
        'color': hl.plt.color.named_grayscale['gray'],
        'linewidth': 2,
    }

    df = df.copy()[
        df['Activity'] == 'day'
    ]

    height = htc.track.timedelta_to_fraction(timedelta(minutes=15))

    xshift = width / 2
    for _, day in df.iterrows():

        for prefix, multiplier in zip(['Start', 'End'], [1, -1]):
            xl = day['Weekday'] - xshift
            xr = day['Weekday'] + xshift

            y1 = day[f'{prefix}Fraction']
            y2 = y1 + height * multiplier

            ax.plot(
                [xl, xl, xr, xr],
                [y2, y1, y1, y2],
                **kwargs,
            )

        # if not pd.isnull(day['Slept']):
        #     hours = round(htc.track.fraction_to_hours(day['SleptFraction']), 1)
        #     hl.plt.text.annotate(
        #         ax,
        #         text=f"{hours} hours of sleep",
        #         x=day['Weekday'],
        #         y=day['StartFraction'] - height,
        #         ha='center',
        #         va='top',
        #     )

        # hours = round(htc.track.fraction_to_hours(day['EndFraction'] - day['StartFraction']), 1)
        # hl.plt.text.annotate(
        #     ax,
        #     text=f"{hours} hour day",
        #     x=day['Weekday'],
        #     y=day['EndFraction'] + height,
        #     ha='center',
        #     va='bottom',
        # )


def weekly_writing_dashboard(
    df,
    ax=None,
):
    config = htc.track.activity_configs()
    writing_color = hl.plt.color.cycle[2]

    if not ax:
        fig, ax = plt.subplots(figsize=hl.plt.dims[1, 1])

    words_df = df.copy()[
        df['Activity'] == 'words'
    ]

    words_df['Color'] = writing_color


    hl.plt.bar(
        ax,
        df=words_df,
        size_col='Value',
        place_col='Weekday',
        tick_label_col='WeekdayName',
        bar_color_col='Color',
    )

    ax.set_xlim(-.5, 6.5)

    average = words_df['Value'].mean()

    x_lim = ax.get_xlim()
    ax.axhline(
        average,
        color=writing_color,
    )


    hl.plt.text.annotate(
        ax,
        f"{round(average)}/day\n{words_df['Value'].sum()} total",
        x=ax.get_xlim()[1],
        y=average,
        x_pad=.1,
        ha='left',
    )

    ax.set_ylim(0, 1000)
    ax.set_yticks([0, 250, 500, 750, 1000])


def compare_months(
    ax=None,
    period_days=30,
):
    if not ax:
        fig, ax = plt.subplots(figsize=hl.plt.dims[1, 1])

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
    'test-weekly-dashboard': {
        'do': weekly_dashboard,
        'kwargs': {'test': True},
    },
    'compare-months': compare_months,
}

runner = hl.runner.PlotRunner(
    collection=COLLECTION,
    directory=htc.constants.FIGURES_DIR / 'track',
)
r = runner
