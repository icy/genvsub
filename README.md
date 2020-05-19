## Alternative to Gettext's envsubst

Substitutes environment variables in shell format strings,
and can *raise error* if any environment is not set.
There are two kinds of format string `$FOO` and `${FOO}`.
This tool only works with the later form and can serve a simple
template engine for your shell scripts ;)
The program can also limit its action to a small set of variables
whose names match a predefined prefix.

## TOC

* [Usage](#usage)
  * [Supported options](#supported-options)
  * [Installation. Examples](#installation-examples)
* [Problems](#problems)
  * [Kustomization](#kustomization)
  * [Helm or Terraform](#helm-or-terraform)
  * TODO: [Sops](#sops)
  * TODO: [Git-secret or Git-crypt](#get-secret-or-git-crypt)
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
* `-p string`: Limit substitution to variables that match this prefix.
        You can use some regular expression as prefix.

It's highly recommended to use `-u` option. It's the original idea
why this tool was written.

### Installation. Examples

The program works with `STDIN` and write their output to `STDOUT`

    $ go get -v github.com/icy/genvsub
    $ echo 'My home is $HOME'   | ./genvsub
    $ echo 'My home is ${HOME}' | ./genvsub
    $ echo 'Raise error with unset variable ${XXHOME}' | ./genvsub -u

To limit substitution to variables that match some prefix, use `-p` option:

    $ echo 'var=${TEST_VAR}' | ./genvsub -u -p SAFE_
    var=${TEST_VAR}

    $ echo '${TEST_VAR}' | ./genvsub -u -p TEST_
    :: Reading from STDIN and looking for variables with regexp '\${TEST_[^}]+}'
    var=
    :: Environment variable 'TEST_VAR' is not set.

The second command raises an error because the variable `TEST_VAR` matches
the expected prefix `TEST_` and its value is not set.

## Problems

### Kustomization

`kustomization` doesn't like to support build-time side-effects from CLI args/ or env variables.
See the explanation: https://github.com/kubernetes-sigs/kustomize/blob/master/docs/eschewedFeatures.md#build-time-side-effects-from-cli-args-or-env-variables .
They provide subcommand `kustomize edit` as an alternative, however that doesn't work
with  all kind of changes you want to apply for your manifest files. `edit` command
doesn't have better support than `patch` file, and the `patch` file has already some
limitation.

What if we really want to have some side-effects from CLI args/ or env variables? 
For example, we want to provide some API token to alertmanager, which is deployed thanks 
to `prometheus-operator`? You may ask why we need that. Okay, the explanation is below.

The main configuration part of `alertmanager` is described in yaml syntax , i.e.,
https://github.com/prometheus/alertmanager/blob/master/doc/examples/simple.yml
and this whole configuration part is just `configSecret` resource in `prometheus-operator`
as mentioned in the specification:
https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanagerspec

Now there are a few options,

- [ ] In git repository, we encrypt the whole configuration file for Alertmanager,
      and use `secretGenerator` to load them to `configSecret`. There are a few 
      tools to do this: `git-secret`, `git-crypt`, `sops`. All of them just bring
      a nightmare to the pull request review process. `ops` can be the best candidate
      when it can encrypt part of the `yaml` file, but it also requires all other parts
      of the file to be required via `sops`. And maintain the exact file path for sops
      is not an easy task.
- [ ] We modify AlertManager (operator) to feed them with some secrets from
      the runtime environment. Well, we are talking about modifying upstream project,
      about the sidecar... It's the best way (see also
      https://github.com/bitnami-labs/sealed-secrets/tree/master/docs/examples/config-template#injecting-secrets-in-config-file-templates)
      but we can't just do that, can we?
- [ ] We store this whole configuration file for alertmanager in `s3`, and pull them
      at build time. There is no way to review the changes, there will be some surprise
      when a wrong configuration is used a right purpose. `s3` has revisions, but
      no reference support (it isn't another git, is it?)
- [ ] We build a fake `configSecret` with sample values, and modify the file
      at build time with our actual values.

In the last option we build some sample onfiguration file, and modify them at the build time
with cli args or env variables. We accept side-effects, but we don't build another DSL
and/or another template language atop Kustomization or k8s manifests: The world is just
a mess already. 

This tool may be an answer. By accepting not-so-many side-effects, we can easily archive the goal:

```
$ kustomize build | genvsub -f variable_file | kubectl apply -f-
```

Yummy! It's another part of the pipe. As `genvsub` can limit the scope of side-effects,
we can control the risk and have a manageable flow.

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

## License

This work is writtedn by Ky-Anh Huynh
and it's release under a MIT license.
