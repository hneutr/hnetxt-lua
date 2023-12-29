#!/usr/bin/env python3
import random
import textwrap
import click
import yaml
from pathlib import Path
from collections import defaultdict

import htc.constants
import htc.quotes
import htc.plot


@click.group()
def cli():
    pass


@cli.command()
def quotes():
    exclusions = ['.git', 'readme.md']

    paths = sorted([p for p in htc.constants.OLD_QUOTES_DIR.glob("*") if p.name not in exclusions])

    books = []
    quote_sets = []
    for path in paths:
        quote_set = htc.quotes.QuoteSet(path)

        books.append(f"{quote_set.author}, {quote_set.piece}")

        quote_set.piece_metadata_path.unlink(missing_ok=True)

        if not quote_set.has_been_migrated:
            quote_sets.append(quote_set)

    total = 0
    if len(quote_sets):
        print(f"quote sets to process: {len(quote_sets)}/{len(paths)}")
        for quote_set in quote_sets:
            quote_set.migrate()
            total += len(quote_set.quotes)

    print(f"total quotes: {total}")

@cli.command()
def typeless_quotes():
    exclusions = ['@.md']

    paths = sorted([p for p in htc.constants.NEW_QUOTES_DIR.glob('*/*/*.md') if p.name not in exclusions])

    to_annotate = []
    for path in paths:
        quote = htc.quotes.Quote(path)

        if quote.is_unannotated:
            to_annotate.append(quote)

    if len(to_annotate):
        print(f"quotes to annotate: {len(to_annotate)}/{len(paths)}")
        for quote in to_annotate:
            quote.annotate()


@cli.command()
def add_date_to_thoughts():
    exclusions = ['.git', '.gitignore']

    for path in htc.constants.OLD_THOUGHTS_DIR.glob('*'):
        if path.name in exclusions:
            continue

        date, name = path.name.split('-', 1)

        if path.suffix == '.txt' and date.endswith('0101'):
            date = date.removesuffix('0101') + '0000'

        try:
            text = path.read_text()
        except:
            print(f"vim {path}")

        path.unlink()

        new_text = f"date: {date}\nuncategorized: true\n\n" + text
        new_path = path.with_name(name).with_suffix('.md')
        new_path.write_text(new_text)

@cli.command()
def plot():
    htc.plot.track()


cli()
