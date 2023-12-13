import hnelib as hl

import htc.track

def writing_stats(df, groupby_cols=None):
    df, groupby_cols = hl.pd.util.get_groupby_cols(df, groupby_cols)

    words = df.copy()[
        df['Activity'] == 'words'
    ]

    words['Words'] = words.groupby(groupby_cols)['Value'].transform('sum')
    words['Words'] = words['Words'].apply(word_count_to_string)
    words['BooleanValue'] = words['Value'].astype(bool)
    words['Days'] = words.groupby(groupby_cols)['BooleanValue'].transform('sum')

    words = words[
        groupby_cols + [
            'Words',
            'Days',
        ]
    ].drop_duplicates()

    wrote = df.copy()[
        df['Activity'] == 'wrote'
    ]

    wrote['Hours'] = wrote.groupby(groupby_cols)['Duration'].transform('sum')
    wrote['Hours'] = wrote['Hours'].apply(hours_to_string)

    wrote = wrote[
        groupby_cols + [
            'Hours',
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

def hours_to_string(hours):
    return round(htc.track.fraction_to_hours(hours), 1)
