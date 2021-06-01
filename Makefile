DB_SPANNER_SCHEMA := db/spanner.sql
OUT_DIR := internal
MODEL_PATH := github.com/s-you/yo-templates/internal/model
SED_EXEC := $(shell which sed)

## ENV
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
GO_FILES_ALL = $(shell bin/golist --exclude-suffixes 'gen.go,_test.go,_mock.go,mock')

build-tools:
	go build -o bin/golist github.com/s-you/golist
	go build -o bin/yo go.mercari.io/yo
	go build -o bin/goimports golang.org/x/tools/cmd/goimports
	@[ -d .git ] && git checkout go.* || true

gen: yo-gen

update-model-path:
	@for f in `find $(OUT_DIR) -name '*.gen.go'`; \
		do $(SED_EXEC) -i -e "s|github.com/s-you/yo-templates/internal/model|$(MODEL_PATH)|" $$f; \
	done;

yo-gen:
	$(eval export PATH=$(shell pwd)/bin:$(PATH))
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/model \
		--from-ddl \
		--template-path ./templates/model \
		--inflection-rule-file templates/inflection_rule.yml \
		--suffix .gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/model \
		--from-ddl \
		--template-path ./templates/model_entities \
		--inflection-rule-file templates/inflection_rule.yml \
		--suffix _entities.gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/model \
		--from-ddl \
		--template-path ./templates/model_identity \
		--inflection-rule-file templates/inflection_rule.yml \
		--suffix _identity.gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/model \
		--from-ddl \
		--template-path ./templates/model_crud \
		--inflection-rule-file templates/inflection_rule.yml \
		--suffix _crud.gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/repository \
		--from-ddl \
		--template-path ./templates/repository \
		--inflection-rule-file templates/inflection_rule.yml \
		--custom-types-file templates/custom_types.yml \
		--custom-type-package model \
		--suffix .gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/repository \
		--from-ddl \
		--template-path ./templates/repository_indexes \
		--inflection-rule-file templates/inflection_rule.yml \
		--custom-types-file templates/custom_types.yml \
		--custom-type-package model \
		--suffix _indexes.gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/repository \
		--from-ddl \
		--template-path ./templates/repository_crud \
		--inflection-rule-file templates/inflection_rule.yml \
		--custom-types-file templates/custom_types.yml \
		--custom-type-package model \
		--suffix _crud.gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/repository \
		--from-ddl \
		--template-path ./templates/repository_all \
		--inflection-rule-file templates/inflection_rule.yml \
		--custom-types-file templates/custom_types.yml \
		--custom-type-package model \
		--suffix _all.gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/repository \
		--from-ddl \
		--template-path ./templates/repository_all_interfaces \
		--inflection-rule-file templates/inflection_rule.yml \
		--custom-types-file templates/custom_types.yml \
		--custom-type-package model \
		--suffix _all_interfaces.gen.go \
		--single-file
	bin/yo generate $(DB_SPANNER_SCHEMA) -o $(OUT_DIR)/repository \
		--from-ddl \
		--template-path ./templates/repository_util \
		--inflection-rule-file templates/inflection_rule.yml \
		--custom-types-file templates/custom_types.yml \
		--custom-type-package model \
		--suffix _util.gen.go \
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
