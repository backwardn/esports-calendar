export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64
export VERSION=(unknown)
GO := go
ENV ?= dev
LDFLAGS ?= -X main.version=$(VERSION)
BUILDFLAGS ?= -a -ldflags '$(LDFLAGS)'
APPSOURCES := $(wildcard internal/*/*.go cmd/*.go calendar/*.go calendar/*/*.go storage/*.go storage/*/*.go ical/*.go)
PROJECT_NAME := $(shell basename $(PWD))

ifneq ($(ENV), dev)
	LDFLAGS += -s -w -extldflags "-static"
endif

ifeq ($(shell git describe --always > /dev/null 2>&1 ; echo $$?), 0)
export VERSION = $(shell git describe --always --dirty="-git")
endif
ifeq ($(shell git describe --tags > /dev/null 2>&1 ; echo $$?), 0)
export VERSION = $(shell git describe --tags)
endif

BUILD := $(GO) build $(BUILDFLAGS)
TEST := $(GO) test $(BUILDFLAGS)

.PHONY: all ecalctl ecalserver clean test coverage

all: ecalctl ecalserver

ecalctl: bin/ecalctl
bin/ecalctl: go.mod cli/ecalctl/main.go $(APPSOURCES)
	$(BUILD) -tags $(ENV) -o $@ ./cli/ecalctl/main.go

ecalserver: bin/ecalserver
bin/ecalserver: go.mod cli/ecalserver/main.go $(APPSOURCES)
	$(BUILD) -tags $(ENV) -o $@ ./cli/ecalserver/main.go

clean:
	-$(RM) bin/*

test: TEST_TARGET := ./...
test:
	$(TEST) $(TEST_FLAGS) $(TEST_TARGET)

coverage: TEST_TARGET := .
coverage: TEST_FLAGS += -covermode=count -coverprofile $(PROJECT_NAME).coverprofile
coverage: test
