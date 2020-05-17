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

  echo >&2 ":: Test: ${*}"
  "${@}"

  if [[ $? -eq "$expected" ]]; then
    echo >&2 ": PASS: ${*}"
  else
    (( FAILS++ ))
    echo >&2 ":: FAIL: ${*}"
  fi
}

test_all() {
  _test 2 test_help
  _test 0 test_default
  _test 0 test_scanning
  _test 0 test_set_u_all_fine
  _test 1 test_set_u_undefined
  _test 0 test_set_u_set_empty
}

## main routine

export PATH="$(pwd -P)":$PATH
FAILS=0
test_all
echo ":: $FAILS test(s) failed."
[[ "$FAILS" -eq 0 ]]
