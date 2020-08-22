default: tests

PHONY: build
build:
	go build

.PHONY: clean
clean:
	@rm -fv tests/*.tmp tests/.tmp

.PHONY: tests
tests: clean build
	./tests/test.sh

.PHONY: all
all: build tests

.PHONY: local
local:
	shellcheck tests/test.sh
