#!/usr/bin/env bash

# Author  : Ky-Anh Huynh
# License : MIT
# Purpose : Smoke tests

test_help() {
  genvsub --help
}

# Looking for something from the output file
_grep() {
  grep -qsEe "${@}" tests/output.tmp
  if [[ $? -eq 0 ]]; then
    echo >&2 ":: __ Pattern matched in the output: '${@}'"
  else
    echo >&2 ":: __ Pattern not matched in the output: '${@}'"
    (( G_ERRORS ++ ))
  fi
}

# Default tests. Some variables can be unset and/or empty
test_default() {
  unset JIRA_USER_NAME
  unset JIRA_USER_PASSWORD
  genvsub < tests/test.yaml >tests/output.tmp
  G_ERRORS=0
  _grep "username: \"\""
  _grep "password: \"\""
  _grep "ignore: \"[\\$]JIRA_USER_NAME\""
  [[ "$G_ERRORS" -eq 0 ]]
}

test_scanning() {
  genvsub -v < tests/test.yaml > tests/output.tmp
  G_ERRORS=0
  _grep "^JIRA_USER_NAME"
  _grep "^JIRA_USER_PASSWORD"
  [[ "$G_ERRORS" -eq 0 ]]
}

test_scanning_with_prefix() {
  genvsub -v -p TEST_ < tests/test.yaml > tests/output.tmp
  _grep "JIRA_USER_PASSWORD"
}

# Don't raise error if all variables are set
test_set_u_all_fine() {
  export JIRA_USER_NAME=foo
  export JIRA_USER_PASSWORD=bar
  ./genvsub -u < tests/test.yaml > tests/output.tmp
  G_ERRORS=0
  _grep "username: \"foo\""
  _grep "password: \"bar\""
  [[ "$G_ERRORS" -eq 0 ]]
}

# Raise some error if some variable is not set
test_set_u_undefined() {
  unset JIRA_USER_NAME
  export JIRA_USER_PASSWORD=bar
  ./genvsub -u < tests/test.yaml > tests/output.tmp
}

# When variable is set to empty value, it's fine
test_set_u_set_empty() {
  export JIRA_USER_NAME=
  export JIRA_USER_PASSWORD=bar
  ./genvsub -u < tests/test.yaml > tests/output.tmp
  G_ERRORS=$?
  _grep "username: \"\""
  _grep "password: \"bar\""
  _grep "ignore: \"[\\$]JIRA_USER_NAME\""
  [[ "$G_ERRORS" -eq 0 ]]
}

test_prefix_test_simple() {
  unset JIRA_USER_NAME
  export JIRA_USER_PASSWORD=bar
  ./genvsub -u -p JIRA_USER < tests/test.yaml > tests/output.tmp
}

test_prefix_test_complex() {
  export JIRA_USER_NAME=foo
  export JIRA_USER_PASSWORD=bar
  ./genvsub -u -p 'JIRA_USER_(NAME|PASSWOROD)' \
    < tests/test.yaml > tests/output.tmp
  G_ERRORS="$?"
  _grep "username: \"foo\""
  _grep "password: \"bar\""
  [[ "$G_ERRORS" -eq 0 ]]
}

test_change_prefix() {
  unset JIRA_USER_NAME
  export JIRA_USER_PASSWORD=bar
  ./genvsub -u -p "SKIP_ME_" < tests/test.yaml > tests/output.tmp
  G_ERRORS="$?"
  _grep "username: \"[\\$]{JIRA_USER_NAME}\""
  _grep "password: \"[\\$]{JIRA_USER_PASSWORD}\""
  [[ "${G_ERRORS}" -eq 0 ]]
}

#	@echo ":: Set-u, good input and good output."
#	JIRA_USER_NAME=foo \
#		JIRA_USER_PASSWORD=bar \
#		./genvsub -u < tests/test.yaml \
#	 | grep "username: $$JIRA_USER_NAME"
#
#	@echo ":: Good testing, should raise error when there is non-set variable."
#	(./genvsub -u < tests/test.yaml >/dev/null; test $$? -ge 1 ;)
#
#	@echo ":: All tests passed, right?"

_test() {
  expected="$1"; shift
  command="$1"; shift

  echo >&2 ":: --------------------------------------------------------"
  echo >&2 ":: Test: ${command}"
  echo >&2 ":: Description: $*"
  echo >&2 ":: --------------------------------------------------------"
  "${command}"

  if [[ $? -eq "$expected" ]]; then
    echo >&2 ": PASS: ${*}"
  else
    (( FAILS++ ))
    echo >&2 ":: FAIL: ${*}"
  fi
}

test_all() {
  _test 2 test_help                 "Show the help message, and exit code > 0"
  _test 0 test_default              "Default action, not error would raise. Don't use this :)"
  _test 0 test_scanning             "Print a list of variables that need to be change"
  _test 1 test_scanning_with_prefix "Scanning, but prefix doesn't catch any variable"
  _test 0 test_set_u_all_fine       "Set -u, with all variables defined in the environment"
  _test 1 test_set_u_undefined      "Set -u, with some unset variable"
  _test 0 test_set_u_set_empty      "Set -u, with some variable defined and set to empty string"
  _test 1 test_prefix_test_simple   "Use prefix, with the same set of variables as 'test_set_u_all_fine'"
  _test 1 test_prefix_test_complex  "Use prefix with not-so-simple regular expression"
  _test 0 test_change_prefix        "Use prefix and no variable from the input can match them."
}

## main routine

export PATH="$(pwd -P)":$PATH
FAILS=0
test_all
echo >&2 ":: --------------------------------------------------------"
echo >&2 ":: $FAILS test(s) failed."
echo >&2 ":: --------------------------------------------------------"

[[ "$FAILS" -eq 0 ]]
