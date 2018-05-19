---
layout: post
title:  Building Portable Python Applications - Tutorial
date:   2018-05-18 20:00:45 -0800
categories: first tutorial python docker application
---
# Building portable Python applications using Pipenv and Docker

A collection of python scripts with dependencies on external libraries can be difficult to wrestle with as they grow into a large and complex system. Fortunately in the age of containers and infrastructure as a service, the tools to tackle these problems are only several commands away. In this post, we build a single-file application to explore the available tooling.

# Meet the Adder
The Adder takes two numbers as options and prints the result to standard out. We will be constructing an application stack that can be deployed on most modern systems. The source directory will take on a structure that is not unlike the following. 

```bash
adder/
├── README.md
├── Dockerfile
├── Pipfile
├── Pipfile.lock
├── adder.py
└── test_adder.py
```

Before starting, make sure that the `pip` is up to date on your system. We install an upgraded version of package manager to a user-owned binary directory.
```bash
pip install --user --upgrade pip
```
On most Linux distributions, `pip` will install to `/home/$USER/.local/bin`. The `PATH` environment variable is generally aware of this path if `pip` is installed correctly, but your milage may vary when using minimal distributions like alpine.

It's often desirable to create per-application environments with their own packages to prevent dependency conflicts. [Pipenv](https://docs.pipenv.org/) is a package management tool that integrates `pip` and `virtualenv` to create a human-centered development workflow. It turns out that it's a great tool for managing autonomous workflows too. The `pipenv` package does not require adminstrative privileges. 

```
$ pip install --user pipenv
```

Lets create a new project for a simple adder. 
``` 
$ mkdir adder
$ cd adder
$ pipenv sync
```

The application is driven by the command-line. Interactions with the operating system and environment occur at the shell-level, so it makes sense to target the command-line when developing a cross platform tool. Click is a framework for building command-line interfaces for applications that is a joy to use. It includes the ability to read arguments from arguments, options, and the environment. It's designed to be composable, so that applications can be part of a larger workflow. 

```
$ pipenv install click
```

The application is simple in structure. 

```python
#!/usr/bin/env python                                       # [1]
import click                                                # [2]

def add(a, b):                                              # [3]
    return a + b

@click.command()                                            # [4]
@click.option('--lhs', type=int, required=True)             # [5]
@click.option('--rhs', type=int, required=True)
def main(lhs, rhs):                                         # [6]
    result = add(lhs, rhs)
    print(result)                                           # [7]

if __name__ == '__main__':                                  # [8]
    main(auto_envvar_prefix='ADDER')                        # [9]
```

Commentary
* [1] Allow this script to be run as a shell script by setting the executable bit with `chmod +x`
* [2] Import the click library for creating the CLI
* [3] The essence of the Adder as a function
* [4] This decorator function (`@` syntax) returns a new function that initializes Click.
* [5] Required options can be read from the environment, as opposed to arguments which are required parameters.
* [6] The main function is the application entrypoint
* [7] Here, results are printed to standard output, but there are better ways of passing data between applications.
* [8] Idiomatic python for single script python entrypoints. 
* [9] Tell `click` to read options from the environment with a prefix.

We're now able to run this from the shell. 
```
$ chmod +x adder.py
$ pipenv run adder.py --lhs 3 --rhs 4
> 7
```

Great, lets write a simple test to verify that everything is working as expected.

# Verification

We will write the tests using `py.test`, a low boilerplate framework for writing tests. The `pipenv install` command includes an option for separating the development dependencies from the application dependencies.

```
$ pipenv install --dev pytest
```


```python
# test_adder.py
import pytest                                               # [1]
from click.testing import CliRunner                         # [2]
from .adder import add                                      # [3]

@pytest.fixture                                             # [4]
def runner():
    return CliRunner()

def test_add(runner):                                       # [5]
    result = runner.invoke(add, ['--lhs', 1, '--rhs', 2])   # [6]
    assert result.exit_code == 0
    assert result.output == '3\n'                           # [7]
```

Commentary
* [1] The `pytest` package forms the basis of the tests. `unittest` is an alternative that is included in the standard library.
* [2] The `click` package includes useful testing harnesses for invoking wrapped functions
* [3] Here, we use a relative import syntax. Since our root folder is not a module (missing `__init__.py`), we will invoke the intepreter with the `-m` flag.
* [4] Fixtures are testing objects that are shared across tests. For example, a static resource can be read from a file and passed as a fixture between testing routines.
* [5] Tests are prefixed with `test_`. Pytest will detect these at runtime.
* [6] The fixture is the return type of the fixture function. Here, the `click` runner is invoking the application with parameters.
* [7] Note the newline. It's probably better practice to use `sys.stdout` to avoid buffering and other unwanted data manipulation

The test is run by telling the python interpreter to treat the current directory as a module using `-m`. 
```bash
pipenv run python -m pytest
```

```bash
============================= test session starts ==============================
platform linux -- Python 3.6.5, pytest-3.5.1, py-1.5.3, pluggy-0.6.0
rootdir: /home/amiyaguchi/Code/adder, inifile:
collected 1 item                                                               

test_adder.py .                                                          [100%]

=========================== 1 passed in 0.02 seconds ===========================
```

Tests are a good way of verifying whether the environment is set up correctly and is indispensible for enabling a reproducible workflow. 

See also: [testing click applications](http://click.pocoo.org/5/testing/), running pytest

# Docker

```Dockerfile
from python:3.6-slim

# everything is run as the root user
RUN pip install --upgrade pip
RUN pip install pipenv

WORKDIR /app
COPY . /app

RUN pipenv sync
CMD pipenv run adder --lhs 1 --rhs 1
```

```bash
docker build -t adder:latest .

docker run -it adder:latest \
    pipenv run adder --lhs 2 --rhs -1
    
docker run -e ADDER_LHS=-2 -e ADDER_RHS=3 -it adder:latest
```
The ergonomics of this workflow is great and makes it easy to reproduce.

# Conclusions
Pipenv and Docker are a powerful pair for writing portable applications that run anywhere Linux runs. 


http://domino.research.ibm.com/library/cyberdig.nsf/papers/0929052195DD819C85257D2300681E7B/$File/rc25482.pdf


Jekyll also offers powerful support for code snippets:

{% highlight ruby %}
def print_hi(name)
  puts "Hi, #{name}"
end
print_hi('Tom')
#=> prints 'Hi, Tom' to STDOUT.
{% endhighlight %}

Check out the [Jekyll docs][jekyll-docs] for more info on how to get the most out of Jekyll. File all bugs/feature requests at [Jekyll’s GitHub repo][jekyll-gh]. If you have questions, you can ask them on [Jekyll Talk][jekyll-talk].

[jekyll-docs]: https://jekyllrb.com/docs/home
[jekyll-gh]:   https://github.com/jekyll/jekyll
[jekyll-talk]: https://talk.jekyllrb.com/
