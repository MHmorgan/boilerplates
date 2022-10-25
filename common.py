import sys
from click import secho


################################################################################
# Logging

def info(msg, /, *, prefix='[·]', **kwargs):
    """Print an info message."""
    kwargs.setdefault('dim', True)
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def emph(msg, /, *, prefix='[*]', **kwargs):
    """Print an emphasized info message."""
    kwargs.setdefault('bold', True)
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def good(msg, /, *, prefix='[✓]', **kwargs):
    """Print a good info message."""
    kwargs.setdefault('fg', 'green')
    kwargs.setdefault('bold', True)
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def bad(msg, /, *, prefix='[✗]', **kwargs):
    """Print a bad info message."""
    kwargs.setdefault('fg', 'red')
    kwargs.setdefault('bold', True)
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def warn(msg, /, *, prefix='[!]', **kwargs):
    """Print a warning message."""
    kwargs.setdefault('fg', 'yellow')
    kwargs.setdefault('bold', True)
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def err(msg, /, *, prefix='[!!]', **kwargs):
    """Print an error message."""
    kwargs.setdefault('fg', 'red')
    kwargs.setdefault('bold', True)
    kwargs.setdefault('err', True)
    secho(f'{prefix} {msg}', **kwargs)


def bail(msg, /, *, code=1, **kwargs):
    """Print an error message and exit"""
    err(msg, **kwargs)
    sys.exit(code)


################################################################################
# Printing

def header(text, /, **kwargs):
    """Print a header text with border."""
    border = '=' * len(str(text))
    kwargs.setdefault('bold', True)
    secho(f'{text}\n{border}', **kwargs)

