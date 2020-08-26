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

To install on your laptop, please try the popular way

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

In this section, we mainly discuss how we want to have secret/credentials in
git repository and our template/manifests/whatever (configuration) files.

### Kustomization

`kustomization` doesn't like to support build-time side-effects from CLI args/ or env variables.
See the explanation: https://github.com/kubernetes-sigs/kustomize/blob/master/docs/eschewedFeatures.md#build-time-side-effects-from-cli-args-or-env-variables .
(https://github.com/kubernetes-sigs/kustomize/blob/b6d760dc6fb40d75d83cc2dd18b9609ec43a3fb5/docs/eschewedFeatures.md#build-time-side-effects-from-cli-args-or-env-variables)
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
$ kustomize build \
  | genvsub -u -p "(ENV_[_A-Z0-9]+)|STG_NAMESPACE|IMAGE_TAG|RESOURCE_PREFIX_" \
  > output.yaml
$ if [[ $? -eq 0 ]]; then
    kubectl apply -f- < output.yaml
  fi
```

Yummy! It's another part of the pipe. As `genvsub` can limit the scope of side-effects,
we can control the risk and have a manageable flow.

## Helm or Terraform

Before we go further, please note as in the previous section [Kusotmization](#kustomization),
we don't really like the idea to encrypt the whole file with `git-secret`, `git-crypt` or `sops`,
because that makes the reviewing process harder. We want to see plain text file as plain text
file, and we also want to modify them quickly/easily.

Both `helm` and `terraform` are complex, and discussing how they work is not a not-so-long-topic.
Though serving different purporses and solving different problems, they all share the same
idea: They allow engineers to describe some custom logic, and control the code with
some additional (control) variables, and yep, variables can be from build/run time
environment. That means they are very flexible dealing with side-effects

```
$ terraform plan -var-file=custom.tfvars
$ helm install --values ./custom_1.yaml --values ./custom_2.yaml
```

It isn't clear if they can support `STDIN` as a regular value file, but basically we can use
`genvsub` to resolve our issue (what's the issue? it's to have some credentials in `helm`
`values.yaml` file, or some terraform DSL files.)

```
$ < input.secret genvsub > custom_helm_with_credentials.tfvars
$ terraform plan -var-file=custom_helm_with_credentials.tfvars
$ shred custom_helm_with_credentials.tfvars # FIXME: this won't work!

$ < input.secret genvsub > custom_helm_with_credentials.vars
$ helm install -values ./custom_helm_with_credentials.vars
$ shred custom_helm_with_credentials.vars # FIXME: this won't work!
```

Well, you may ask why we just use some `helm plugin`, or `terraform provider` instead?
Yes, we can. `terraform` has some provider to deal with external secrets,
and `helm` may have some plugin that features the same thing.
They can solve the problem. You can use. And using `genvsub` is an alternative.

Helm engineers solve Helm issue, Terraform engineers solve Terraform engineer.
Why don't we just accept side-effects and both use environment variables instead:)

Please note that, in `Helm` `values.yaml`, you can't refer to another variable.
When using some helm charts, you likely write down all hard-coded strings in `values.yaml`
file, or you write another template atop the standard helm charts (lolz),
or you have some wrapper atop (for example, see `helm-secrets` by Zendesk below)

See also

- Helm plugin: https://github.com/zendesk/helm-secrets
- Terraform provider: https://github.com/carlpett/terraform-provider-sops
- Terraform ssm_parameter provider: https://www.terraform.io/docs/providers/aws/r/ssm_parameter.html

## Development

### Smoke tests

We don't likely have tests with `Golang`. We have some smoke tests instead.

```
$ make build tests
```

Tests are written in `shell` script.
Please have a look at [tests/test.sh](tests/test.sh).

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
- [ ] https://github.com/s12v/exec-with-secrets: Fetch configuration/secrets/variables
      at run time, and provides them to your program. Now you have to rebuild your
      docker images with the tool atop your original `executable` command.

## License

This work is writtedn by Ky-Anh Huynh
and it's released under a MIT license.
