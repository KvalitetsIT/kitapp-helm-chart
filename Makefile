MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

CHART_TESTING_TAG := v3.14.0
HELM_DOCS_TAG     := v1.14.2
HELM_UNITTEST_TAG := 4.2.0-1.1.0

.PHONY: all lint docs test test-update-snapshot release

all: lint docs test

lint:
	docker run --rm --name chart-testing -w /data -v $(MAKEFILE_DIR):/data quay.io/helmpack/chart-testing:$(CHART_TESTING_TAG) ct lint --config /data/ct.yaml

docs:
	docker run --rm --name helm-docs -v "$(MAKEFILE_DIR):/helm-docs" jnorwood/helm-docs:$(HELM_DOCS_TAG) --sort-values-order file --chart-search-root charts/ --output-file README.md

test:
	docker run --rm -v $(MAKEFILE_DIR):/apps helmunittest/helm-unittest:$(HELM_UNITTEST_TAG) charts/kitapp

test-update-snapshot:
	docker run --rm -v $(MAKEFILE_DIR):/apps helmunittest/helm-unittest:$(HELM_UNITTEST_TAG) -u charts/kitapp

release:
	@test -n "$(VERSION)" || (echo "Usage: make release VERSION=x.y.z" && exit 1)
	@command -v yq > /dev/null 2>&1 || (echo "Error: yq is not installed (https://github.com/mikefarah/yq)" && exit 1)
	@test "$$(git branch --show-current)" = "main" || (echo "Error: must be on main" && exit 1)
	@test -z "$$(git status --porcelain)" || (echo "Error: working tree is dirty" && exit 1)
	@git fetch origin main
	@test "$$(git rev-parse HEAD)" = "$$(git rev-parse origin/main)" || (echo "Error: not up to date with origin/main" && exit 1)
	yq -i ".version = \"$(VERSION)\"" charts/kitapp/Chart.yaml
	yq -i ".appVersion = \"$(VERSION)\"" charts/kitapp/Chart.yaml
	$(MAKE) docs
	git add charts/kitapp/Chart.yaml charts/kitapp/README.md
	git commit -m "chore: release v$(VERSION)"
	git tag -a v$(VERSION) -m "v$(VERSION)"
	git push origin main
	git push origin v$(VERSION)
	@echo ""
	@echo "Released v$(VERSION)"
