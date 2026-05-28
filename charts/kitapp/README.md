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

## Values

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | "" | Override the chart name used for resource naming. |
| fullnameOverride | string | "" | Fully override the generated full resource name. |
| replicas | int | 2 | Number of pod replicas. |
| strategy | object | see values.yaml | Deployment strategy configuration. |
| strategy.type | string | RollingUpdate | Deployment strategy type. |
| revisionHistoryLimit | int | 5 | Number of old ReplicaSets to retain for Deployment rollback history. |
| imagePullSecrets | list | [] | Optional list of image pull secrets. |
| podLabels | object | {} | Extra labels to add to the pod. |
| podAnnotations | object | {} | Extra pod annotations. |
| nodeSelector | object | {} | Node selector labels for pod scheduling. |
| tolerations | list | [] | Pod tolerations for scheduling onto tainted nodes. |
| affinity | object | see values.yaml | Kubernetes affinity rules for pod scheduling. Defaults to preferred pod anti-affinity across nodes for replicas from the same release. |
| serviceAccount | object | see values.yaml | Service account settings. |
| serviceAccount.create | bool | false | Create a dedicated ServiceAccount. |
| serviceAccount.name | string | "" | Existing ServiceAccount name to use (or generated when empty and create=true). |
| serviceAccount.annotations | object | {} | Annotations for the ServiceAccount. |
| serviceAccount.automountServiceAccountToken | bool | false | Mount the ServiceAccount token into pods. |
| podSecurityContext | object | see values.yaml | Security context applied to the pod (e.g. fsGroup, runAsUser, runAsGroup). |

### Runtime

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image | object | see values.yaml | Container image settings. |
| image.repository | string | "" | Container image repository (required). |
| image.tag | string | "" | Container image tag (required). |
| image.pullPolicy | string | IfNotPresent | Image pull policy. |
| command | list | [] | Optional container command override. |
| args | list | [] | Optional container args override. |
| env | list | [] | Environment variables for the container. |
| extraEnvs | list | [] | Additional environment variables appended after `env`. Useful for overlay values files to extend env without replacing shared base entries. |
| envFrom | list | [] | Environment variable sources (ConfigMapRef/SecretRef) for the container. |
| extraEnvFrom | list | [] | Additional environment variable sources appended after `envFrom`. Useful for overlay values files to extend envFrom without replacing shared base entries. |
| resources | object | {} | Container resource requests and limits. |
| livenessProbe | object | {} | Kubernetes liveness probe. |
| readinessProbe | object | {} | Kubernetes readiness probe. |
| startupProbe | object | {} | Kubernetes startup probe. |
| containerSecurityContext | object | see values.yaml | Security context applied to the application container. |

### Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applicationPort | object | see values.yaml | Primary application port exposed by the container and Service. |
| applicationPort.name | string | http | Primary application port name. |
| applicationPort.port | int | 8080 | Primary application container port. |
| applicationPort.protocol | string | TCP | Primary application protocol. |
| additionalApplicationPorts | list | [] | Additional named application ports exposed on both container and Service. Each item supports name, port, and optional protocol. |
| servicePort | object | see values.yaml | Primary Service port exposed by the Service. |
| servicePort.name | string | null | Primary Service port name. If empty, falls back to applicationPort.name. |
| servicePort.port | string | null | Primary Service port number. If empty, defaults to applicationPort.port. |
| servicePort.protocol | string | null | Primary Service protocol. If empty, falls back to applicationPort.protocol. |
| additionalServicePorts | list | [] | Additional Service-only ports. Each item supports `name`, `port`, optional `targetPort`, and optional `protocol`. If `targetPort` is omitted, it defaults to the same value as `port`. |
| service | object | see values.yaml | Service settings for exposing the application. |
| service.type | string | ClusterIP | Kubernetes Service type. |
| service.annotations | object | {} | Annotations for the Service. |
| service.labels | object | see values.yaml | Labels for the Service. |
| service.labels."istio.io/use-waypoint" | string | `"waypoint"` | Route traffic through the Istio waypoint proxy for L7 policy enforcement. |
| service.labels."istio.io/ingress-use-waypoint" | string | `"true"` | Apply waypoint enforcement to ingress traffic only (not east-west mesh traffic). |

### Persistence

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| volumes | list | [] | Structured volume definitions. Each entry defines both the container mount and the pod volume source. |
| extraVolumes | list | [] | Additional structured volume definitions appended after `volumes`. Use to share common volumes in base values and extend per environment overlays. |

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

