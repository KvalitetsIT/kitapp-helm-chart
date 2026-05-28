all: lint docs

lint:
	docker run --rm --name chart-testing -w /data -v $(PWD):/data quay.io/helmpack/chart-testing:v3.14.0 ct lint --config /data/ct.yaml

docs:
	docker run --rm --name helm-docs -v "$(PWD):/helm-docs" jnorwood/helm-docs:v1.14.2 --sort-values-order file --chart-search-root charts/ --output-file README.md

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
