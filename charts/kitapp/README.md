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
| extraEnvs | list | [] | Additional environment variables appended after `env`. Useful for overlay values files to extend env without replacing shared base entries. |
| envFrom | list | [] | Environment variable sources (ConfigMapRef/SecretRef) for the container. |
| extraEnvFrom | list | [] | Additional environment variable sources appended after `envFrom`. Useful for overlay values files to extend envFrom without replacing shared base entries. |
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
| oauth2.config | object | see values.yaml | Structured oauth2-proxy config for commonly configured keys. |
| oauth2.config.emailDomains | list | ["*"] | Email domains allowed to authenticate. Use ["*"] to allow any domain. |
| oauth2.config.allowedGroups | list | [] | Groups allowed to authenticate. Empty means no group restriction. |
| oauth2.config.skipAuthRoutes | list | [] | URL path patterns that bypass authentication. |
| oauth2.rawConfig | object | {} | Raw TOML key/value pairs appended verbatim to oauth2-proxy.cfg. Use for any oauth2-proxy setting not covered by the structured keys above. |
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
| podSecurityContext | object | see values.yaml | Security context applied to the pod (e.g. fsGroup, runAsUser, runAsGroup). |
| containerSecurityContext | object | see values.yaml | Security context applied to the application container. |

### Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service | object | see values.yaml | Service settings for exposing the application. |
| service.type | string | ClusterIP | Kubernetes Service type. |
| service.annotations | object | {} | Annotations for the Service. |

### Persistence

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| volumes | list | [] | Structured volume definitions. Each entry defines both the container mount and the pod volume source. |
| extraVolumes | list | [] | Additional structured volume definitions appended after `volumes`. Use to share common volumes in base values and extend per environment overlays. |

### Dependencies

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| templates | object | {} | Values passed to the KvalitetsIT templates dependency chart. |

### Gateway

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| gateway | object | see values.yaml | Gateway API integration settings. |
| gateway.enabled | bool | false | Enable Gateway API resources (HTTPRoute, ListenerSet, and optional policies). |
| gateway.hostnames | list | [] | Public hostname(s) for the HTTPRoute and ListenerSet. The first hostname is also used to auto-populate oauth2-proxy redirect_url. |
| gateway.port | string | null | Backend port for the auto-generated catch-all rule. Defaults to applicationPort.port, or 4180 when oauth2.enabled=true. |
| gateway.gateway | object | see values.yaml | Gateway attachment settings. |
| gateway.gateway.name | string | ingressgateway | Name of the Gateway to attach to. |
| gateway.gateway.namespace | string | istio-ingress | Namespace of the Gateway. |
| gateway.gateway.sectionName | string | "" | If set, skip ListenerSet creation and attach the HTTPRoute directly to this Gateway listener section. |
| gateway.clusterIssuer | string | letsencrypt-prod-istio | Cert-manager ClusterIssuer for auto-TLS on the ListenerSet. |
| gateway.rules | list | [] | Explicit HTTPRoute rules. If empty, a catch-all rule to the app Service is generated. |
| gateway.authorizationPolicies | object | {} | Istio AuthorizationPolicy resources keyed by name. Supports IP-based (remoteIpBlocks), path-based, and source-identity (principals) rules. |
| gateway.requestAuthentications | object | {} | Istio RequestAuthentication resources keyed by name. Use to require and validate JWTs from an OIDC provider (e.g. Keycloak). |

## Usage

This chart deploys a generic Kubernetes `Deployment` with a `Service` and optional structured `volumes`.

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
  tag: "1.31.0"

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

### Volumes and PVCs

Use a single `volumes` list where each item defines both mount options and a `volumeSpec` source.

```yaml
volumes:
  - name: app-config
    mountPath: /app/config
    readOnly: true
    subPath: application.yaml
    volumeSpec:
      configMap:
        name: my-config
```

Use `extraVolumes` with the same structure to append environment-specific entries on top of shared base `volumes`.

Mount an external PVC:

```yaml
volumes:
  - name: app-data
    mountPath: /data
    volumeSpec:
      persistentVolumeClaim:
        existingClaim: my-existing-pvc
```

Create and mount a PVC from the chart:

```yaml
volumes:
  - name: app-data
    mountPath: /data
    volumeSpec:
      persistentVolumeClaim:
        create: true
        size: 8Gi
        storageClass: nfs
        accessMode: ReadWriteMany
```

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

### Expose via Gateway API

Enable `gateway` to create an HTTPRoute and ListenerSet (with auto-TLS via cert-manager).
The backend is automatically wired to the chart's own Service. When `oauth2.enabled=true`,
the backend port defaults to `4180` and `redirect_url` is injected into the oauth2-proxy config.

```yaml
gateway:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  clusterIssuer: letsencrypt-prod-istio
```

To skip ListenerSet creation and attach directly to an existing Gateway listener:

```yaml
gateway:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
    sectionName: https-my-app
```

### Authorization policies

Use `gateway.authorizationPolicies` to create Istio `AuthorizationPolicy` resources targeting the app Service.

```yaml
gateway:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  authorizationPolicies:
    block-metrics:
      action: DENY
      rules:
        - to:
            - operation:
                paths: [/metrics]
    ip-allowlist:
      action: ALLOW
      rules:
        - from:
            - source:
                remoteIpBlocks: ["10.0.0.0/8"]
    mesh-only:
      action: ALLOW
      rules:
        - from:
            - source:
                principals: ["cluster.local/ns/frontend/sa/frontend"]
```

### JWT / RequestAuthentication (Keycloak)