### Route

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| route | object | see values.yaml | Gateway API route settings. |
| route.enabled | bool | false | Enable Gateway API resources (HTTPRoute or TLSRoute, ListenerSet, and optional policies). |
| route.type | string | HTTPRoute | Route type. Supports HTTPRoute or TLSRoute. |
| route.exposeMetrics | bool | true | Expose the /metrics path via the HTTPRoute. Set to false to block external access to metrics. When false, a PathPrefix /metrics rule with no backends is prepended before the catch-all. Istio returns 404 for empty backendRefs: https://github.com/istio/istio/blob/2ca2c3cbf76713c720d22b57e6995bdd5ad65153/pilot/pkg/config/kube/gateway/conversion.go#L231-L235 HTTPRoute only. |
| route.hostnames | list | [] | Public hostname(s) for the HTTPRoute and ListenerSet. The first hostname is also used to auto-populate oauth2-proxy redirect_url. |
| route.port | string | null | Backend port for the auto-generated catch-all rule. Defaults to applicationPort.port, or 4180 when oauth2.enabled=true. |
| route.gateway | object | see values.yaml | Gateway attachment settings. |
| route.gateway.name | string | ingressgateway | Name of the Gateway to attach to. |
| route.gateway.namespace | string | istio-ingress | Namespace of the Gateway. |
| route.gateway.sectionName | string | "" | If set, skip ListenerSet creation and attach the route directly to this Gateway listener section. |
| route.clusterIssuer | string | letsencrypt-prod-istio | Cert-manager ClusterIssuer for auto-TLS on the ListenerSet. HTTPRoute only. |
| route.rules | list | [] | Explicit HTTPRoute rules prepended before the catch-all. HTTPRoute only. |
| route.authorizationPolicies | object | {} | Istio AuthorizationPolicy resources keyed by name. Supports IP-based (remoteIpBlocks), path-based, and source-identity (principals) rules. |
| route.requestAuthentications | object | {} | Istio RequestAuthentication resources keyed by name. HTTPRoute only — requires decrypted traffic. Use to require and validate JWTs from an OIDC provider (e.g. Keycloak). |

### OAuth2

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| oauth2 | object | see values.yaml | OAuth2 proxy injector integration. Adds required pod label and annotations for the KvalitetsIT oauth2-proxy-injector webhook. |
| oauth2.enabled | bool | false | Enable oauth2-proxy sidecar injection metadata on the pod. |
| oauth2.proxyPort | int | 4180 | Port oauth2-proxy listens on. Used for `http_address` in oauth2-proxy.cfg, the Service port, and the gateway backend port. |
| oauth2.image | string | "" | Optional oauth2-proxy image override. Renders injector annotation `oauth2-proxy.kitkube.dk/image`. |
| oauth2.upstream | string | "" | Dedicated upstream URL for oauth2-proxy. This is always used for `upstreams` in oauth2-proxy.cfg. Defaults to `http://127.0.0.1:<applicationPort.port>` when empty. |
| oauth2.clientId | string | "" | OIDC client ID (`client_id` in oauth2-proxy.cfg). |
| oauth2.cookieName | string | "" | Cookie name used by oauth2-proxy. Defaults to `clientId` when empty. |
| oauth2.issuerUrl | string | "" | Reusable oauth2-proxy issuer URL used by generated oauth2-proxy.cfg (`oidc_issuer_url`). |
| oauth2.config | object | see values.yaml | Structured oauth2-proxy config for commonly configured keys. |
| oauth2.config.emailDomains | list | ["*"] | Email domains allowed to authenticate. Use ["*"] to allow any domain. |
| oauth2.config.allowedGroups | list | [] | Groups allowed to authenticate. Empty means no group restriction. |
| oauth2.config.skipAuthRoutes | list | [] | URL path patterns that bypass authentication. |
| oauth2.rawConfig | object | {} | Raw TOML key/value pairs appended verbatim to oauth2-proxy.cfg. Use for any oauth2-proxy setting not covered by the structured keys above. |
| oauth2.secretRef | string | "" | Existing Secret name referenced by injector annotation (required when oauth2.enabled=true). |
| oauth2.sidecar | object | see values.yaml | Optional sidecar resource annotation settings. |
| oauth2.providerCA | object | see values.yaml | Optional provider CA annotation settings. |

