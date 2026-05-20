# kitapp Helm Chart

Generic application Helm chart for deploying a Kubernetes `Deployment`.

Chart path: [`charts/kitapp`](charts/kitapp)

## Quick start

```sh
helm install my-app ./charts/kitapp
```

## Example values

```yaml
replicaCount: 2

image:
  repository: ghcr.io/your-org/your-app
  tag: "1.0.0"

applicationPort:
  name: http
  port: 8080
  protocol: TCP

service:
  type: ClusterIP

servicePort: 8080

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
- [`charts/kitapp/ci/oauth2-minimal-values.yaml`](charts/kitapp/ci/oauth2-minimal-values.yaml)
- [`charts/kitapp/ci/oauth2-advanced-values.yaml`](charts/kitapp/ci/oauth2-advanced-values.yaml)
