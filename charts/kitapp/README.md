# kitapp

Small generic Helm chart for deploying a Kubernetes application as a Deployment.

**Homepage:** <https://github.com/KvalitetsIT>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| KvalitetsIT | <kithosting@kvalitetsit.dk> | <https://github.com/KvalitetsIT/helm-repo> |

## Source Code

* <https://github.com/KvalitetsIT/kitapp-helm-chart>
* <https://github.com/KvalitetsIT/kitapp-helm-chart/tree/main/charts/kitapp>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/ | ingress(gateway-routes) | 0.0.5 |
| https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/ | templates | 2.1.1 |

## Values

### Naming

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | "" | Override the chart name used for resource naming. |
| fullnameOverride | string | "" | Fully override the generated full resource name. |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | 1 | Number of pod replicas. |
| strategy | object | see values.yaml | Deployment strategy configuration. |
| strategy.type | string | RollingUpdate | Deployment strategy type. |

### Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image | object | see values.yaml | Container image settings. |
| image.repository | string | "" | Container image repository (required). |
| image.tag | string | "" | Container image tag (required). |
| image.pullPolicy | string | IfNotPresent | Image pull policy. |
| imagePullSecrets | list | [] | Optional list of image pull secrets. |

### Ports

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applicationPort | object | see values.yaml | Primary application port exposed by the container and Service. |
| applicationPort.name | string | http | Primary application port name. |
| applicationPort.port | string | null | Primary application container port. If empty, falls back to servicePort. |
| applicationPort.protocol | string | TCP | Primary application protocol. |
| additionalApplicationPorts | list | [] | Additional named application ports exposed on both container and Service. Each item supports name, port, and optional protocol. |
| servicePort | object | see values.yaml | Primary Service port exposed by the Service. |
| servicePort.name | string | null | Primary Service port name. If empty, falls back to applicationPort.name. |
| servicePort.port | string | null | Primary Service port number. If empty, falls back to applicationPort.port. |
| servicePort.protocol | string | null | Primary Service protocol. If empty, falls back to applicationPort.protocol. |
| additionalServicePorts | list | [] | Additional Service-only ports. Each item supports `name`, `port`, optional `targetPort`, and optional `protocol`. If `targetPort` is omitted, it defaults to the same value as `port`. |

### Runtime

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| command | list | [] | Optional container command override. |
| args | list | [] | Optional container args override. |
| env | list | [] | Environment variables for the container. |
| additionalEnvs | list | [] | Additional environment variables appended after `env`. Useful for overlay values files to extend env without replacing shared base entries. |
| envFrom | list | [] | Environment variable sources (ConfigMapRef/SecretRef) for the container. |
| resources | object | {} | Container resource requests and limits. |

### Health

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| livenessProbe | object | {} | Kubernetes liveness probe. |
| readinessProbe | object | {} | Kubernetes readiness probe. |
| startupProbe | object | {} | Kubernetes startup probe. |

### OAuth2

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| oauth2 | object | see values.yaml | OAuth2 proxy injector integration. Adds required pod label and annotations for the KvalitetsIT oauth2-proxy-injector webhook. |
| oauth2.enabled | bool | false | Enable oauth2-proxy sidecar injection metadata on the pod. |
| oauth2.image | string | "" | Optional oauth2-proxy image override. Renders injector annotation `oauth2-proxy.kitkube.dk/image`. |
| oauth2.upstream | string | http://127.0.0.1:8080 | Dedicated upstream URL for oauth2-proxy. This is always used for `upstreams` in oauth2-proxy.cfg. |
| oauth2.clientId | string | "" | Reusable oauth2-proxy client id used by generated oauth2-proxy.cfg (`client_id`, `cookie_name`). |
| oauth2.issuerUrl | string | "" | Reusable oauth2-proxy issuer URL used by generated oauth2-proxy.cfg (`oidc_issuer_url`). |
| oauth2.config | object | {} | oauth2-proxy.cfg override values map. Defaults are defined in the oauth2 configmap template; values set here override those defaults. Values are appended after defaults, so duplicate keys override earlier ones. |
| oauth2.secretRef | string | "" | Existing Secret name referenced by injector annotation (required when oauth2.enabled=true). |
| oauth2.sidecar | object | see values.yaml | Optional sidecar resource annotation settings. |
| oauth2.providerCA | object | see values.yaml | Optional provider CA annotation settings. |
| oauth2.overrides.annotations | object | {} | Optional injector annotations merged into pod annotations when oauth2.enabled=true. Use for advanced injector keys (for example oauth2-proxy.kitkube.dk/image, sidecar resources, provider CA settings). |

### Pod Metadata

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podLabels | object | {} | Extra labels to add to the pod. |
| podAnnotations | object | {} | Extra pod annotations. |

### Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics | object | see values.yaml | Metrics settings for optional metrics port and ServiceMonitor. |
| metrics.enabled | bool | false | Enable metrics port exposure on container and Service. The metrics port name is always `metrics` when enabled. |
| metrics.port | string | null | Metrics port number. If empty, uses applicationPort.port. |
| metrics.path | string | /metrics | Metrics scrape path. |
| metrics.interval | string | 30s | ServiceMonitor scrape interval. |
| metrics.labels | object | {} | Extra labels for the ServiceMonitor (when metrics.enabled=true and ServiceMonitor CRD is installed). |
| metrics.annotations | object | {} | Extra annotations for the ServiceMonitor (when metrics.enabled=true and ServiceMonitor CRD is installed). |

### Security

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceAccount | object | see values.yaml | Service account settings. |
| serviceAccount.create | bool | true | Create a dedicated ServiceAccount. |
| serviceAccount.name | string | "" | Existing ServiceAccount name to use (or generated when empty and create=true). |
| serviceAccount.annotations | object | {} | Annotations for the ServiceAccount. |

### Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service | object | see values.yaml | Service settings for exposing the application. |
| service.type | string | ClusterIP | Kubernetes Service type. |
| service.annotations | object | {} | Annotations for the Service. |

### Persistence

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| persistence | object | see values.yaml | Mount an existing PVC into the pod. |
| persistence.enabled | bool | false | Enable mounting an existing PersistentVolumeClaim. |
| persistence.existingClaim | string | "" | Existing PersistentVolumeClaim name (required when persistence.enabled=true). |
| persistence.mountPath | string | /data | Container mount path for the existing PVC. |

### Dependencies

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| templates | object | {} | Values passed to the KvalitetsIT templates dependency chart. |
| ingress | object | see values.yaml | Values passed to the aliased ingress dependency chart (gateway-routes). Configure Gateway API routes under ingress.routes. |
| ingress.routes | object | {} | Route definitions passed to gateway-routes. |

## Usage

This chart deploys a generic Kubernetes `Deployment` with a `Service` and optional PVC mount.

### Required values

- `image.repository` must be set
- `image.tag` must be set
- `applicationPort.name` must be set
- one of `applicationPort.port` or `servicePort.port` must be set

### Example values

```yaml
replicaCount: 1

image:
  repository: ghcr.io/your-org/your-app
  tag: "1.0.0"

env:
  - name: APP_ENV
    value: production

applicationPort:
  name: http
  port: 8000
  protocol: TCP

servicePort:
  port: 8000

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

metrics:
  enabled: true
  port: 9090
  path: /metrics
  labels:
    release: kube-prometheus-stack
```

When `metrics.enabled=true`, the metrics port name is always `metrics`.

### Additional application ports

Use `additionalApplicationPorts` to expose extra named ports on both the container and Service.

```yaml
applicationPort:
  name: http
  port: 8000

additionalApplicationPorts:
  - name: grpc
    port: 9095
    protocol: TCP
```

### Expose via Gateway API (`ingress`)

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
                port: 8000
```

### OAuth2 proxy injector integration

Enable `oauth2` to add the injector opt-in label and required annotations automatically.

### OAuth2 required metadata (auto-injected)

- label: `oauth2-proxy.kitkube.dk/inject: "true"`
- annotations:
  - `oauth2-proxy.kitkube.dk/configmap`
  - `oauth2-proxy.kitkube.dk/secret`

```yaml
oauth2:
  enabled: true
  secretRef: my-app-oauth2-proxy-envs
  clientId: portal
  issuerUrl: https://issuer.example.com/realms/portal
```

See [`ci/oauth2-minimal-values.yaml`](ci/oauth2-minimal-values.yaml).

### Advanced injector overrides

Use `oauth2.overrides.annotations` for advanced injector settings without expanding chart API:

```yaml
oauth2:
  enabled: true
  secretRef: my-app-oauth2-proxy-envs
  image: ghcr.io/oauth2-proxy/oauth2-proxy:v7.9.0
  upstream: http://127.0.0.1:8000
  clientId: portal
  issuerUrl: https://issuer.example.com/realms/portal
  config:
    email_domains:
      - example.com
    allowed_groups:
      - admins
    skip_auth_routes:
      - ^/healthz$
  overrides:
    annotations:
      oauth2-proxy.kitkube.dk/sidecar.requests.cpu: 50m
      oauth2-proxy.kitkube.dk/sidecar.requests.memory: 64Mi
```

See [`ci/oauth2-advanced-values.yaml`](ci/oauth2-advanced-values.yaml).

### Gateway-routes backend to oauth2-proxy port 4180

When `oauth2.enabled=true`, the Service always includes `oauth2-proxy:4180`, so Gateway API backendRefs can route directly to the proxy:

ingress:
  routes:
    app:
      httpRoute:
        hostnames:
          - my-app.example.com
        rules:
          - backendRefs:
              - name: my-app
                port: 4180
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