Use `gateway.requestAuthentications` to create Istio `RequestAuthentication` resources
that validate JWTs from an OIDC provider such as Keycloak.

```yaml
gateway:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  requestAuthentications:
    keycloak:
      jwtRules:
        - issuer: https://keycloak.example.com/realms/myrealm
          jwksUri: https://keycloak.example.com/realms/myrealm/protocol/openid-connect/certs
          audiences:
            - my-app
          forwardOriginalToken: false
```

### Security context

Use `podSecurityContext` for pod-level settings (fsGroup, runAsUser) and `containerSecurityContext` for container-level hardening:

```yaml
image:
  repository: nginx
  tag: "1.31.0"

applicationPort:
  name: http
  port: 8000

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault
  appArmorProfile:
    type: RuntimeDefault
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
  image: ghcr.io/oauth2-proxy/oauth2-proxy:v7.15.0
  upstream: http://127.0.0.1:8000
  clientId: portal
  issuerUrl: https://issuer.example.com/realms/portal
  config:
    emailDomains:
      - example.com
    allowedGroups:
      - admins
    skipAuthRoutes:
      - ^/healthz$
  overrides:
    annotations:
      oauth2-proxy.kitkube.dk/sidecar.requests.cpu: 50m
      oauth2-proxy.kitkube.dk/sidecar.requests.memory: 64Mi
```

See [`ci/oauth2-advanced-values.yaml`](ci/oauth2-advanced-values.yaml).

### Gateway + OAuth2 combined

When both `gateway.enabled=true` and `oauth2.enabled=true`, the chart automatically:
- Routes the HTTPRoute catch-all rule to the oauth2-proxy sidecar port `4180`
- Injects `redirect_url = https://<first-hostname>/oauth2/callback` into the oauth2-proxy ConfigMap

```yaml
gateway:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress

oauth2:
  enabled: true
  secretRef: my-app-oauth2-proxy-envs
  clientId: portal
  issuerUrl: https://keycloak.example.com/realms/myrealm
```

### CI examples (from files)

These snippets are injected directly from `ci/*.yaml` so docs stay in sync with tested examples.
Only unique, high-signal examples are included here to avoid duplication.

<details>
<summary><code>ci/minimal-values.yaml</code></summary>

```yaml
image:
  repository: nginx
  tag: "1.31.0"

applicationPort:
  name: http
  port: 8000
```
</details>

<details>
<summary><code>ci/pvc-values.yaml</code></summary>

```yaml
image:
  repository: nginx
  tag: "1.31.0"

applicationPort:
  port: 80

volumes:
  - name: app-data
    mountPath: /data
    volumeSpec:
      persistentVolumeClaim:
        existingClaim: my-existing-pvc
  - name: app-config-file
    mountPath: /app/config/application.yaml
    subPath: application.yaml
    volumeSpec:
      configMap:
        name: app-config
        items:
          - key: application.yaml
            path: application.yaml
  - name: app-cache
    mountPath: /cache
    volumeSpec:
      emptyDir: {}
  - name: app-data-created
    mountPath: /created
    volumeSpec:
      persistentVolumeClaim:
        create: true
        size: 1Gi
```
</details>

<details>
<summary><code>ci/authpolicy-values.yaml</code></summary>

```yaml
image:
  repository: nginx
  tag: "1.31.0"

applicationPort:
  name: http
  port: 8000

gateway:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  clusterIssuer: letsencrypt-prod-istio
  authorizationPolicies:
    block-metrics:
      action: DENY
      rules:
        - to:
            - operation:
                paths:
                  - /metrics
    ip-allowlist:
      action: ALLOW
      rules:
        - from:
            - source:
                remoteIpBlocks:
                  - "10.0.0.0/8"
    mesh-only:
      action: ALLOW
      rules:
        - from:
            - source:
                principals:
                  - "cluster.local/ns/frontend/sa/frontend"
  requestAuthentications:
    keycloak:
      jwtRules:
        - issuer: https://keycloak.example.com/realms/myrealm
          jwksUri: https://keycloak.example.com/realms/myrealm/protocol/openid-connect/certs
          audiences:
            - my-app
          forwardOriginalToken: false
```
</details>

<details>
<summary><code>ci/oauth2-advanced-values.yaml</code></summary>

```yaml
image:
  repository: ghcr.io/your-org/your-app
  tag: "1.31.0"

applicationPort:
  name: http
  port: 8000

servicePort:
  port: 8000

oauth2:
  enabled: true
  secretRef: my-app-oauth2-proxy-envs
  image: ghcr.io/oauth2-proxy/oauth2-proxy:v7.15.0
  upstream: http://127.0.0.1:8000
  clientId: portal
  issuerUrl: https://issuer.example.com/realms/portal
  config:
    emailDomains:
      - example.com
    allowedGroups:
      - admins
    skipAuthRoutes:
      - ^/healthz$
  sidecar:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
  providerCA:
    configMap: oidc-provider-ca
    key: ca.crt

gateway:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  clusterIssuer: letsencrypt-prod-istio
```
</details>

<details>
<summary><code>ci/advanced-values.yaml</code></summary>

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.31.0"

env:
  - name: EXAMPLE
    value: hello

extraEnvs:
  - name: LOG_LEVEL
    value: debug

applicationPort:
  name: http
  port: 8000
  protocol: TCP

additionalApplicationPorts:
  - name: grpc
    port: 9095
    protocol: TCP

servicePort:
  port: 8000

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 300m
    memory: 256Mi

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL

livenessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 10
  periodSeconds: 20

readinessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
```
</details>

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
