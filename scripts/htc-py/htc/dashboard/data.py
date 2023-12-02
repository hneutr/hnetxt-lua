import functools
import re
import pandas as pd
import subprocess
from datetime import datetime, timedelta, date

import htc.config
import htc.constants

DAY_SECONDS = timedelta(days=1).total_seconds()
HOUR_SECONDS = timedelta(hours=1).total_seconds()

@functools.lru_cache
def csv_path(test=False):
    config = htc.config.get('track')
    data_dir = htc.constants.TEST_DATA_DIR if test else htc.constants.DATA_DIR / config['data_dir']
    return data_dir / config['csv_name']


def regenerate_csv():
    x = subprocess.run(
        " ".join([
            f"cd {htc.constants.LUA_ROOT}",
            "&&",
            f"luarocks test {htc.constants.TRACKER_SCRIPT}",
        ]),
        shell=True,
        # capture_output=True,
    )

def get(
    date_filter=None,
    test=False,
    datatype=None,
):
    regenerate_csv()
    import sys; sys.exit()
    df = pd.read_csv(
        csv_path(test=test),
        parse_dates=["date"]
    ).rename(columns={
        'date': 'Date',
        'activity': 'Activity',
        'value': 'Value',
    })

    df['Weekday'] = df['Date'].dt.weekday
    df['WeekdayName'] = df['Date'].dt.day_name()

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
    df = add_sleep(df)
    df['BooleanValue'] = df['Value'].apply(bool)

    return df


def add_sleep(df):
    _df = df.copy()[
        df['Activity'] == 'day'
    ]

    sleep_rows = []
    for _, day in _df.iterrows():
        previous_day = _df[
            _df['Date'] == day['Date'] - timedelta(days=1)
        ]

        if previous_day.empty:
            continue

        sleep_rows.append({
            'Activity': 'slept',
            'Date': day['Date'],
            'Value': day['Start'] - previous_day.iloc[0]['End'],
        })


    return pd.concat([df, pd.DataFrame(sleep_rows)])


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
        row['Value'] = self.time_to_datetime(row['Value'], row['Date'])
        return row

    @staticmethod
    def time_to_datetime(time, date):
        time = datetime.strptime(time, "%H:%M")
        return date + timedelta(hours=time.hour, minutes=time.minute)

    @staticmethod
    def time_to_fraction(time, date):
        td = time - date
        return td.total_seconds() / DAY_SECONDS


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
        row['Start'] = self.time_to_datetime(start, row['Date'])
        row['End'] = self.time_to_datetime(end, row['Date'])
        if row['End'] < row['Start']:
            row['End'] += timedelta(days=1)

        row['StartFraction'] = self.time_to_fraction(row['Start'], row['Date'])
        row['EndFraction'] = self.time_to_fraction(row['End'], row['Date'])
        row['Duration'] = row['EndFraction'] - row['StartFraction']

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



def get_week_data(
    df,
    last_week=False,
):
    today = datetime.today()
    week_start = datetime(year=today.year, month=today.month, day=today.day) - timedelta(days=today.weekday())

    if last_week:
        week_start -= timedelta(days=7)
        
    week_end = week_start + timedelta(days=7)

    df = df.copy()[
        (week_start <= df['Date'])
        &
        (df['Date'] < week_end)
    ]

    return df


class Parser(object):
    ENTRY_DIR = htc.constants.

    def __init__(self):
        1

    @functools.cached_property
    def entry_dir(self):
        config = htc.config.get('track')
        return htc.constants.DATA_DIR / config['data_dir']

    def parse()
