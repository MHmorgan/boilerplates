#!/usr/bin/env python3.10

import sys

import click
from click import echo, secho
import requests

URL_BASE = 'https://mhmorgan.github.io/boilerplates/'
URL_FILELIST = URL_BASE + 'meta/filelist.txt'


def info(msg, /, *, prefix='[*]', **kwargs):
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def warn(msg, /, *, prefix='[!]', **kwargs):
    kwargs.setdefault('fg', 'yellow')
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def err(msg, /, *, prefix='[!!]', **kwargs):
    kwargs.setdefault('fg', 'red')
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def bail(msg, /, **kwargs):
    err(msg, **kwargs)
    sys.exit(1)


def fetch_filelist() -> list[str]:
    r = requests.get(URL_FILELIST)
    return r.text.splitlines(False)


def fetch_file(name: str) -> str:
    r = requests.get(URL_BASE + name)
    if not r.ok:
        bail(r.reason)
    return r.text


@click.command()
@click.argument('file', required=False)
def main(file: str):
    """Fetch the given FILE from the boilerplates repository,
    or list all boilerplates.
    """
    files = fetch_filelist()

    if not file:
        echo('\n'.join(files))
        return

    echo(fetch_file(file))


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Keyboard interrupt. Stopping.')
