#!/usr/bin/env bash

# Author  : Ky-Anh Huynh
# License : MIT
# Purpose : Smoke tests

test_help() {
  genvsub --help
  [[ $? -ge 2 ]]
}

# Looking for something from the output file
_grep() {
  if grep -qsEe "${@}" "tests/${FUNCNAME[1]}.tmp"; then
    echo >&2 ":: __ Pattern matched in the output: '${*}'"
  else
    echo >&2 ":: __ Pattern not matched in the output: '${*}'"
    (( G_ERRORS ++ ))
  fi
}

_genvsub() {
  ./genvsub "${@}" < tests/test.yaml > "tests/${FUNCNAME[1]:-panic}.tmp"
}

# Default tests. Some variables can be unset and/or empty
test_default() {
  unset JIRA_USER_NAME
  unset JIRA_USER_PASSWORD
  _genvsub
  G_ERRORS=0
  _grep "username: \".*error::variable_unset>\""
  _grep "password: \".*error::variable_unset>\""
  _grep "ignore: \"[\\$]JIRA_USER_NAME\""
  [[ "$G_ERRORS" -eq 0 ]]
}

test_scanning() {
  _genvsub -v
  G_ERRORS=0
  _grep "^JIRA_USER_NAME"
  _grep "^JIRA_USER_PASSWORD"
  [[ "$G_ERRORS" -eq 0 ]]
}

test_scanning_with_prefix() {
  _genvsub -v -p 'TEST_.*'
  lc="$(awk 'END{print NR}' < "tests/${FUNCNAME[0]}.tmp")"
  [[ "$lc" -eq 0 ]] || return 1

  _genvsub -v -p 'JIRA_.*'
  G_ERRORS=0
  _grep "^JIRA_USER_NAME"
  _grep "^JIRA_USER_PASSWORD"
  [[ "$G_ERRORS" -eq 0 ]]
}

# Don't raise error if all variables are set
test_set_u_all_fine() {
  export JIRA_USER_NAME=foo
  export JIRA_USER_PASSWORD=bar
  _genvsub -u
  G_ERRORS=0
  _grep "username: \"foo\""
  _grep "password: \"bar\""
  [[ "$G_ERRORS" -eq 0 ]]
}

# Raise some error if some variable is not set
test_set_u_undefined() {
  unset JIRA_USER_NAME
  export JIRA_USER_PASSWORD=bar
  _genvsub -u
  [[ $? -ge 1 ]]
}

# When variable is set to empty value, it's fine
test_set_u_set_empty() {
  export JIRA_USER_NAME=
  export JIRA_USER_PASSWORD=bar
  _genvsub -u
  G_ERRORS=$?
  _grep "username: \"\""
  _grep "password: \"bar\""
  _grep "ignore: \"[\\$]JIRA_USER_NAME\""
  [[ "$G_ERRORS" -eq 0 ]]
}

test_prefix_test_simple() {
  unset JIRA_USER_NAME
  export JIRA_USER_PASSWORD=bar
  _genvsub -u -p 'JIRA_USER.*'
  [[ $? -ge 1 ]]
}

test_multiple_lines() {
  export JIRA_USER_NAME="foo
  :user
bar"
  export JIRA_USER_PASSWORD="foo
  :password
bar"
  _genvsub
  G_ERRORS="$?"
  _grep "^  :user"
  _grep "^  :password"
  [[ "$G_ERRORS" -eq 0 ]]
}

test_prefix_test_complex() {
  export JIRA_USER_NAME=foo
  export JIRA_USER_PASSWORD=bar
  _genvsub -u -p 'JIRA_USER_NAME|JIRA_USER_PASSWORD'
  G_ERRORS="$?"
  _grep "username: \"foo\""
  _grep "password: \"bar\""
  [[ "$G_ERRORS" -eq 0 ]]
}

test_prefix_test_complexv() {
  unset JIRA_USER_NAME
  unset JIRA_USER_PASSWORD
  _genvsub -u -v -p 'JIRA_USER_NAME|JIRA_USER_PASSWORD'
  G_ERRORS="$?"
  _grep "^JIRA_USER_NAME"
  _grep "^JIRA_USER_PASSWORD"
  [[ "$G_ERRORS" -ge 1 ]]
}

test_change_prefix() {
  unset JIRA_USER_NAME
  export JIRA_USER_PASSWORD=bar
  _genvsub -u -p 'SKIP_ME_.*'
  G_ERRORS="$?"
  _grep "username: \"[\\$]{JIRA_USER_NAME}\""
  _grep "password: \"[\\$]{JIRA_USER_PASSWORD}\""
  [[ "${G_ERRORS}" -eq 0 ]]
}

_test() {
  command="$1"; shift

  echo >&2 ":: --------------------------------------------------------"
  echo >&2 ":: Test: ${command}"
  echo >&2 ":: Description: $*"
  echo >&2 ":: --------------------------------------------------------"
  if "${command}"; then
    echo >&2 ": PASS: $command: ${*}"
  else
    (( FAILS++ ))
    cat "tests/${command}.tmp"
    echo >&2 ":: FAIL: $command: ${*}"
  fi
}

test_all() {
  _test test_help                 "Show the help message, and exit code > 0"
  _test test_default              "Default action, not error would raise. Don't use this :)"
  _test test_scanning             "Print a list of variables that need to be change"
  _test test_scanning_with_prefix "Scanning, but prefix doesn't catch any variable"
  _test test_set_u_all_fine       "Set -u, with all variables defined in the environment"
  _test test_set_u_undefined      "Set -u, with some unset variable"
  _test test_set_u_set_empty      "Set -u, with some variable defined and set to empty string"
  _test test_prefix_test_simple   "Use prefix, with the same set of variables as 'test_set_u_all_fine'"
  _test test_prefix_test_complex  "Use prefix with not-so-simple regular expression"
  _test test_prefix_test_complexv "Use prefix with not-so-simple regular expression (Just print, don't do anything)"
  _test test_change_prefix        "Use prefix and no variable from the input can match them."
  _test test_multiple_lines       "Test if program works with multiple lines input"
}

## main routine

PATH="$(pwd -P)":$PATH
export PATH

FAILS=0
test_all
echo >&2 ":: --------------------------------------------------------"
echo >&2 ":: $FAILS test(s) failed."
echo >&2 ":: --------------------------------------------------------"

[[ "$FAILS" -eq 0 ]]
