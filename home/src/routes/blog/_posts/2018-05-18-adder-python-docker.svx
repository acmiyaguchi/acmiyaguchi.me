---
layout: post
title: Building Portable Python Applications
date: 2018-05-18T20:00:45-08:00
category: Engineering
tags: tutorial python docker application software
---

Scripts are a collection of commands that run in sequence when executed. Scripts
can be used to drive interactions between characters in a video game or to set a
web-server to a desired state. These actors interact with the environment as
they perform according to the script. You will often find scripts in large and
complex systems, where they are necessary to scale. Software projects accrue
scripts out of necessity to avoid memorizing the many incantations for building,
testing, and releasing code. Fortunately, the "write once, run everywhere"
philosophy is not unique to Java. In this tutorial, we will create a
data-processing application in Python that can be run in a reproducible way
using Pipenv and Docker.

Python has been a dominating language in scientific community with projects like
SciPy and Anaconda providing a reproducible environment for data processing and
analysis. Python is designed to be general purpose, but the [Zen of
Python](https://www.python.org/dev/peps/pep-0020/) makes it a suitable choice
for new programmers and experienced ones alike. Notebook computing, popularized
by IPython and later Jupyter, [is a paradigm
shift](https://blog.jupyter.org/jupyter-receives-the-acm-software-system-award-d433b0dfe3a2)
in the way we interact with computers. The notebook is also a script for
reproducing a particular experiment or procedure.

The POSIX shell language and CMD batching together run on most computers today.
However, shell likely runs on more virtualized copies of systems due to the
prevalence of Infrastructure as a Service (IaaS). The [success of Amazon Web
Service](https://www.forbes.com/sites/roberthof/2016/03/22/ten-years-later-amazon-web-services-defies-skeptics/#c6b15ee6c447)
fits well with the nature of computation today -- distributed and heterogeneous.
Many large sites will offload massive amounts of traffic, computation, and data
to servers owned by different companies across the globe. Despite the complexity
of software today, it's never been easier to create robust and reproducible
applications using both Python and shell.

![The program environment](/assets/2018-05-18/program-environment.svg)

_**Figure:** A typical computer can support many applications by layering
software to handle orthogonal tasks. An application runs in an environment._

## An Adding Machine

While a data-processing application can be involved, we can look at the
construction of a simple one. An adding machine takes two numbers as options and
prints the result to standard out. The Adder is a Python application that
implements an adding machine. The project is flat, and every file is single
purposed. Large projects grow from a similar base with defined processes and a
nested folder structure.

```bash
adder/
├── README.md
├── Dockerfile
├── Pipfile
├── Pipfile.lock
├── adder.py
└── test_adder.py
```

Before starting a new project, make sure that the `pip` is up to date on your
system. If not already up-to-date, install the upgraded version in the user
executable folder (e.g. `$HOME/.local/bin`).

```bash
pip install --user --upgrade pip
```

We will be using Pipenv to manage the Python environment and dependencies.
[Pipenv](https://docs.pipenv.org/) integrates `pip` and `virtualenv` to create a
human-centered development workflow. It turns out that it's an excellent tool
for managing autonomous workflows too. This tool increases the portability of a
Python application by isolating dependencies management and execution into
userland, i.e., applications do not need root privileges.

```bash
$ pip install --user pipenv
```

If there are issues with the `--user` option, check that the `PATH` variable is
set correctly.

Create a new project for the Adder.

```bash
$ mkdir adder
$ cd adder
$ pipenv sync
```

We will be observing the adding machine through the standard terminal input and
output (stdin and stdout or file descriptors 1 and 2).
[Click](http://click.pocoo.org/5/) is a library for creating command-line
interfaces for Python applications. The idea of the command is central to the
Click API. It provides a simple way to create interfaces and can take input from
arguments, options, and environment variables.

To add a library to a project, `install` it.

```bash
$ pipenv install click
```

Python and Click can be used to write the Adder implementation.

```python
#!/usr/bin/env python # [1]
import click # [2]

def add(a, b): # [3]
return a + b

@click.command() # [4]
@click.option('--port-A', type=int, required=True) # [5]
@click.option('--port-B', type=int, required=True)
def main(port_a, port_b): # [6]
result = add(port_a, port_b)
print(result) # [7]

if **name** == '**main**': # [8]
main(auto_envvar_prefix='ADDER') # [9]
```

1. Run the file using Python from the user environment. This is run by setting
   the executable bit via `chmod +x`.
2. Import Click library to create the Command Line Interface (CLI).
3. The core functionality of an adding machine.
4. The `@` is notation for the application of a decorator function. This returns
   `main` wrapped with `click` initialization.
5. This convention should be adopted when running applications through Docker.
   See [9].
6. The application entry point
7. Printing to stdout is one way to pass data between applications. Files and
   sockets are also widely used.
8. The script is run standalone when the `__main__` script entry point is
   defined.
9. `click` will read variables from the environment when the
   `auto_envvar_prefix` is defined.

We're can now run the application in the wild.

```bash
$ chmod +x adder.py
$ pipenv run ./adder.py --port-A 3 --port-B 4
> 7
$ pipenv run ADDER_PORT_A=3 ADDER_PORT_B=4 ./adder.py
>7
```

Great, everything looks correct at first glance. Because we're writing software
that's executed more often than it's read, let's verify the behavior with a
test.

## Adder Verification

There's an extensive toolbox to choose from when testing Python software. Here,
we want a low boilerplate framework called
[`pytest`](https://docs.pytest.org/en/latest/) to write tests. We can keep these
dependencies separate from the production dependencies by adding the `--dev`
option to the `install` command.

```bash
$ pipenv install --dev pytest
```

Again, here is a breakdown of the anatomy of the code.

```python
# test_adder.py

import pytest # [1]
from click.testing import CliRunner # [2]
from .adder import add # [3]

@pytest.fixture # [4]
def runner():
return CliRunner()

def test_add(runner): # [5]
result = runner.invoke(add, ['--port-A', 1, '--port-B', 2]) # [6]
assert result.exit_code == 0
assert result.output == '3\n' # [7]
```

1. The `pytest` package forms the basis of the tests. `unittest` is an
   alternative that is included in the standard library.
2. The `click` package [includes useful testing
   harnesses](http://click.pocoo.org/5/testing/) for invoking wrapped functions
3. The relative import syntax is used here. Because `__init__.py` is missing, we
   need to supply the interpreter a hint to treat the current folder as a module
   using the `-m` flag.
4. Fixtures are testing objects that are shared across tests. For example, a
   static resource can be read from a file and passed as a fixture between
   testing routines.
5. Tests are prefixed with `test_`. Pytest will detect these at runtime.
6. The `runner` type is the same as the return type of the `runner()` fixture
   function.
7. Note the newline. One possible improvement is to ignore whitespace or write
   directly to stdout.

Run the test using pytest. Remember that the current directory should be treated
as a module using `python -m <command>`.

```bash
pipenv run python -m pytest
```

Pytest generates the test results and prints them out to the console. Add the
`--junitxml` option to log the results into a file.

```bash
============================= test session starts ==============================
platform linux -- Python 3.6.5, pytest-3.5.1, py-1.5.3, pluggy-0.6.0
rootdir: /home/amiyaguchi/Code/adder, inifile:
collected 1 item

test_adder.py . [100%]

=========================== 1 passed in 0.02 seconds ===========================
```

Tests verify the correct environment configuration and are indispensable for
enabling a reproducible workflow.

Tests is a dark art of itself. If you had to reverse engineer the Adder black
box, how you generate the minimal set of statements needed to validate its
hypothesized behavior?

## Running in Docker

Now that the Python adding machine can be run and tested the shell, we can
package the entire environment in an operating system container. Docker creates
application environments that share the host kernel but are isolated from all
system resources like the file system and process manager. Environment variables
are a standard way to set container configuration.

To start your container fleet, drop a `Dockerfile` to the project directory.

```docker
from python:3.6-slim

# everything is run as the root user

RUN pip install --upgrade pip
RUN pip install pipenv

WORKDIR /app
COPY . /app

RUN pipenv sync
CMD pipenv run adder --port-A 1 --port-B 1
```

These steps should look familiar. The `Dockerfile` is a source of end-to-end
system documentation.

The container is managed locally with two commands. To create the docker image,
run `build` in the current directory.

```bash
docker build -t adder:latest .
```

This will generate an image and tag it as `adder:latest`.

The shell is the control interface of the adding machine. The Docker CLI has an
option for setting environment variables.

```bash
$ docker run -it adder:latest \
    pipenv run ./adder --port-A 2 --port-B -1
> 1
$ docker run -e ADDER_PORT_A=-2 -e ADDER_PORT_B=3 -it adder:latest
> 1
```

## Thoughts

With this, the application is successfully portable. The repository can be
distributed as a source or as an image. Pipenv and Docker are potent tools that
can improve your workflow and make results accessible to reproduce.

## References

[[Github Sources] acmiyaguchi/example-adder](https://github.com/acmiyaguchi/example-adder)

### Command Reference

```bash
pipenv init                                     # Create a Pipfile
pipenv install click                            # Install Click as a library
pipenv install --dev pytest                     # Install pytest as a development library
pipenv sync                                     # Create a Pipfile.lock

pipenv run python -m pytest                     # Run tests like `tests_*`
pipenv run python application.py                # Run the app in the virtual environment

docker build -t <image-name> .                  # Build a docker image in the current directory
docker run -it <image-name> <shell command>     # Run an image interactively with a psuedo-tty
```

### Links

- [PyPA: Tool recommendations](https://packaging.python.org/guides/tool-recommendations/)
- [Pipenv: Python Dev Workflow for Humans](https://docs.pipenv.org/)
- [Click: a command line library for Python. ](http://click.pocoo.org/5/)
- [pytest: helps you write better programs](https://docs.pytest.org/en/latest/)
- [Docker: Build, Ship, and Run Any App, Anywhere](https://www.docker.com/what-docker)
