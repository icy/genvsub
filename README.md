![icy](https://github.com/icy/genvsub/workflows/icy/badge.svg)

## Alternative to Gettext's envsubst

Substitutes environment variables in shell format strings,
and can *raise error* if any environment is not set.
There are two kinds of format string `$FOO` and `${FOO}`.
This tool only works with the later form and can serve a simple
template engine for your shell scripts ;)
The program can also limit its action to a small set of variables
whose names match a predefined prefix/regexp.

## TOC

* [Usage](#usage)
  * [Supported options](#supported-options)
  * [Installation. Examples](#installation-examples)
  * [Note on variable prefix](#note-on-variable-prefix)
* [Development](#development)
  * [Smoke tests](#smoke-tests)
* [References](#references)
* [License](#license)

## Usage

### Supported options

* `-v`: Scan and output all occurrences of variables in the input.
* `-u`: Raise error when environment variable is not set.
        When being used with `-v`, the program scans through the whole
        input; otherwise, the program stops immediately when there is
        any undefined (environment) variable.
* `-p regexp`: Limit substitution to variables that match this prefix.
        You can use some regular expression as prefix.
        Default to `[^}]+`. Can be used as an alternative
        to `SHELL-FORMAT` option in the original GNU `envsubst`

It's highly recommended to use `-u` option. It's the original idea
why this tool was written.

### Installation. Examples

Starting from `v1.2.2`, you can download binary files generated automatically
by Github-Action action (via goreleaser tool). You find the files from
the release listing page: https://github.com/icy/genvsub/releases

To install on your laptop by local compiling process, please try the popular way

    $ go get -v github.com/icy/genvsub
    $ export PATH=$PATH:$(go env GOPATH)/bin

The program works with `STDIN` and write their output to `STDOUT`

    $ echo 'My home is $HOME'   | ./genvsub
    $ echo 'My home is ${HOME}' | ./genvsub
    $ echo 'Raise error with unset variable ${XXHOME}' | ./genvsub -u

To limit substitution to variables that match some prefix, use `-p` option:

    $  echo 'var=${TEST_VAR}' | ./genvsub -u -p SAFE_
    :: genvsub is reading from STDIN and looking for variables with regexp '\${(SAFE_)}'
    var=${TEST_VAR}

    $ echo '${TEST_VAR}' | ./genvsub -u -p 'TEST_.*'
    :: genvsub is reading from STDIN and looking for variables with regexp '\${(TEST_.*)}'
    <TEST_VAR::error::variable_unset>
    :: Environment variable 'TEST_VAR' is not set.

The second command raises an error because the variable `TEST_VAR` matches
the expected prefix `TEST_` and its value is not set.

You can also specify exactly a few variables to be substituted
(which is exactly an alternative to the `shell-format` option
in the original GNU tool `envsubst`):

    $ echo '${TEST_VAR}' | ./genvsub -u -p 'VAR_NAME_3|VAR_NAME_3|VAR_NAME_3'

### Note on variable prefix

When using `-p string` to specify the variable prefix, you can also use
some simple regular expression. However, please note that for the given
input argument `-p PREFIX`, the  program will build the final regexp
`\${(PREFIX)}`.

1. Hence you can't use for example `-p '^FOO'`.
2. You can also easily trick the program with some fun `PREFIX` ;)
   However, as seen in
   https://github.com/icy/genvsub/blob/33e68048c6fe4b6ca0befadbc9fa5c19055ede8b/sub.go#L42
   the program enforces input data to follow the form `${VARIABLE_NAME}`.
   I'm still thinking if we can allow more tricks here.

## Problems

Clean up on Dec 18th 2020.

## Development

### Smoke tests

We don't likely have tests with `Golang`. We have some smoke tests instead.

```
$ make build tests
```

Tests are written in `shell` script.
Please have a look at [tests/test.sh](tests/test.sh).

### Ruby version

Removed on Dec 18th 2020.

## References

- [ ] Original tool: https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html
    (which can't raise error if some variable is not set.)
- [ ] https://github.com/a8m/envsubst : A Go tool; It tries to behave like Bash with some
     advanced feature dealing with empty/non-set/default values
     https://github.com/a8m/envsubst#docs; it can also raise error if some variable
     is empty and/or not-set. This tool has a few features that I don't need,
     and at the same time it doesn't have some features I need (reg-exp variable name
     filter, strict variable naming format, bla bla)
- [ ] https://github.com/gdvalle/envsub : A Rust tool; It introduces new syntax `%VAR%`,
      which can be refined with `ENVSUB_PREFIX=%` and `ENVSUB_SUFFIX=%`.
      When hitting unset variables it will exit rather than expanding as empty strings.
      It also fully buffers input before writing, so in-place replacement is possible.
- [ ] https://github.com/s12v/exec-with-secrets: Fetch configuration/secrets/variables
      at run time, and provides them to your program. Now you have to rebuild your
      docker images with the tool atop your original `executable` command.

## License

This work is writtedn by Ky-Anh Huynh
and it's released under a MIT license.
