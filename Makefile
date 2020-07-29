default: tests

PHONY: build
build:
	go build

.PHONY: clean
clean:
	@rm -fv tests/*.tmp

.PHONY: tests
tests: clean
	./tests/test.sh

.PHONY: all
all: build tests
