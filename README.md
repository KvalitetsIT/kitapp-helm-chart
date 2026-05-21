# kitapp Helm Chart

Generic application Helm chart for deploying a Kubernetes `Deployment`.

Chart path: [`charts/kitapp`](charts/kitapp)

## About

This repository contains the generic `kitapp` chart and supporting examples used for validation.

For chart configuration, values reference, and usage details, see:

- [`charts/kitapp/README.md`](charts/kitapp/README.md)

## Example values

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

## Gateway API routes

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

## Local examples

- [`charts/kitapp/ci/deployment-values.yaml`](charts/kitapp/ci/deployment-values.yaml)
- [`charts/kitapp/ci/ingress-values.yaml`](charts/kitapp/ci/ingress-values.yaml)
- [`charts/kitapp/ci/metrics-values.yaml`](charts/kitapp/ci/metrics-values.yaml)
- [`charts/kitapp/ci/oauth2-minimal-values.yaml`](charts/kitapp/ci/oauth2-minimal-values.yaml)
- [`charts/kitapp/ci/oauth2-advanced-values.yaml`](charts/kitapp/ci/oauth2-advanced-values.yaml)
