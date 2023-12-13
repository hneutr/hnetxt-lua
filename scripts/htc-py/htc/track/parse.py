import functools
import pandas as pd
from datetime import datetime

import htc.config
import htc.constants

ENTRY_DIR = htc.constants.DATA_DIR / htc.config.get('track')['data_dir']
TEST_ENTRY_DIR = htc.constants.TEST_DATA_DIR
SEPARATOR = htc.config.get('track')['separator']


def get_raw(test=False):
    entry_dir = TEST_DATA_DIR if test else ENTRY_DIR

    rows = []
    for entry in entry_dir.glob("*.md"):
        date = datetime.strptime(entry.stem, "%Y%m%d")

        for line in entry.read_text().split("\n"):
            if not len(line):
                continue

            activity, value = [s.strip() for s in line.split(SEPARATOR, 1)]
            
            rows.append({
                'Date': date,
                'Activity': activity,
                'Value': value,
            })

    return pd.DataFrame(rows)
