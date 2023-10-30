from pathlib import Path
import yaml
import string


import htc.constants

class QuoteSet(object):
    DELIMITER = "-"
    PAGE_SUFFIX = ":"
    DEFAULT_QUOTE_TYPE = "tbd"
    CHARS_TO_CONVERT = {
        '’': "'",
        '“': '"',
        '”': '"',
    }

    def __init__(self, source_path=None, author=None, piece=None):
        if source_path:
            self.source_path = source_path
            self.parse_source(source_path.name)
        else:
            self.author = author
            self.piece = piece

    @property
    def has_been_migrated(self):
        return self.piece_metadata_path.exists()

    def migrate(self, rewrite=False):
        if rewrite:
            self.piece_metadata_path.unlink(missing_ok=True)

        if self.piece_metadata_path.exists():
            return

        self.write_piece_quotes()
        self.write_author_metadata()
        self.write_piece_metadata()
        print(f"{self.author}, {self.piece}: {len(self.quotes)}")

    @property
    def author_dir(self):
        return htc.constants.NEW_QUOTES_DIR.joinpath(self.author)

    @property
    def author_metadata_path(self):
        return self.author_dir.joinpath('@.md')

    @property
    def piece_dir(self):
        return self.author_dir.joinpath(self.piece)

    @property
    def author_metadata_path(self):
        return self.author_dir.joinpath('@.md')

    @property
    def piece_metadata_path(self):
        return self.piece_dir.joinpath('@.md')

    def parse_source(self, source_name):
        name = source_name.removesuffix('.md')

        if name.count('.') == 1:
            name = name.replace('_', '-')
            name = name.replace('.', '_')

        author, piece = name.replace('-', ' ').split('_')

        self.author = self.format_author(author)
        self.piece = piece.title()

    def format_author(self, author):
        author = author.title()
        return " ".join([p + '.' if len(p) == 1 else p for p in author.split(' ')])

    def write_author_metadata(self):
        parts = self.author.split()

        metadata = {
            'first name': parts[0],
            'last name': parts[-1],
        }

        if len(parts) > 2:
            metadata['middle name'] = parts[1:-1]

        self.author_metadata_path.parent.mkdir(exist_ok=True, parents=True)
        self.author_metadata_path.write_text(yaml.dump(metadata))

    def write_piece_metadata(self):
        self.piece_metadata_path.write_text(yaml.dump({'title': self.piece}))

    def write_piece_quotes(self):
        self.clean_piece_dir()
        lines = [l for l in self.source_path.read_text().split("\n") if l]

        quotes = []
        for line in lines:
            if len(line) == line.count(self.DELIMITER):
                quotes.append([])
            else:
                if not quotes:
                    quotes.append([])

                quotes[-1].append(line)

        self.quotes = [self.format_quote(q) for q in quotes if len(q)]

        for quote in self.quotes:
            self.write_quote(quote)

    def clean_piece_dir(self):
        self.piece_dir.mkdir(exist_ok=True, parents=True)
        for path in self.piece_dir.glob('*.md'):
            path.unlink()

    def format_quote(self, quote):
        metadata = {
            'type': self.DEFAULT_QUOTE_TYPE,
        }

        if quote[0].endswith(self.PAGE_SUFFIX):
            page = quote[0].removesuffix(self.PAGE_SUFFIX)
            page = page.split('-')[0]
            page = int(page) if page.isnumeric() else page
            metadata['page'] = page
            quote = quote[1:]

        return {
            'metadata': metadata,
            'content': quote,
        }

    def get_quote_path(self, page=""):
        letters = [None] if page else []
        letters.extend(string.ascii_letters)

        while True:
            number = 0
            for letter in letters:
                modifier = f"{letter}{number}" if number else letter
                path = self._get_quote_path([page, modifier])

                if not path.exists():
                    return path

            number += 1

    def _get_quote_path(self, parts):
        parts = [str(p) for p in parts if p]
        stem = "-".join(parts)
        return self.piece_dir.joinpath(f"{stem}.md")

    def get_quote_text(self, quote):
        metadata_text = yaml.dump(quote['metadata'])
        content_text = "\n".join(quote['content'])

        text = f"{metadata_text}\n{content_text}\n"

        for old_char, new_char in self.CHARS_TO_CONVERT.items():
            text = text.replace(old_char, new_char)

        return text

    def write_quote(self, quote):
        text = self.get_quote_text(quote)
        path = self.get_quote_path(quote['metadata'].get('page'))
        path.write_text(text)


class Quote(object):
    DEFAULT_QUOTE_TYPE = "tbd"

    QUOTE_TYPES = [
        'passage',
        'description',
        'perspective',
        'wit',
        'on art',
        'observation',
    ]

    def __init__(self, path):
        self.path = path

        self.author, self.piece = self.path.parent.relative_to(htc.constants.NEW_QUOTES_DIR).parts
        self.parse()

    def parse(self):
        self.text = self.path.read_text()
        metadata, self.content = self.text.split("\n\n")

        self.metadata = yaml.load(metadata, Loader=yaml.Loader)

    @property
    def is_unannotated(self):
        return self.metadata['type'] == self.DEFAULT_QUOTE_TYPE

    def write(self):
        self.path.write_text(f"{yaml.dump(self.metadata)}\n{self.content}")

    def annotate(self):
        lines = [""]
        for word in self.content.strip().split():
            if lines[-1]:
                lines[-1] += " "

            lines[-1] += word

            if len(lines[-1]) > 80:
                lines.append("")

        print("\n" + 90 * "-" + "\n")
        print("\n".join([f"{l}" for l in lines]))
        print(f"\t- {self.piece}, {self.author}, {self.path.stem}\n")

        print(f"annotation:")
        for i, quote_type in enumerate(self.QUOTE_TYPES):
            print(f"{i + 1}: {quote_type}")

        index = int(input()) - 1

        self.metadata['type'] = self.QUOTE_TYPES[index]
        self.write()
