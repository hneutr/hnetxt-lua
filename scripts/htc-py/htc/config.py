import yaml
import htc.constants
import matplotlib.pyplot as plt
from PIL import Image

def get(config_name):
    path = htc.constants.CONFIG_DIR / f"{config_name}.yaml"
    return yaml.load(path.read_text(), Loader=yaml.Loader)

def get_emoji(name):
    path = htc.constants.EMOJI_DIR / f"{name}.png"
    return Image.open(str(path))
