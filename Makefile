#-------------------------------------------------------------------------------
# Running `make` will show the list of subcommands that will run.

SHELL:=bash
GOBIN=$(shell ./find-go-bin.sh)
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

#-------------------------------------------------------------------------------
# Global stuff.

GO=$(shell which go)
HOMEBREW_PACKAGES=bash bats-core coreutils findutils git git-lfs go grep jq librsvg nodejs pre-commit python@3.11 tfschema trufflesecurity/trufflehog/trufflehog

# Determine the operating system and CPU arch.
OS=$(shell uname -o | tr '[:upper:]' '[:lower:]')

# Determine which version of `echo` to use. Use version from coreutils if available.
ECHOCHECK_HOMEBREW_AMD64 := $(shell command -v /usr/local/opt/coreutils/libexec/gnubin/echo 2> /dev/null)
ECHOCHECK_HOMEBREW_ARM64 := $(shell command -v /opt/homebrew/opt/coreutils/libexec/gnubin/echo 2> /dev/null)

ifdef ECHOCHECK_HOMEBREW_AMD64
	ECHO=/usr/local/opt/coreutils/libexec/gnubin/echo -e
else ifdef ECHOCHECK_HOMEBREW_ARM64
	ECHO=/opt/homebrew/opt/coreutils/libexec/gnubin/echo -e
else ifeq ($(findstring linux,$(OS)), linux)
	ECHO=echo -e
else
	ECHO=echo
endif

#-------------------------------------------------------------------------------
# Running `make` will show the list of subcommands that will run.

all: help

.PHONY: help
## help: [help]* Prints this help message.
help:
	@ $(ECHO) "Usage:"
	@ $(ECHO) ""
	@ sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /' | \
		while IFS= read -r line; do \
			if [[ "$$line" == *"]*"* ]]; then \
				$(ECHO) "\033[1;33m$$line\033[0m"; \
			else \
				$(ECHO) "$$line"; \
			fi; \
		done

#-------------------------------------------------------------------------------
# Installation

