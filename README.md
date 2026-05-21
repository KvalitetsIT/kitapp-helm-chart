# kitapp Helm Chart

Generic application Helm chart for deploying a Kubernetes `Deployment`.

## What This Repository Contains

- Chart source: [`charts/kitapp`](charts/kitapp)
- Full chart docs (values reference, generated docs): [`charts/kitapp/README.md`](charts/kitapp/README.md)
- CI values used for rendering/linting scenarios:
  - [`charts/kitapp/ci/minimal-values.yaml`](charts/kitapp/ci/minimal-values.yaml)
  - [`charts/kitapp/ci/deployment-values.yaml`](charts/kitapp/ci/deployment-values.yaml)
  - [`charts/kitapp/ci/ingress-values.yaml`](charts/kitapp/ci/ingress-values.yaml)
  - [`charts/kitapp/ci/metrics-values.yaml`](charts/kitapp/ci/metrics-values.yaml)
  - [`charts/kitapp/ci/pvc-values.yaml`](charts/kitapp/ci/pvc-values.yaml)
  - [`charts/kitapp/ci/oauth2-minimal-values.yaml`](charts/kitapp/ci/oauth2-minimal-values.yaml)
  - [`charts/kitapp/ci/oauth2-advanced-values.yaml`](charts/kitapp/ci/oauth2-advanced-values.yaml)

## Review Guide

Use this sequence to review quickly and consistently:

1. Verify API shape in [`charts/kitapp/values.yaml`](charts/kitapp/values.yaml).
2. Verify rendering behavior in:
   - [`charts/kitapp/templates/deployment.yaml`](charts/kitapp/templates/deployment.yaml)
   - [`charts/kitapp/templates/service.yaml`](charts/kitapp/templates/service.yaml)
   - [`charts/kitapp/templates/validate.yaml`](charts/kitapp/templates/validate.yaml)
3. Verify docs and examples match actual schema:
   - [`charts/kitapp/README.md`](charts/kitapp/README.md)
   - `charts/kitapp/ci/*.yaml`
4. Verify chart metadata and dependencies in [`charts/kitapp/Chart.yaml`](charts/kitapp/Chart.yaml).

## Required Inputs

At minimum, a consumer must provide:

- `image.repository`
- `image.tag`
- `applicationPort.name`
- one of `applicationPort.port` or `servicePort.port`

## Example Configurations

### Expanded: Typical App Deployment

```yaml
replicaCount: 2

image:
  repository: ghcr.io/your-org/your-app
  tag: "1.31.0"

applicationPort:
  name: http
  port: 8080
  protocol: TCP

service:
  type: ClusterIP

servicePort:
  port: 8080

livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 10
  periodSeconds: 20

readinessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
```

<details>
<summary>Gateway API Route Example</summary>

```yaml
ingress:
  routes:
    app:
      httpRoute:
        hostnames:
          - my-app.example.com
        rules:
          - backendRefs:
              - name: my-app
                port: 8080
```

</details>

<details>
<summary>Metrics Example</summary>

```yaml
metrics:
  enabled: true
  port: 9090
  path: /metrics
  labels:
    release: kube-prometheus-stack
```

</details>

<details>
<summary>OAuth2 Minimal Example</summary>

```yaml
oauth2:
  enabled: true
  secretRef: my-app-oauth2-proxy-envs
  clientId: portal
  issuerUrl: https://issuer.example.com/realms/portal
```

</details>

## Notes for Maintainers

- Root README is intentionally high-level.
- Detailed value docs are maintained in `charts/kitapp/README.md`.
- If values/templates change, regenerate chart docs and keep CI values aligned.
