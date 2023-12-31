from datetime import timedelta, datetime, date, time
import math

SECONDS = {
    'second': 1,
    'minute': 60,
    'hour': timedelta(hours=1).total_seconds(),
    'day': timedelta(days=1).total_seconds(),
    'week': timedelta(weeks=1).total_seconds(),
}


class TimeFraction(object):
    @classmethod
    def to_delta(cls, val):
        return timedelta(seconds=val * SECONDS['day'])

    @classmethod
    def to_time(cls, val):
        val = val - int(val)
        delta = cls.to_delta(val)

        seconds = delta.total_seconds()
        hours = int(seconds // SECONDS['hour'])
        seconds %= SECONDS['hour']
        minutes = int(seconds // SECONDS['minute'])
        seconds %= SECONDS['minute']
        seconds = int(seconds)
        return time(hour=hours, minute=minutes, second=seconds)

    @classmethod
    def _from(cls, val):
        if isinstance(val, timedelta):
            val = TimeDelta.to_frac(val)
        elif isinstance(val, datetime):
            1

class Time(object):
    @classmethod
    def to_string(
        cls,
        val, 
        hour=True,
        minute=True,
        second=False,
        ampm=True,
        round_minutes_to=None,
        noon_and_midnight=False,
    ):
        val = cls._from(val)

        if not isinstance(val, datetime):
            val = datetime.combine(date=datetime.now().date(), time=val)

        if round_minutes_to:
            minute = round(val.minute / round_minutes_to) * round_minutes_to

            if minute == 60:
                val = val.replace(hour=val.hour + 1, minute=0)
            else:
                val = val.replace(minute=minute)

        fmt_parts = []
        if minute and val.minute:
            fmt_parts.append("%M")

        if second:
            fmt_parts.append("%S")

        if hour:
            fmt_parts.insert(0, "%-I" if ampm else "%-H")

        fmt = ":".join(fmt_parts)

        if ampm:
            fmt += " %p"

        string = val.strftime(fmt)

        if noon_and_midnight:
            if string == '12 PM':
                return 'noon'
            elif string == '12 AM':
                return 'midnight'

        return string

    @classmethod
    def _from(cls, val):
        if isinstance(val, str):
            val = datetime.strptime(val, "%H:%M")
        elif isinstance(val, float):
            val = TimeFraction.to_time(val)

        return val

    @classmethod
    def to_frac(cls, val):
        val = cls._from(val)
        return TimeDelta.to_frac(hours=val.hour, minutes=val.minute)

class DateTime(object):
    @classmethod
    def to_frac(cls, dt):
        return TimeDelta.to_frac(hours=dt.hour, minutes=dt.minute, seconds=dt.second)

class TimeDelta(object):
    @classmethod
    def _from(cls, val=None, **kwargs):
        if isinstance(val, float):
            val = TimeFraction.to_delta(val)
        else:
            val = timedelta(**kwargs)

        return val

    @classmethod
    def to_frac(cls, **kwargs):
        return cls._from(**kwargs).total_seconds() / SECONDS['day']

    @classmethod
    def to_string(cls, unit='hour', round_to=0, **kwargs):
        val = cls._from(**kwargs)
        raw = val.total_seconds() / SECONDS[unit]
        val = math.floor(raw)

        if round_to:
            val += round((raw - val) / round_to) * round_to

        if val == int(val):
            val = int(val)

        return str(val)
