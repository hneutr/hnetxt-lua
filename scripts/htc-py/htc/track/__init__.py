import functools
import pandas as pd
from datetime import datetime, timedelta, date

import htc.config
import htc.constants
import htc.track.parse as parse

def dashboard_config():
    config = htc.config.get('dashboard')
    colors = htc.config.get('colors')
    config['colors'] = {k: colors[v] for k, v in config['colors'].items()}
    return config

@functools.lru_cache
def activity_configs(datatype=None):
    order = 0
    configs = {}
    for category_config in htc.config.get('track')['categories']:
        category_name = category_config['name']

        category_order = 0
        for config in category_config['activities']:
            activity_name = config.pop('name')
            config['category'] = category_name
            config['order'] = order
            order += 1

            config['category order'] = category_order
            category_order += 1

            if datatype and datatype != config['datatype']:
                continue

            configs[activity_name] = config

    configs = annotate_datatype_defaults(configs)
    configs = annotate_colors(configs)

    return configs

def annotate_datatype_defaults(configs):
    datatype_defaults = htc.config.get('track')['datatype_defaults']
    for config in configs.values():
        config['default'] = datatype_defaults[config.get('datatype', 'boolean')]

    return configs

def annotate_colors(configs, src_key='color', dst_key='color'):
    colors = htc.config.get('colors')

    for config in configs.values():
        if src_key in config:
            config[dst_key] = colors[config[src_key]]

    return configs


@functools.lru_cache
def category_configs():
    track_config = htc.config.get('track')

    order = 0
    categories = {}
    for category in track_config['categories']:
        category_name = category.pop('name')
        category['activities'] = [activity.pop('name') for activity in category['activities']]
        categories[category_name] = category

    return categories
