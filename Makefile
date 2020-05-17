default: tests

PHONY: build
build:
	go build

.PHONY: tests
tests:
	@echo ":: Showing help message"
	./envsubst --help || true

	@echo ":: Good testing, accept non-set variables."
	./envsubst < tests/test.yaml

	@echo ":: Scanning..."
	./envsubst -v < tests/test.yaml

	@echo ":: Set-u, good input and good output."
	JIRA_USER_NAME=username \
		JIRA_USER_PASSWORD=password \
		./envsubst -u < tests/test.yaml

	@echo ":: Good testing, should raise error when there is non-set variable."
	./envsubst --u < tests/test.yaml || true

	@echo ":: All tests passed, right?"
