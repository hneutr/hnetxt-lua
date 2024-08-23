#!/usr/bin/env python3
import random
import textwrap
import click
import yaml
from pathlib import Path
from collections import defaultdict

import htc.constants
import htc.plot


@click.group()
def cli():
    pass


@cli.command()
def plot():
    htc.plot.track()


cli()
