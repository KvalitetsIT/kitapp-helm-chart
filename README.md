# kitapp Helm chart repository

Repository for the generic `kitapp` Helm chart.

The chart lives in [`charts/kitapp`](charts/kitapp).

---

## Where to find chart documentation

To avoid duplicate maintenance, all chart API and usage docs are maintained in:

- [`charts/kitapp/README.md`](charts/kitapp/README.md)

That file is generated from `README.md.gotmpl` and CI example values.

---

## Repository structure

```text
.
├── charts/
│   └── kitapp/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── README.md.gotmpl
│       ├── README.md
│       ├── templates/
│       └── ci/
│           └── *-values.yaml
├── Makefile
├── ct.yaml
└── README.md
```

---

## Development

### Prerequisites

- Docker (used by `make docs` and `make lint`)

### Generate chart docs

```sh
make docs
```

Regenerates [`charts/kitapp/README.md`](charts/kitapp/README.md) from:

- `charts/kitapp/README.md.gotmpl`
- chart metadata and values docs
- `charts/kitapp/ci/*.yaml` examples

### Lint chart

```sh
make lint
```

Runs chart-testing (`ct lint`) using `ct.yaml`.

---

## Maintainer notes

- Keep this root README repository-focused (setup/workflow only).
- Put chart behavior, values, and examples in `charts/kitapp/README.md.gotmpl` and `charts/kitapp/ci/*.yaml`.
- Do not edit generated `charts/kitapp/README.md` manually.
