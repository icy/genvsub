## Alternative to Gettext's envsubst

Substitutes environment variables in shell format strings,
and can raise error if any environment is not set.
There are two kinds of format string `$FOO` and `${FOO}`.
This tool only works with the later form and can serve a simple
template engine for your shell scripts ;)

## TOC

* [Usage](#usage)
  * [Supported options](#supported-options)
  * [Installation. Examples](#installation-examples)
* [Development](#development)
  * [Smoke tests](#smoke-tests)
  * [Ruby version](#ruby-version)
* [References](#references)
* [License](#license)

## Usage

### Supported options

* `-v` : Scan and output ocurrences of variables in the input
* `-u`: Raise error when environment variable is not set.
        This option doesn't work when `-v` is used.

### Installation. Examples

The program works with `STDIN` and write their output to `STDOUT`

    $ go get -v github.com/icy/genvsub
    $ echo 'My home is $HOME'   | ./genvsub
    $ echo 'My home is ${HOME}' | ./genvsub
    $ echo 'Raise error with unset variable ${XXHOME}' | ./genvsub -u

## Development

### Smoke tests

We don't likely have tests with `Golang`. We have some smoke tests instead.

```
$ make build tests
```

Tests are written in `shell` script.
Please have a look at [tests/test.sh](tests/test.sh)

### Ruby version

The usage is almost the same.

    $ echo 'My home is ${HOME}' | ./sub.rb

*WARNING*: The `Ruby` version is written for a reference purpose.
It's not well maintained. Please don't rely on it.

## References

- [ ] Original tool: https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html
- [ ] https://github.com/a8m/envsubst
- [ ] https://github.com/gdvalle/envsub (introduce new syntax `%VAR%`,
      which can be refined with `ENVSUB_PREFIX=%` and `ENVSUB_SUFFIX=%`)

## License

This work is writtedn by Ky-Anh Huynh
and it's release under a MIT license.