### Audit

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| audit | object | see values.yaml | Audit log sidecar settings. When enabled, injects a Vector sidecar container into the pod that ships audit logs to a Vector Aggregator (e.g. the `loki-audit` chart). A ConfigMap with the Vector pipeline config is also created and mounted into the sidecar at `/etc/vector/vector.yaml`. |
| audit.enabled | bool | false | Enable the Vector audit log sidecar (ConfigMap + sidecar container). |
| audit.tenantName | string | "" | Tenant name stamped on every audit event. Required when audit.enabled=true. Set via a platform-controlled mechanism (e.g. ArgoCD helm parameter) rather than letting the application team set it freely, to prevent tenant spoofing. |
| audit.image.repository | string | timberio/vector | Vector container image repository. |
| audit.image.tag | string | 0.55.0-distroless-libc | Vector container image tag. |
| audit.image.pullPolicy | string | IfNotPresent | Image pull policy. |
| audit.resources | object | see values.yaml | Resource requests and limits for the Vector audit sidecar container. |
| audit.resources.requests.cpu | string | 50m | CPU request for the Vector audit sidecar. |
| audit.resources.requests.memory | string | 64Mi | Memory request for the Vector audit sidecar. |
| audit.resources.limits.memory | string | 128Mi | Memory limit for the Vector audit sidecar. |
| audit.config.httpPort | int | 9001 | Port the Vector HTTP source listens on inside the sidecar. The application sends audit events to this port via HTTP POST. |
| audit.config.aggregatorAddress | string | vector-aggregator.logging.svc.cluster.local:6000 | Address of the Vector Aggregator to forward audit logs to. Override in env-repo values to match your loki-audit release name and namespace. |
| audit.config.sinkVersion | string | "2" | Vector sink protocol version. |

## Usage

This chart deploys a generic Kubernetes `Deployment` with a `Service` and optional structured `volumes`.

### Required values

- `image.repository` and `image.tag` must be set
- `applicationPort.port` must be set (defaults to `8080`)
- when `oauth2.enabled=true`: `oauth2.secretRef`, `oauth2.clientId`, and `oauth2.issuerUrl` must be set
- when `route.enabled=true`: `route.hostnames` and `route.gateway.name` must be set

### Minimal

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080
```

### Runtime and scheduling

Covers `additionalApplicationPorts`, `env`/`extraEnvs`, `resources`, liveness/readiness probes, and `nodeSelector`.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

additionalApplicationPorts:
  - name: actuator
    port: 9090
    protocol: TCP

env:
  - name: EXAMPLE
    value: hello

extraEnvs:
  - name: LOG_LEVEL
    value: debug

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 300m
    memory: 256Mi

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
  initialDelaySeconds: 5
  periodSeconds: 10

nodeSelector:
  kubernetes.io/os: linux
```

### Advanced runtime

Covers `command`/`args`, `envFrom`/`extraEnvFrom`, `startupProbe`, `tolerations`, and `affinity`.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

command:
  - /bin/app

args:
  - --config=/etc/app/config.yaml

envFrom:
  - secretRef:
      name: my-app-secrets

extraEnvFrom:
  - configMapRef:
      name: my-app-config

startupProbe:
  httpGet:
    path: /healthz
    port: http
  failureThreshold: 30
  periodSeconds: 10

tolerations:
  - key: dedicated
    operator: Equal
    value: app
    effect: NoSchedule

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node-role
              operator: In
              values:
                - application
```

### Metrics

When `metrics.enabled=true`, the metrics port name is always `metrics`.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  port: 8080

metrics:
  enabled: true
  port: 9090
  path: /metrics
  labels:
    release: kube-prometheus-stack
```

### Volumes and PVCs

Use `volumes` to define both the container mount and the pod volume source in a single entry.
Use `extraVolumes` to append entries on top of a shared base without replacing it.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

volumes:
  - name: app-data
    mountPath: /data
    volumeSpec:
      persistentVolumeClaim:
        create: true
        accessMode: ReadWriteOnce
        size: 1Gi

  - name: app-config
    mountPath: /etc/app/config.yaml
    subPath: config.yaml
    readOnly: true
    volumeSpec:
      configMap:
        name: my-app-config

  - name: tmp
    mountPath: /tmp
    volumeSpec:
      emptyDir: {}

extraVolumes:
  - name: shared-cache
    mountPath: /cache
    volumeSpec:
      emptyDir: {}
```

To mount an externally managed PVC, use `existingClaim` instead of `create`:

```yaml
volumes:
  - name: app-data
    mountPath: /data
    volumeSpec:
      persistentVolumeClaim:
        existingClaim: my-existing-pvc
