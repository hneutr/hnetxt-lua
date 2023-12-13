from datetime import datetime, timedelta, date, time

class Time(object):
    MINUTE_SECONDS = 60
    HOUR_SECONDS = timedelta(hours=1).total_seconds()
    DAY_SECONDS = timedelta(days=1).total_seconds()
    WEEK_SECONDS = timedelta(weeks=1).total_seconds()

    @classmethod
    def delta_to_fraction(cls, delta):
        return delta.total_seconds() / cls.DAY_SECONDS

    @classmethod
    def delta_to_time(cls, delta):
        seconds = delta.total_seconds()
        hours = int(seconds // cls.HOUR_SECONDS)
        seconds %= cls.HOUR_SECONDS
        minutes = int(seconds // cls.MINUTE_SECONDS)
        seconds %= cls.MINUTE_SECONDS
        seconds = int(seconds)

        hours %= 24
        minutes %= 60

        return time(hour=hours, minute=minutes, second=seconds)

    @classmethod
    def time_to_fraction(cls, time):
        return cls.delta_to_fraction(timedelta(hours=time.hour, minutes=time.minute, seconds=time.second))

    @classmethod
    def fraction_to_delta(cls, fraction):
        return timedelta(seconds=fraction * cls.DAY_SECONDS)

    @classmethod
    def fraction_to_time(cls, fraction):
        return cls.delta_to_time(cls.fraction_to_delta(fraction))

    @classmethod
    def to_string(
        cls,
        time,
        hour=True,
        minute=True,
        second=False,
        ampm=True,
        round_minutes_to=None,
        noon_and_midnight=False,
    ):
        if isinstance(time, float):
            time = cls.fraction_to_time(time)
        elif isinstance(time, timedelta):
            ampm = False
            time = cls.delta_to_time(time)

        if not isinstance(time, datetime):
            time = datetime.combine(date=datetime.now().date(), time=time)

        if round_minutes_to:
            minute = round(time.minute / round_minutes_to) * round_minutes_to

            if minute == 60:
                time = time.replace(hour=time.hour + 1, minute=0)
            else:
                time = time.replace(minute=minute)

        fmt_parts = []
        if minute and time.minute:
            fmt_parts.append("%M")

        if second:
            fmt_parts.append("%S")

        if hour:
            fmt_parts.insert(0, "%-I" if ampm else "%-H")

        fmt = ":".join(fmt_parts)

        if ampm:
            fmt += " %p"

        string = time.strftime(fmt)

        if noon_and_midnight:
            if string == '12 PM':
                return 'noon'
            elif string == '12 AM':
                return 'midnight'

        return string