.PHONY: install-tools-go
## install-tools-go: [tools]* Install/upgrade the required Go packages.
install-tools-go:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Installing Go packages...\033[0m"
	$(GO) install github.com/antham/gommit@latest
	$(GO) install github.com/bitfield/gotestdox/cmd/gotestdox@latest
	$(GO) install github.com/google/osv-scanner/cmd/osv-scanner@v1
	$(GO) install github.com/goph/licensei/cmd/licensei@latest
	$(GO) install github.com/mdempsky/unconvert@latest
	$(GO) install github.com/nikolaydubina/go-binsize-treemap@latest
	$(GO) install github.com/nikolaydubina/go-cover-treemap@latest
	$(GO) install github.com/orlangure/gocovsh@latest
	$(GO) install github.com/pelletier/go-toml/v2/cmd/tomljson@latest
	$(GO) install github.com/securego/gosec/v2/cmd/gosec@latest
	$(GO) install github.com/trufflesecurity/driftwood@latest
	$(GO) install golang.org/x/perf/cmd/benchstat@latest
	$(GO) install golang.org/x/tools/cmd/godoc@latest
	$(GO) install golang.org/x/vuln/cmd/govulncheck@latest
	$(GO) install gotest.tools/gotestsum@latest

.PHONY: install-tools-mac
## install-tools-mac: [tools]* Install/upgrade the required tools for macOS, including Go packages.
install-tools-mac: install-tools-go
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Installing required packages for macOS (Homebrew)...\033[0m"
	brew update && brew install $(HOMEBREW_PACKAGES) && brew upgrade $(HOMEBREW_PACKAGES)
	curl -sSLf https://raw.githubusercontent.com/mtdowling/chag/master/install.sh | bash

	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33mTo update to the latest versions, run:\033[0m"
	@ $(ECHO) "\033[1;33m    brew update && brew upgrade\033[0m"
	@ $(ECHO) " "

.PHONY: install-hooks
## install-hooks: [tools]* Install/upgrade the Git hooks used for ensuring consistency.
install-hooks:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Installing Git hooks...\033[0m"
	cp -vf .githooks/commit-msg.sh .git/hooks/commit-msg
	chmod +x .git/hooks/*
	pre-commit install

	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33mLearn more about `pre-commit` at:\033[0m"
	@ $(ECHO) "\033[1;33m    https://pre-commit.com\033[0m"
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33mLearn more about `gommit` at:\033[0m"
	@ $(ECHO) "\033[1;33m    https://github.com/antham/gommit\033[0m"
	@ $(ECHO) " "

#-------------------------------------------------------------------------------
# Compile

.PHONY: tidy
## tidy: [build] Updates go.mod and downloads dependencies.
tidy:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Tidy and download the Go dependencies...\033[0m"
	$(GO) mod tidy -go=1.21 -v

.PHONY: godeps
## godeps: [build] Updates go.mod and downloads dependencies.
godeps:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Upgrade the minor versions of Go dependencies...\033[0m"
	$(GO) get -d -u -t -v ./...

#-------------------------------------------------------------------------------
# Clean

.PHONY: clean-go
## clean-go: [clean] Clean Go's module cache.
clean-go:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Cleaning Go cache...\033[0m"
	$(GO) clean -i -r -x -testcache -modcache -cache

.PHONY: clean-bench
## clean-bench: [clean] Cleans all benchmarking-related files.
clean-bench:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Cleaning artifacts from benchmarks...\033[0m"
	- find . -type f -name "__*.out" | xargs rm -Rf
	- find . -type f -name "*.test" | xargs rm -Rf

.PHONY: clean
## clean: [clean]* Runs ALL cleaning tasks (except the Go cache).
clean: clean-bench

#-------------------------------------------------------------------------------
# Documentation

.PHONY: docs
## docs: [docs]* Runs primary documentation tasks.
docs: docs-cli

.PHONY: docs-cli
## docs-cli: [docs] Preview the Go library documentation on the CLI.
docs-cli:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Displaying Go CLI documentation...\033[0m"
	$(GO) doc -C -all

.PHONY: docs-serve
## docs-serve: [docs] Preview the Go library documentation as displayed on pkg.go.dev.
docs-serve:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Displaying Go HTTP documentation...\033[0m"
	open http://localhost:6060/pkg/github.com/skyzyx/semver/
	godoc -index -links

#-------------------------------------------------------------------------------
# Linting

.PHONY: vuln
## vuln: [lint]* Checks for known security vulnerabilities.
vuln:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running govulncheck (https://go.dev/blog/vuln)...\033[0m"
	govulncheck ./...

	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running govulncheck -test (https://go.dev/blog/vuln)...\033[0m"
	govulncheck -test ./...

	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running osv-scanner (https://osv.dev)...\033[0m"
	osv-scanner -r .

	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running gosec (https://github.com/securego/gosec)...\033[0m"
	gosec -terse -tests ./...

.PHONY: secrets
## secrets: [lint]* Checks for verifiable secrets.
secrets:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running TruffleHog...\033[0m"
	trufflehog git file://. --json --only-verified --concurrency=$(nproc) 2>/dev/null | jq '.'

.PHONY: pre-commit
## pre-commit: [lint]* Runs `pre-commit` against all files.
pre-commit:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running pre-commit...\033[0m"
	pre-commit run --all-files

.PHONY: license
## license: [lint]* Checks the licenses of all files and dependencies.
license:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Checking license statistics...\033[0m"
	@ - licensei stat

	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Checking license compliance...\033[0m"
	@ - licensei check
	@ $(ECHO) " "
	@ - licensei list

	@ $(ECHO) " "

.PHONY: unconvert
## unconvert: [lint]* Identify unnecessary type conversions. All GOOS/GOARCH matches.
unconvert:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running unconvert (all GOOS/GOARCH)...\033[0m"
	unconvert -all -fastmath -tests -v ./...

.PHONY: lint
## lint: [lint]* Runs ALL linting/validation tasks.
lint: vuln license unconvert pre-commit

#-------------------------------------------------------------------------------
# Testing
# https://github.com/golang/go/wiki/TableDrivenTests
# https://go.dev/doc/tutorial/fuzz
# https://pkg.go.dev/testing
# https://pkg.go.dev/golang.org/x/perf/cmd/benchstat

.PHONY: test
## test: [test]* Runs ALL tests.
test: unit fuzz

.PHONY: unit
## unit: [test] Runs unit tests.
unit:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running unit tests...\033[0m"
	gotestsum --format testname -- -count=1 -parallel=$(shell nproc) -timeout 30s -coverpkg=./... -coverprofile=__coverage.out -v ./...
	@ go-cover-treemap -coverprofile __coverage.out > unit-coverage.svg
	@ rsvg-convert --width=2000 --format=png --output="unit-coverage.png" "unit-coverage.svg"

.PHONY: fuzz
## fuzz: [test]* Runs the fuzzer for 1 minute per test.
fuzz:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running the fuzzer (https://go.dev/doc/tutorial/fuzz)...\033[0m"
	$(GO) test -run='^$$' -fuzz=FuzzNewConstraint -fuzztime 1m -parallel=$(shell nproc) -v ./...
	$(GO) test -run='^$$' -fuzz=FuzzNewVersion -fuzztime 1m -parallel=$(shell nproc) -v ./...
	$(GO) test -run='^$$' -fuzz=FuzzStrictNewVersion -fuzztime 1m -parallel=$(shell nproc) -v ./...

.PHONY: quickbench
## quickbench: [test]* Runs the benchmarks with minimal data for a quick check
quickbench:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running "quick" benchmark...\033[0m"
	$(GO) test -bench=. -timeout 60m ./...

.PHONY: bench
## bench: [test]* Runs the benchmarks with enough data for analysis with benchstat.
bench:
	@ $(ECHO) " "
	@ $(ECHO) "\033[1;33m=====> Running "full" benchmark...\033[0m"
	$(GO) test -bench=. -count=6 -timeout 60m -benchmem -cpuprofile=__cpu.out -memprofile=__mem.out -trace=__trace.out ./... | tee __bench-$(shell date --utc "+%Y%m%dT%H%M%SZ").out

.PHONY: view-cov-cli
## view-cov-cli: [test] After running test or unittest, this will view the coverage report on the CLI.
view-cov-cli:
	gocovsh --profile=__coverage.out

.PHONY: view-cov-html
## view-cov-html: [test] After running test or unittest, this will launch a browser to view the coverage report.
view-cov-html:
	$(GO) tool cover -html=__coverage.out

.PHONY: view-cpupprof
## view-cpupprof: [test] After running bench, this will launch a browser to view the CPU profiler results.
view-cpupprof:
	$(GO) tool pprof -http :8080 __cpu.out

.PHONY: view-mempprof
## view-mempprof: [test] After running bench, this will launch a browser to view the memory profiler results.
view-mempprof:
	$(GO) tool pprof -http :8080 __mem.out

.PHONY: view-trace
## view-trace: [test] After running bench, this will launch a browser to view the trace results.
view-trace:
	$(GO) tool trace __trace.out

#-------------------------------------------------------------------------------
# Git Tasks

.PHONY: tag
## tag: [release]* Tags (and GPG-signs) the release.
tag:
	@ if [ $$(git status -s -uall | wc -l) != 1 ]; then echo 'ERROR: Git workspace must be clean.'; exit 1; fi;

	@echo "This release will be tagged as: $$(cat ./VERSION)"
	@echo "This version should match your release. If it doesn't, re-run 'make version'."
	@echo "---------------------------------------------------------------------"
	@read -p "Press any key to continue, or press Control+C to cancel. " x;

	@echo " "
	@chag update $$(cat ./VERSION)
	@echo " "

	@echo "These are the contents of the CHANGELOG for this release. Are these correct?"
	@echo "---------------------------------------------------------------------"
	@chag contents
	@echo "---------------------------------------------------------------------"
	@echo "Are these release notes correct? If not, cancel and update CHANGELOG.md."
	@read -p "Press any key to continue, or press Control+C to cancel. " x;

	@echo " "

	git add .
	git commit -a -m "Preparing the $$(cat ./VERSION) release."
	chag tag --sign

.PHONY: version
## version: [release]* Sets the version for the next release; pre-req for a release tag.
version:
	@echo "Current version: $$(cat ./VERSION)"
	@read -p "Enter new version number: " nv; \
	printf "$$nv" > ./VERSION
