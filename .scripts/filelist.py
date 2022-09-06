#!/usr/bin/env python3.10

from pathlib import Path

IGNORE_FILE = 'meta/ignore.txt'
IGNORE_LIST = Path(IGNORE_FILE).read_text().splitlines(False)


def list_files(path: Path):
    for file in path.iterdir():
        # Ignore all hidden files and folders
        if file.match('.*') or str(file) in IGNORE_LIST:
            continue
        elif file.is_file():
            yield str(file)
        elif file.is_dir():
            yield from list_files(file)


def main():
    for file in list_files(Path('.')):
        print(file)


main()
