default: tests

PHONY: build
build:
	go build

.PHONY: tests
tests:
	@echo ":: Showing help message"
	./genvsub --help || true

	@echo ":: Good testing, accept non-set variables."
	./genvsub < tests/test.yaml

	@echo ":: Scanning..."
	./genvsub -v < tests/test.yaml

	@echo ":: Set-u, good input and good output."
	JIRA_USER_NAME=username \
		JIRA_USER_PASSWORD=password \
		./genvsub -u < tests/test.yaml

	@echo ":: Good testing, should raise error when there is non-set variable."
	./genvsub -u < tests/test.yaml >/dev/null || true

	@echo ":: All tests passed, right?"
