---
layout: post
title:  "Building Portable Python Applications"
date:   2018-05-18 20:00:45 -0700
categories: first tutorial python docker application
---

A benign collection of scripts with dependencies can quickly become hard to maintain. A build and release process can help manage complexity by making it easy to create something new. Fortunately, the "write once, deploy everywhere" philosophy is not unique to Java. The layers of abstraction in the software stack make it possible to develop complex systems and processes. In this tutorial, we will create create a small data-processing application in Python. 


{:refdef: style="text-align: center;"}
![The program environment]({{ "/assets/blog-00-program-environment.svg" | absolute_url }})
{: refdef}


The Python program runs on the Python intepreter as byte-code, with access to the packages and libraries installed in it's local environment. The package manager and the virtual environment tool generally suffice for portability. However, tools that run at the operating system level such as chroot jails and Docker provide an extra layer of compatibility. There are lower levels of the stack such as hypervisors like KVM, but they rarely useful when building applications.

## Meet the Adder

While a data-processing application sounds large and complex, adding two numbers is not. The Adder takes two numbers as options and prints the result to standard out.

The project structure for the source-code is fairly minimal.

```bash
adder/
├── README.md
├── Dockerfile
├── Pipfile
├── Pipfile.lock
├── adder.py
└── test_adder.py
```

Before starting a new project, make sure that the `pip` is up to date on your system. We install an upgraded version of package manager to a user-owned binary directory.

```bash
pip install --user --upgrade pip
```

On most Linux distributions, `pip` will install to `/home/$USER/.local/bin`. You may want to double check the `PATH` environment variable if there are issues running command line tools installed from pip.

