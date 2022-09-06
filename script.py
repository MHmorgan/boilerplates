#!/usr/bin/env python3

import sys

import click
from click import echo, secho
from sh import ls


# The / ensures that `msg` cannot be given as a keyword argument.
# The * ensures that `prefix` can only be given as a keyword argument.
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


################################################################################
#                                                                              #
# CLI
#                                                                              #
################################################################################

@click.group()
def cli():
    pass


@cli.command()
@click.argument('name')
def foo(name: str):
    info(f'Hello {name}')
    global ls
    ls = ls.bake(_out=sys.stdout)
    ls('-l')
    warn("I'm warning you.")
    bail("Oh, no!")

if __name__ == '__main__':
    try:
        cli()
    except KeyboardInterrupt:
        print('Keyboard interrupt. Stopping.')