```

### Expose via Gateway API

Enable `route` to create an HTTPRoute and ListenerSet (with auto-TLS via cert-manager).
The backend is automatically wired to the chart's own Service.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

route:
  enabled: true
  hostnames:
    - app.local
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  clusterIssuer: letsencrypt-prod-istio
```

To skip ListenerSet creation and attach directly to an existing Gateway listener, set `route.gateway.sectionName`:

```yaml
route:
  gateway:
    sectionName: https-my-app
```

### TLSRoute

For passthrough TLS (e.g. gRPC-TLS or raw TCP), use `route.type: TLSRoute`.
No ListenerSet or cert-manager is involved.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: https
  port: 8443

route:
  enabled: true
  type: TLSRoute
  hostnames:
    - app.local
  gateway:
    name: ingressgateway
    namespace: istio-ingress
```

### Authorization policies and JWT validation

Use `route.authorizationPolicies` to create Istio `AuthorizationPolicy` resources targeting the app Service.
Use `route.requestAuthentications` to create Istio `RequestAuthentication` resources that validate JWTs
from an OIDC provider such as Keycloak.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

route:
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

### Security context

Override `podSecurityContext` and `containerSecurityContext` to harden the pod.
Enable AppArmor only on clusters where it is available on the nodes.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

serviceAccount:
  create: true
  annotations:
    this-is-a-key: this-is-a-value

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 65534
  runAsGroup: 65534
  fsGroup: 65534

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

Auto-injected metadata:

- label: `oauth2-proxy.kitkube.dk/inject: "true"`
- annotations: `oauth2-proxy.kitkube.dk/configmap`, `oauth2-proxy.kitkube.dk/secret`, `checksum/oauth2-config`

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

servicePort:
  port: 8080

oauth2:
  enabled: true
  secretRef: my-app-oauth2-proxy-envs
  clientId: portal
  issuerUrl: https://issuer.example.com/realms/portal

route:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  clusterIssuer: letsencrypt-prod-istio
```

Use `oauth2.sidecar` and `oauth2.providerCA` for advanced injector annotations:

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

servicePort:
  port: 8080

oauth2:
  enabled: true
  secretRef: my-app-oauth2-proxy-envs
  image: ghcr.io/oauth2-proxy/oauth2-proxy:v7.15.0
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

route:
  enabled: true
  hostnames:
    - my-app.example.com
  gateway:
    name: ingressgateway
    namespace: istio-ingress
  clusterIssuer: letsencrypt-prod-istio
```

### Route + OAuth2

When both `route.enabled=true` and `oauth2.enabled=true`, the chart automatically:
- Routes the HTTPRoute catch-all rule to the oauth2-proxy sidecar port `4180`
- Injects `redirect_url = https://<first-hostname>/oauth2/callback` into the oauth2-proxy ConfigMap

Both are shown combined in [`ci/oauth2-minimal-values.yaml`](ci/oauth2-minimal-values.yaml).

### Audit

Enable `audit` to inject a Vector native sidecar that receives audit events from the application
over HTTP and forwards them to a Vector Aggregator (e.g. the `loki-audit` chart). The application
POSTs structured JSON to `127.0.0.1:<httpPort>` inside the pod.

#### Event schema

| Field     | Type   | Required | Description                                              |
|-----------|--------|----------|----------------------------------------------------------|
| `message` | string | yes      | Human-readable description of what happened.             |
| `actor`   | string | yes      | Identity of the user or system that performed the action.|
| `action`  | string | yes      | Machine-readable action identifier (e.g. `CREATE`).      |
| `data`    | object | no       | Arbitrary structured context for the event.              |

```json
{
  "message": "User updated patient record",
  "actor": "doctor@hospital.dk",
  "action": "UPDATE",
  "data": {
    "resourceId": "patient-42",
    "resourceType": "PatientRecord",
    "changes": {
      "diagnosis": "updated"
    }
  }
}
```

The sidecar rejects events where required fields are missing, blank, or where `data` is not an object.
Events are enriched with Kubernetes pod metadata (`pod_name`, `pod_namespace`, `node_name`, `pod_ip`) before forwarding.

```yaml
image:
  repository: docker.io/mccutchen/go-httpbin
  tag: "v2.15.0"

applicationPort:
  name: http
  port: 8080

audit:
  enabled: true
  tenantName: test-tenant
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