To prevent dependency conflicts, write a new project to a new virtual environment. [Pipenv](https://docs.pipenv.org/) integrates `pip` and `virtualenv` to create a human-centered development workflow. It turns out that it's a great tool for managing autonomous workflows too. The `pipenv` package does not require adminstrative privileges. 

```bash
$ pip install --user pipenv
```

Create a new project for a simple adder. 
```bash
$ mkdir adder
$ cd adder
$ pipenv sync
```

The best way to interact with a non-interactive program is through stdin and stdout. [Click](http://click.pocoo.org/5/) is a package for creating command-line interfaces for Python applications. It provides ways to build out interfaces and can recieve input from arguments, options, and environment variables. Its composable design makes it easy to create tools with rich interfaces.


```bash
$ pipenv install click
```

The implementation below has been commented, but it is simple in structure.

{% highlight python %}
#!/usr/bin/env python                                       # [1]
import click                                                # [2]

def add(a, b):                                              # [3]
    return a + b

@click.command()                                            # [4]
@click.option('--port-A', type=int, required=True)          # [5]
@click.option('--port-B', type=int, required=True)
def main(port_a, port_b):                                   # [6]
    result = add(port_a, port_b)
    print(result)                                           # [7]

if __name__ == '__main__':                                  # [8]
    main(auto_envvar_prefix='ADDER')                        # [9]
{% endhighlight %}

1. Allow this script to be run as a shell script by setting the executable bit with `chmod +x`
2. Import the click library for creating the CLI
3. The essence of the Adder as a function
4. This decorator function (`@` syntax) returns a new function that initializes Click.
5. Required options can be read from the environment, as opposed to arguments which are required parameters.
6. The main function is the application entrypoint
7. Here, results are printed to standard output, but there are better ways of passing data between applications.
8. Idiomatic python for single script python entrypoints. 
9. Tell `click` to read options from the environment with a prefix.

We're now able to run this from the shell. 
```bash
$ chmod +x adder.py
$ pipenv run ./adder.py --port-A 3 --port-B 4
> 7
$ pipenv run ADDER_PORT_A=3 ADDER_PORT_B=4 ./adder.py
>7
```

Great, lets write a simple test to verify that everything is working as expected.

## Writing a Test

We will write the tests using `py.test`, a low boilerplate framework for writing tests. The `pipenv install` command includes an option for separating the development dependencies from the application dependencies.

```bash
$ pipenv install --dev pytest
```


{% highlight python %}
# test_adder.py
import pytest                                                       # [1]
from click.testing import CliRunner                                 # [2]
from .adder import add                                              # [3]

@pytest.fixture                                                     # [4]
def runner():
    return CliRunner()

def test_add(runner):                                               # [5]
    result = runner.invoke(add, ['--port-A', 1, '--port-B', 2])     # [6]
    assert result.exit_code == 0
    assert result.output == '3\n'                                   # [7]
{% endhighlight %}

1. The `pytest` package forms the basis of the tests. `unittest` is an alternative that is included in the standard library.
2. The `click` package includes useful testing harnesses for invoking wrapped functions
3. Here, we use a relative import syntax. Since our root folder is not a module (missing `__init__.py`), we will invoke the intepreter with the `-m` flag.
4. Fixtures are testing objects that are shared across tests. For example, a static resource can be read from a file and passed as a fixture between testing routines.
5. Tests are prefixed with `test_`. Pytest will detect these at runtime.
6. The fixture is the return type of the fixture function. Here, the `click` runner is invoking the application with parameters.
7. Note the newline. It's probably better practice to use `sys.stdout` to avoid buffering and other unwanted data manipulation

The test is run by telling the python interpreter to treat the current directory as a module using `-m`. 
```bash
pipenv run python -m pytest
```

Pytest generates the test results and prints them out to the console. A machine-readable log can be created by setting the `--junitxml` option to the output path.

{% highlight shell %}
============================= test session starts ==============================
platform linux -- Python 3.6.5, pytest-3.5.1, py-1.5.3, pluggy-0.6.0
rootdir: /home/amiyaguchi/Code/adder, inifile:
collected 1 item                                                               

test_adder.py .                                                          [100%]

=========================== 1 passed in 0.02 seconds ===========================
{% endhighlight %}

Tests are a good way of verifying whether the environment is set up correctly and is indispensible for enabling a reproducible workflow. 

# Running in Docker

Now that the software is ready to be release, it needs to be packaged where it can be easily deployed. Docker is a containerization layer that can be the foundation of a deployment process. The application can only communicate through the file-system, network-sockets, or the environment when running in a Docker container. The Adder communicates with the host using the environment and standard out, but long running applications like servers should coordinate over the network.

To dockerize a project, drop in a `Dockerfile` to the root directory. 

{% highlight docker %}
from python:3.6-slim

# everything is run as the root user
RUN pip install --upgrade pip
RUN pip install pipenv

WORKDIR /app
COPY . /app

RUN pipenv sync
CMD pipenv run adder --port-A 1 --port-B 1
{% endhighlight %}

These steps should look familiar. The `Dockerfile` is a good place to document bootstrapping the system from scratch.
 
The container is managed locally with two commands. To create the docker image, run `build` in the current directory.
```bash
docker build -t adder:latest .
```
This will generate an image according to the `Dockerfile` and give it a tag `adder:latest`.

The adder can be run the same as before. There is special syntax to pass environment variables into the container on start.

```bash
$ docker run -it adder:latest \
    pipenv run ./adder --port-A 2 --port-B -1
> 1
$ docker run -e ADDER_PORT_A=-2 -e ADDER_PORT_B=3 -it adder:latest
> 1
```

## Thoughts

With this, the application is successfully portable. The repository can be distributed as a source or as an image. Pipenv and Docker are powerful tools that can improve your workflow and make results easy to reproduce.


## References

[[Github Sources] acmiyaguchi/example-adder](https://github.com/acmiyaguchi/example-adder)

__Command Reference__
```bash
pipenv init                                     # Create a Pipfile
pipenv install click                            # Install click as a library
pipenv install --dev pytest                     # Install pytest as a development library
pipenv sync                                     # Create a Pipfile.lock

pipenv run python -m pytest                     # Run tests like `tests_*`
pipenv run python application.py                # Run the app in the virtual environment

docker build -t <image-name> .                  # Build a docker image in the current directory
docker run -it <image-name> <shell command>     # Run an image interactively with a psuedo-tty
```

__Links__
- [PyPA: Tool recommendations](https://packaging.python.org/guides/tool-recommendations/)
- [Pipenv: Python Dev Workflow for Humans](https://docs.pipenv.org/)
- [Click: a command line library for Python. ](http://click.pocoo.org/5/)
- [pytest: helps you write better programs](https://docs.pytest.org/en/latest/)
- [Docker: Build, Ship, and Run Any App, Anywhere](https://www.docker.com/what-docker)


See also: [testing click applications](http://click.pocoo.org/5/testing/)

