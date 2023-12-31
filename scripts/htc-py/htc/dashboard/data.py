import functools
import re
import pandas as pd
import subprocess
from datetime import datetime, timedelta, date

import htc.config
import htc.constants
import htc.track
from htc.datatype import Time, TimeDelta

DAY_SECONDS = timedelta(days=1).total_seconds()
HOUR_SECONDS = timedelta(hours=1).total_seconds()
WEEK_SECONDS = timedelta(weeks=1).total_seconds()

def get(
    test=False,
    date_filter=None,
):
    df = htc.track.parse.get_raw(test=test)
    df['Weekday'] = df['Date'].dt.weekday

    df = annotate_dates(df)
    df = transform_data(df)
    return df


def infer_datatype(value):
    for datatype in get_datatypes():
        if datatype.is_type(value):
            return datatype.NAME


def transform_data(df):
    df['Datatype'] = df['Value'].apply(infer_datatype)
    df = df[
        df['Datatype'].notna()
    ]

    new_rows = []
    for _, row in df.iterrows():
        datatype = get_datatypes_by_name().get(row['Datatype'])

        if datatype and datatype.include(row['Value']):
            new_rows.append(datatype.transform_row(row.to_dict()))

    df = pd.DataFrame(new_rows)
    df['BooleanValue'] = df['Value'].apply(bool)
    df = annotate_dates(df)

    return df


def get_sleep_data(df):
    df = df.copy()[
        df['Activity'] == 'day'
    ]

    other_df = get()
    other_df = other_df[
        other_df['Activity'] == 'day'
    ]

    sleep_rows = []
    for _, day in df.iterrows():
        date = day['Date']
        previous_day = other_df[
            other_df['Date'] == date - timedelta(days=1)
        ]

        if previous_day.empty:
            continue

        previous_day = previous_day.iloc[0]
        start = previous_day['End']

        end = day['Start'] + 1

        sleep_rows.append({
            'Activity': 'slept',
            'Date': date,
            'Start': start,
            'End': end,
            'Duration': end - start,
        })

    return pd.DataFrame(sleep_rows)


class Datatype(object):
    NAME = ''

    def default(self):
        return htc.config.get('track')['datatype_defaults'][self.NAME]

    def to_boolean(self, val):
        return bool(val)

    def include(self, val):
        return True

    def is_type(self, val):
        return False

    def transform(self, val):
        return val

    def transform_row(self, row):
        row['Value'] = self.transform(row['Value'])
        return row


class BooleanDatatype(Datatype):
    NAME = 'boolean'
    RAW_TRANFORM = {
        'true': True,
        'false': False,
    }

    def is_type(self, val):
        return self.RAW_TRANFORM.get(val) != None

    def transform(self, val):
        return self.RAW_TRANFORM[val]


class NumberDatatype(Datatype):
    NAME = 'number'
    def is_type(self, val):
        return val.isdigit()

    def transform(self, val):
        return int(val)


class TimeDatatype(Datatype):
    NAME = 'time'
    RE = re.compile("^\d\d:\d\d$")

    def is_type(self, val):
        return val == self.default() or self.RE.match(val)

    def include(self, val):
        return bool(self.RE.match(val))

    def transform_row(self, row):
        row['Value'] = Time.to_frac(row['Value'])
        return row

class TimespanDatatype(TimeDatatype):
    NAME = 'timespan'
    RE = re.compile("^(\d\d:\d\d)\-(\d\d:\d\d)$")

    def is_type(self, val):
        return val == self.default() or self.RE.match(val)

    def include(self, val):
        return bool(self.RE.match(val))

    def transform_row(self, row):
        match = self.RE.match(row['Value'])
        start, end = match[1], match[2]

        row['Start'] = Time.to_frac(start)
        row['End'] = Time.to_frac(end)

        if row['End'] < row['Start']:
            row['End'] += 1
        
        row['Duration'] = row['End'] - row['Start']

        return row


@functools.lru_cache
def get_datatypes():
    return [
        BooleanDatatype(),
        NumberDatatype(),
        TimespanDatatype(),
        TimeDatatype(),
    ]

@functools.lru_cache
def get_datatypes_by_name():
    return {d.NAME: d for d in get_datatypes()}


def week_start(d=datetime.now()):
    return datetime(year=d.year, month=d.month, day=d.day) - timedelta(days=d.weekday())

def delta_months(d):
    now = datetime.now()
    years = d.year - now.year
    months = d.month - now.month
    return 12 * years + months

def delta_weeks(d):
    delta = week_start(d) - week_start()
    return int(delta.total_seconds() / WEEK_SECONDS)

def delta_days(d):
    delta = date(year=d.year, month=d.month, day=d.day) - date.today()
    return int(delta.total_seconds() / DAY_SECONDS)

def annotate_dates(df):
    df['DeltaDays'] = df['Date'].apply(delta_days)
    df['DeltaWeeks'] = df['Date'].apply(delta_weeks)
    df['DeltaMonths'] = df['Date'].apply(delta_months)
    return df
