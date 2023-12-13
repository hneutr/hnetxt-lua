import yaml
import matplotlib.pyplot as plt
import functools
from PIL import Image

import htc.constants


def get(config_name):
    path = htc.constants.CONFIG_DIR / f"{config_name}.yaml"
    return yaml.load(path.read_text(), Loader=yaml.Loader)

def get_emoji(name):
    path = htc.constants.EMOJI_DIR / f"{name}.png"
    return Image.open(str(path))
