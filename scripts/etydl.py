import requests
import time
import textwrap
from pathlib import Path
from bs4 import BeautifulSoup

DEFINITION_CLASS = "word__defination--2q7ZH"
LANGUAGE_DIR = Path.home() / "eidola/language"

def modify_asterisk(s):
    return s.replace(
        "[etymonline](https://www.etymonline.com/word/*",
        "[etymonline](https://www.etymonline.com/word/\*",
    )

def get_url(lines):
    for line in lines:
        line = line.strip()

        if line.startswith("[etymonline](") and line.endswith(")"):
            return line.removeprefix("[etymonline](").removesuffix(")")

def should_add_content(lines):
    is_unchecked = False
    is_missing_etymonline_content = True
    for line in lines:
        line = line.strip()

        if line == "@unchecked":
            is_unchecked = True
        elif line == "┇ etymonline":
            is_missing_etymonline_content = False

    return is_unchecked and is_missing_etymonline_content

def get_etymonline_content(url, class_name=DEFINITION_CLASS):
    response = requests.get(url)
    if response.status_code != 200:
        print(url)
        print(f"Failed to download HTML. Status code: {response.status_code}")
        import sys; sys.exit()

    html = response.text
    soup = BeautifulSoup(html, 'html.parser')
    return soup.find(class_=class_name).text

def add_ety_content(path):
    content = path.read_text()
    lines = content.split("\n")
    url = get_url(lines)

    if url and should_add_content(lines):
        content = "\n".join([
            content.rstrip(),
            textwrap.dedent("""
            ┏━━━━━━━━━━━━━━━━━━╸
            ┇ etymonline
            ┗━━━━━━━━━━━━━━━━━━╸
            """),
            get_etymonline_content(url),
        ])

    content = modify_asterisk(content)
    path.write_text(content)


if __name__ == '__main__':
    for i, path in enumerate(LANGUAGE_DIR.glob("*.md")):
        add_ety_content(path)

        if not i % 50:
            print(i)
