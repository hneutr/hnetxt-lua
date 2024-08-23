import yaml
import matplotlib.pyplot as plt

import htc.constants


def get(config_name):
    path = htc.constants.CONFIG_DIR / f"{config_name}.yaml"
    return yaml.load(path.read_text(), Loader=yaml.Loader)
