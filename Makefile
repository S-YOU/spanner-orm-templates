DB_SPANNER_SCHEMA := db/spanner.sql

## ENV
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
GO_FILES_ALL = $(shell bin/golist --exclude-suffixes 'gen.go,_test.go,_mock.go,mock')

build-tools:
	go build -o bin/golist github.com/s-you/golist
	go build -o bin/yo go.mercari.io/yo
	go build -o bin/goimports golang.org/x/tools/cmd/goimports
	@[ -d .git ] && git checkout go.* || true

gen: yo-gen

yo-gen:
	$(eval export PATH=$(shell pwd)/bin:$(PATH))
	bin/yo generate $(DB_SPANNER_SCHEMA) -o internal/model \
		--from-ddl \
		--template-path ./templates/model \
		--inflection-rule-file templates/inflection_rule.yml \
		--suffix .gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o internal/repository \
		--from-ddl \
		--template-path ./templates/repository \
		--inflection-rule-file templates/inflection_rule.yml \
		--custom-types-file templates/custom_types.yml \
		--custom-type-package model \
		--suffix .gen.go \
		--single-file

### test
test:
	go test -v -p 1 ./...

### fmt
fmt:
	@bin/goimports -local github.com/s-you -l -w ${GO_FILES_ALL}

lint: vet
	@LINT="$$(bin/goimports -local github.com/s-you -l -format-only ${GO_FILES_ALL})"; printf "$$LINT"; \
		[ -z "$$LINT" ] && echo "lint ok"

### vet
vet:
	go vet ./...
