from datetime import datetime
import hnelib as hl

import htc.track
from htc.datatype import TimeDelta, Time

def sleep_stats():
    df = htc.dashboard.data.get_sleep_data(htc.dashboard.data.get())

    stats = {}
    label_to_key = {
        'went to bed': 'Start',
        'got up': 'End',
        'hours': 'Duration',
    }

    for label, key in label_to_key.items():
        if key == 'Duration':
            stats[label] = TimeDelta.to_string(val=df[key].mean(), round_to=.25)
        else:
            stats[label] = Time.to_string(val=df[key].mean(), round_minutes_to=15)

    return stats

def days_week_stat(activity):
    df = htc.dashboard.data.get()
    df = df[
        df['Activity'] == activity
    ]

    total_days = len(df)
    days = len(df[df['Value']])
    rate = days / total_days
    days = round(rate * 7)
    remainder = rate * 7 - days
    rate = days + (round(remainder * 100 / 25) / 100 * 25)

    rate = round(rate / .25) * .25

    if int(rate) == rate:
        rate = int(rate)

    return {
        "days/week": rate
    }



# def writing_stats_df(df, groupby_cols=None):
def writing_stats_df(df, groupby_cols=None):
    df, groupby_cols = hl.pd.util.get_groupby_cols(df, groupby_cols)

    words = df.copy()[
        df['Activity'] == 'words'
    ]

    words['Words'] = words.groupby(groupby_cols)['Value'].transform('sum')
    words['Words'] = words['Words'].apply(word_count_to_string)
    words['BooleanValue'] = words['Value'].astype(bool)

    words = words[
        groupby_cols + [
            'Words',
        ]
    ].drop_duplicates()

    wrote = df.copy()[
        df['Activity'] == 'wrote'
    ]

    wrote['Hours'] = wrote.groupby(groupby_cols)['Duration'].transform('sum')
    wrote['Hours'] = wrote['Hours'].apply(lambda t: TimeDelta.to_string(val=t, round_to=.25))
    wrote['BooleanValue'] = wrote['Value'].astype(bool)
    wrote['Days'] = wrote.groupby(groupby_cols)['BooleanValue'].transform('sum')

    wrote = wrote[
        groupby_cols + [
            'Hours',
            'Days',
        ]
    ].drop_duplicates()

    df = words.merge(
        wrote,
        on=groupby_cols
    )

    df = df.sort_values(by=groupby_cols, ascending=False)
    return hl.pd.util.remove_fake_cols(df)

def writing_stats(
    weeks_previous=0,
    months_previous=0,
):
    df = htc.dashboard.data.get()

    ny_date = datetime(year=2023, month=8, day=18)

    sections = {
        'this week': {
            'groupby_cols': ['DeltaWeeks'],
            'stats': ['Words', 'Days', 'Hours'],
            'filters': {'DeltaWeeks': weeks_previous},
        },
        'in NY': {
            'stats': ['Words'],
            'df': df[df['Date'] > ny_date]
        }

    }
    stats = {}
    for label, section in sections.items():
        section_df = writing_stats_df(section.get('df', df), groupby_cols=section.get('groupby_cols'))
        for col, val in section.get('filters', {}).items():
            section_df = section_df[
                section_df[col] == val
            ]

        section_stats = {} if section_df.empty else section_df.iloc[0]

        stats[label] = {stat.lower(): section_stats.get(stat, 0) for stat in section['stats']}

    return stats

def word_count_to_string(words):
    if words > 1000:
        words /= 1000
        words = round(words, 1)
        words = str(words) + "K"

    return str(words)
