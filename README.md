## Alternative to Gettext's envsubst

Substitutes environment variables in shell format strings,
and can raise error if any environment is not set.
There are two kinds of format string `$FOO` and `${FOO}`.
This tool only works with the later form and can serve a simple
template engine for your shell scripts ;)

## Usage

## Supported options

* `-v` : Scan and output ocurrences of variables in the input
* `-set-u`: Raise error when environment variable is not set.
  This option doesn't work when `-v` is used.

### Go version

The program works with `STDIN` and write their output to `STDOUT`

    $ go get -d
    $ go build
    $ echo 'My home is $HOME'   | ./envsubst
    $ echo 'My home is ${HOME}' | ./envsubst
    $ echo 'Raise error with unset variable ${XXHOME}' | ./envsubst -set-u

### Ruby version

The usage is almost the same.

    $ echo 'My home is ${HOME}' | ./sub.rb

## References

Original tool:
  https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html

Similar tool:
  https://github.com/a8m/envsubst

## License

MIT
