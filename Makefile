.PHONY: all build dev install clean release vendor dist

-include Makefile.inc

VERSION := $(shell git describe --always --dirty --tags)
SHA := $(shell git rev-parse --short HEAD)
BRANCH := $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))
BUILD := $(SHA)-$(BRANCH)
TARBALL := dist/mirrorbits-$(VERSION).tar.gz

distdir ?= mirrorbits_$(VERSION)
DIST_TARBALL := $(distdir).tar.gz

PACKAGE = github.com/etix/mirrorbits

GOFLAGS := -ldflags "-X $(PACKAGE)/core.VERSION=$(VERSION) -X $(PACKAGE)/core.BUILD=$(BUILD)"
GOFLAGSDEV := -race -ldflags "-X $(PACKAGE)/core.VERSION=$(VERSION) -X $(PACKAGE)/core.BUILD=$(BUILD) -X $(PACKAGE)/core.DEV=-dev"

export PATH := ${GOPATH}/bin:$(PATH)

all: build

ifdef USE_TEMP_GOPATH
WITH_TEMP_GOPATH = ./with-temp-gopath.sh ${PACKAGE}
endif

vendor:
ifdef DISABLE_GOVENDOR
	@echo Assuming vendored code is already present
else
	which govendor 2>/dev/null || go get github.com/kardianos/govendor
	$(WITH_TEMP_GOPATH) govendor sync ${PACKAGE}
endif

build: vendor
	$(WITH_TEMP_GOPATH) go build $(GOFLAGS) -o bin/mirrorbits .

dev: vendor
	go build $(GOFLAGSDEV) -o bin/mirrorbits .

install: vendor
	go install -v $(GOFLAGS) .

clean:
	@echo Cleaning workspace...
	@rm -dRf bin dist $(DIST_TARBALL)

release: $(TARBALL)

test:
	@govendor test $(GOFLAGS) -v -cover +local

$(TARBALL): build
	@echo Packaging release...
	@mkdir -p tmp/mirrorbits
	@cp -f bin/mirrorbits tmp/mirrorbits/
	@cp -r templates tmp/mirrorbits/
	@cp mirrorbits.conf tmp/mirrorbits/
	@mkdir -p dist/
	@tar -czf $@ -C tmp mirrorbits && echo release tarball has been created: $@
	@rm -rf tmp

$(DIST_TARBALL): vendor clean
	mkdir -p dist
	tar -czf dist/$@ --transform "s,^\\./,$(distdir)/," --exclude-vcs --exclude dist .
	mv dist/$@ $@

dist: $(DIST_TARBALL)
