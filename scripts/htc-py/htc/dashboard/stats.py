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

def exercise_stats():
    df = htc.dashboard.data.get()
    df = df[
        df['Activity'] == 'exercise'
    ]

    total_days = len(df)
    days = len(df[df['Value']])
    rate = days / total_days
    days = round(rate * 7)
    remainder = rate * 7 - days
    exercised_per_week = days + (round(remainder * 100 / 25) / 100 * 25)

    return {
        "days/week": exercised_per_week
    }


def writing_stats(df, groupby_cols=None):
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

    return hl.pd.util.remove_fake_cols(words.merge(
        wrote,
        on=groupby_cols
    ))

def word_count_to_string(words):
    if words > 1000:
        words /= 1000
        words = round(words, 1)
        words = str(words) + "K"

    return str(words)
