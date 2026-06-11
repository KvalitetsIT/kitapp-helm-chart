# Migration: `service` → `kitapp` + `templates`

## Before you start — ask these questions first

Before doing anything, check what files the user has provided and ask:

**1. Multi-file setup**
If the user has only provided one file, ask:
> "Do you have environment-specific overlays, e.g. `values-test.yaml` or `values-prod.yaml`? If so, please paste them all — each file needs to be migrated."

Only proceed once you have all files. Migrate the base `values.yaml` first, then each overlay in turn. In overlays, only migrate the keys that are actually present — do not repeat the full base values.

**2. Tenant setup**
Ask before migrating any `netpol.*` keys:
> "Is this app deployed into a namespace managed by the new tenant chart, or the old multitenant chart?"

- **New tenant chart** — the namespace is default-deny to everything outside it, but all traffic within the namespace is open. Apps typically need no NetworkPolicy unless they need to reach a service in another namespace. Skip migrating `netpol.*` entirely unless that is the case.
- **Old multitenant chart** — migrate `netpol.*` as documented in the NetworkPolicy section.

**4. PVCs**
If `pvc.*` keys exist, the `mountPath` is NOT stored in the `pvc` section — it is in the corresponding `deployment.extraVolumeMounts` entry. Cross-reference the PVC name against `deployment.extraVolumeMounts` to find it. Only ask if no matching mount entry exists:
> "You have PVCs defined (`{list the names}`) but I can't find a corresponding `deployment.extraVolumeMounts` entry for them. What is the `mountPath` for each? Please answer one per line, e.g. `app-data: /data`"

**5. Unsupported features — ask immediately if any are present**
Scan all provided files before starting. If any of the following keys exist anywhere, stop and ask before migrating:

| Key found | Ask |
|---|---|
| `initContainers.*` | "You have `initContainers` defined. This is not supported in `kitapp`. How do you want to handle this — bake the logic into the application image, use a Helm post-renderer, or skip it for now?" |
| `sidecar.*` | "You have `sidecar` defined. This is not supported in `kitapp` and requires manual resolution. Can you describe what the sidecar does so we can figure out the best path forward?" |
| `extraDeployments.*` or `docDeployment.*` | Add a second `kitapp` dependency with an alias matching the deployment name (see extraDeployments section). No need to ask — derive the alias from the key name. |
Do not proceed past this point until all blocking questions above are answered.

---

## Chart.yaml

Replace the `service` dependency with `kitapp`. Add `templates` only if the old values contain any of: `sealedSecret`, `netpol`, `cronjob`, `job`, `prometheusRules`.

```yaml
dependencies:
  - name: kitapp
    version: "<latest>"
    repository: https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/
  - name: templates          # only if needed — see above
    version: "<latest>"
    repository: https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/
```

All values are scoped under the dependency name:

```yaml
kitapp:
  replicas: 2
  ...

templates:
  sealedSecrets:
    ...
```

---

## Key renames

| Old | New | Notes |
|---|---|---|
| `replicaCount` | `replicas` | |
| `deployment.containerPort` | `applicationPort.port` | Omit entirely if value is `8080` (the default) |
| `deployment.commands` | `command` | |
| `deployment.args` | `args` | |
| `deployment.readinessProbe` | `readinessProbe` | |
| `deployment.livenessProbe` | `livenessProbe` | |
| `deployment.securityContext` | `containerSecurityContext` | |
| `service.port` | `servicePort.port` | Usually omit — only set if the Service port must differ from `applicationPort.port` |
| `serviceMonitor.enabled` | `metrics.enabled` | |
| `serviceMonitor.path` | `metrics.path` | |
| `serviceMonitor.targetPort` | `metrics.port` | |
| `serviceMonitor.interval` | `metrics.interval` | |
| `serviceMonitor.release` | `metrics.labels.release` | |
| `serviceAccount.automount` | `serviceAccount.automountServiceAccountToken` | |

**Drop entirely:** `deployment.enabled`, `service.enabled`, `service.targetPort`

---

## Env vars

Old format used a map with a `type` discriminator. New format is a standard Kubernetes list.

```yaml
# Old
deployment:
  env:
    MY_VAR:
      value: foo
    MY_SECRET:
      type: secretKeyRef
      name: my-secret
      key: password
    MY_CM:
      type: configMapKeyRef
      name: my-cm
      key: someKey
    POD_IP:
      type: fieldPath
      fieldPath: status.podIP
  envFrom:
    configMapRef:
      - my-configmap

# New
kitapp:
  env:
    - name: MY_VAR
      value: foo
    - name: MY_SECRET
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: password
    - name: MY_CM
      valueFrom:
        configMapKeyRef:
          name: my-cm
          key: someKey
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  envFrom:
    - configMapRef:
        name: my-configmap
```

### Env vars in multi-file setups

> ⚠️ **Helm does not merge lists — a list in an overlay completely replaces the same list in `values.yaml`.** Never put environment-specific vars into `kitapp.env` in an overlay, or you will lose all base vars.

The correct split is:

| Key | Where it lives | Purpose |
|---|---|---|
| `kitapp.env` | `values.yaml` only | All vars shared across all environments |
| `kitapp.extraEnv` | `values-test.yaml`, `values-prod.yaml` | Vars that are added or differ per environment |

```yaml
# values.yaml
kitapp:
  env:
    - name: MY_VAR
      value: foo
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP

# values-test.yaml
kitapp:
  extraEnv:
    - name: LOG_LEVEL
      value: debug

# values-prod.yaml
kitapp:
  extraEnv:
    - name: LOG_LEVEL
      value: warn
```

If the user has overlays and any env vars differ per environment, ask:
> "Which env vars differ between environments? I'll put the shared ones in `values.yaml` under `env` and the per-environment ones in each overlay under `extraEnv`."

---

## Volumes

Three old mechanisms collapse into one unified `volumes[]` list.

```yaml
# Old
deployment:
  configMapMountPaths:
    some-key:                    # key is irrelevant — just a loop identifier
      configMapMountPath: /etc/app
      configMapMountSubPath: config.yaml
  extraVolumeMounts:
    tmp:
      mountPath: /tmp
  extraVolumes:
    tmp:
      emptyDir: {}
pvc:
  app-data:
    accessMode: ReadWriteOnce
    request: 5Gi
    storageclass: nfs

# New
kitapp:
  volumes:
    - name: app-config
      mountPath: /etc/app
      subPath: config.yaml
      volumeSpec:
        configMap:
          name: <release-name>-config  # always this name — see note below
    - name: tmp
      mountPath: /tmp
      volumeSpec:
        emptyDir: {}
    - name: app-data
      mountPath: /data          # ← cross-referenced from deployment.extraVolumeMounts
      volumeSpec:
        persistentVolumeClaim:
          create: true
          accessMode: ReadWriteOnce
          size: 5Gi
          storageClass: nfs
```

> ⚠️ `configMapMountPaths` always mounts from a single chart-generated configmap named `<release-name>-config` (the data comes from `extraConfigMap`/`extraConfigMapJson` values). The map key is irrelevant. Use the actual release name when setting `volumeSpec.configMap.name`.

> ⚠️ `pvc.*` does not store `mountPath`. The mount is defined separately under `deployment.extraVolumeMounts` — cross-reference by name to find it. Only ask the user if no corresponding mount entry exists.

### Volumes in multi-file setups

The same list-overwrite problem applies to volumes. Never put environment-specific volumes into `kitapp.volumes` in an overlay.

| Key | Where it lives | Purpose |
|---|---|---|
| `kitapp.volumes` | `values.yaml` only | All volumes shared across environments |
| `kitapp.extraVolumes` | `values-test.yaml`, `values-prod.yaml` | Volumes added only in specific environments |

```yaml
# values.yaml
kitapp:
  volumes:
    - name: my-config
      mountPath: /etc/app
      subPath: config.yaml
      volumeSpec:
        configMap:
          name: my-config

# values-test.yaml
kitapp:
  extraVolumes:
    - name: debug-config
      mountPath: /etc/debug
      volumeSpec:
        configMap:
          name: debug-config
```

If the user has overlays and any volumes differ per environment, ask:
> "Are there any volumes that only exist in certain environments? I'll put shared volumes in `values.yaml` under `volumes` and environment-specific ones in each overlay under `extraVolumes`."

---

## Ingress → Route

```yaml
# Old
ingress:
  enabled: true
  hosts:
    - host: myapp.example.com

# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
```

- Only set `gateway.name`, `gateway.namespace`, or `clusterIssuer` if they differ from the defaults (`ingressgateway`, `istio-ingress`, `letsencrypt-prod-istio`).
- In overlays, only the hostname typically differs — migrate only that key in `values-test.yaml` / `values-prod.yaml`.
- `/metrics` is blocked from external access by default (`route.exposeMetrics: false`). Only set `route.exposeMetrics: true` if the old setup intentionally exposed metrics externally.

### oauth2-proxy

The old service chart had no built-in oauth2-proxy support. Detect prior usage by looking for either:

- An `openid` chart dependency in `Chart.yaml`
- `podLabels` or `podAnnotations` containing `oauth2-proxy.kitkube.dk/*` keys

If either is present, migrate to `oauth2.enabled: true` in kitapp — do not recreate a separate deployment.

```yaml
# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
  oauth2:
    enabled: true
    issuerUrl: https://keycloak.example.com
    realm: my-realm
    existingSecret: my-app-oauth2-proxy-envs  # or use provisionClient: true
```

> When `oauth2.enabled=true`, kitapp sets the route backend port to `4180` and wires up the oauth2-proxy injector webhook automatically. The first hostname in `route.hostnames` is used to auto-populate `redirect_url`.

### nginx annotation mapping

| nginx annotation | Action |
|---|---|
| _(none)_ | Simple route — no extra config needed |
| `nginx.ingress.kubernetes.io/backend-protocol: HTTP` | No action needed — Envoy always uses HTTP to the backend |
| `nginx.ingress.kubernetes.io/force-ssl-redirect: "true"` | No action needed — the ListenerSet only exposes port 443 |
| `nginx.ingress.kubernetes.io/rewrite-target` | See [Path rewrite](#path-rewrite) below |
| `nginx.ingress.kubernetes.io/app-root` | See [App-root redirect](#app-root-redirect) below |
| `nginx.ingress.kubernetes.io/whitelist-source-range` | See [IP allowlist](#ip-allowlist) below |
| `nginx.ingress.kubernetes.io/enable-cors` / `cors-allow-*` | Supported — see [CORS](#cors) below |
| `nginx.ingress.kubernetes.io/ssl-passthrough` | ⚠️ No direct equivalent — flag and ask |
| `nginx.ingress.kubernetes.io/auth-tls-verify-client` / `auth-tls-secret` | ⚠️ No direct equivalent — flag and ask |
| `nginx.ingress.kubernetes.io/auth-tls-pass-certificate-to-upstream` | No action needed — `x-forwarded-client-cert` is forwarded automatically via a global EnvoyFilter |
| `nginx.ingress.kubernetes.io/proxy-body-size` | No action needed — Envoy streams request bodies without buffering |
| `nginx.ingress.kubernetes.io/proxy-buffer-size` / `proxy-buffers-number` | No action needed — Envoy streams, no buffering |
| `nginx.ingress.kubernetes.io/large-client-header-buffers` | No action needed — Envoy default header limit is 60 KB (nginx default is 32 KB) |
| `nginx.ingress.kubernetes.io/server-snippet` (block path) | Supported via AuthorizationPolicy DENY — see [Block paths](#block-paths) below |
| `nginx.ingress.kubernetes.io/configuration-snippet: more_set_headers` | Supported — see [Response headers](#response-headers) below |

Annotations marked **No action needed** are safe to drop. Annotations marked ⚠️ have no direct equivalent — flag them and ask the user whether they can be dropped or need a custom EnvoyFilter.

---

### IP allowlist

```yaml
# Old
nginx.ingress.kubernetes.io/whitelist-source-range: "1.2.3.4/32,10.0.0.0/8"

# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
    authorizationPolicies:
      ip-allowlist:
        action: ALLOW
        rules:
          - from:
              - source:
                  remoteIpBlocks:
                    - "1.2.3.4/32"
                    - "10.0.0.0/8"
```

---

### Path rewrite

Strip a path prefix before forwarding to the backend.

```yaml
# Old
nginx.ingress.kubernetes.io/rewrite-target: "/"
# with path: /api

# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /api
        filters:
          - type: URLRewrite
            urlRewrite:
              path:
                type: ReplacePrefixMatch
                replacePrefixMatch: /
        backendRefs:
          - name: myapp
            port: 8080
```

---

### App-root redirect

Redirect `/` to a specific path, then forward all traffic under that path to the backend.

```yaml
# Old
nginx.ingress.kubernetes.io/app-root: "/app"

# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
    rules:
      - matches:
          - path:
              type: Exact
              value: /
        filters:
          - type: RequestRedirect
            requestRedirect:
              path:
                type: ReplaceFullPath
                replaceFullPath: /app
      - matches:
          - path:
              type: PathPrefix
              value: /app
        backendRefs:
          - name: myapp
            port: 8080
```

> Note: the catch-all backend rule is auto-generated by kitapp — only add an explicit `backendRefs` rule here if you need a non-default port or service name.

---

### CORS

Use a `CORS` filter in `route.rules`. The filter runs on the catch-all rule (or any rule you add) and handles preflight `OPTIONS` requests automatically.

```yaml
# Old
nginx.ingress.kubernetes.io/enable-cors: "true"
nginx.ingress.kubernetes.io/cors-allow-origin: "https://frontend.example.com"
nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, OPTIONS"
nginx.ingress.kubernetes.io/cors-allow-headers: "Authorization, Content-Type"

# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
    rules:
      - filters:
          - type: CORS
            cors:
              allowOrigins:
                - "https://frontend.example.com"
              allowMethods:
                - GET
                - POST
                - OPTIONS
              allowHeaders:
                - Authorization
                - Content-Type
        backendRefs:
          - name: myapp
            port: 8080
```

> Rules in `route.rules` are prepended before the kitapp catch-all. A CORS rule without `matches` (like the example above) will match all requests, so it acts as the effective catch-all — include `backendRefs` so traffic is actually forwarded.

---

### SSL passthrough

No direct equivalent. Flag with ⚠️ and ask the user whether they can move TLS termination to the gateway or need a custom solution.

---

### Client certificate authentication

No direct equivalent for `auth-tls-verify-client` / `auth-tls-secret`. Flag with ⚠️ and ask the user. Note: `auth-tls-pass-certificate-to-upstream` requires no action — `x-forwarded-client-cert` is forwarded automatically.

---

### Block paths

Use an AuthorizationPolicy `DENY` rule. The kitapp chart blocks `/metrics` externally by default (`route.exposeMetrics: false`). For other paths:

```yaml
# Old
nginx.ingress.kubernetes.io/server-snippet: |
  location ~* ^/admin {
    deny all;
  }

# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
    authorizationPolicies:
      block-admin:
        action: DENY
        rules:
          - to:
              - operation:
                  paths:
                    - "/admin"
                    - "/admin/*"
```

---

### Response headers

Use a `ResponseHeaderModifier` filter in `route.rules`.

```yaml
# Old
nginx.ingress.kubernetes.io/configuration-snippet: |
  more_set_headers "X-Frame-Options: DENY";
  more_set_headers "X-Content-Type-Options: nosniff";

# New
kitapp:
  route:
    enabled: true
    hostnames:
      - myapp.example.com
    rules:
      - filters:
          - type: ResponseHeaderModifier
            responseHeaderModifier:
              set:
                - name: X-Frame-Options
                  value: DENY
                - name: X-Content-Type-Options
                  value: nosniff
        backendRefs:
          - name: myapp
            port: 8080
```

> ⚠️ If an annotation is present that does not appear in the table above, or is marked with no equivalent, flag it and ask the user whether it can be dropped or needs a custom EnvoyFilter.

---

## SealedSecrets

```yaml
# Old
sealedSecret:
  my-secret:
    type: Opaque
    encryptedData:
      password: AgB...

# New
templates:
  sealedSecrets:
    my-secret:
      encryptedData:
        password: AgB...
      template:
        type: Opaque    # omit if Opaque — it is the default
```

Encrypted values are cluster-specific — ensure all values are re-sealed for each target cluster before deploying.

---

## NetworkPolicy

Only reached when the app is on the **old multitenant chart** (see preflight question 2). On the new tenant chart, skip this section entirely unless the app communicates with services outside its namespace.

Old format was custom. New format is standard Kubernetes. Drop `allowLetsEncrypt` entirely.

```yaml
# Old
netpol:
  ingress:
    from-nginx:
      namespaceSelector:
        kubernetes.io/metadata.name: ingress-nginx
      ports:
        8080: TCP

# New
templates:
  networkPolicies:
    from-nginx:
      podSelector: {}
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: ingress-nginx
          ports:
            - port: 8080
              protocol: TCP
```

Port format changes from `{port: protocol}` map to `[{port: N, protocol: X}]` list.

> ⚠️ After migrating to Istio, update any `namespaceSelector` values that referenced `ingress-nginx` to the Istio ingress gateway namespace (typically `istio-ingress`). A policy that still allows traffic from `ingress-nginx` will never match and is effectively dead.

---

## CronJobs and Jobs

Migrate to raw Kubernetes manifests under `templates.resources`.

```yaml
# Old
cronjob:
  cleanup:
    image:
      repository: myorg/cleaner
      tag: "1.0.0"
    schedule: "0 2 * * *"
    restartPolicy: Never
    env:
      DB_URL:
        type: secretKeyRef
        name: db-secret
        key: url

# New
templates:
  resources:
    cleanup:
      apiVersion: batch/v1
      kind: CronJob
      metadata:
        name: "{{ .Release.Name }}-cleanup"
      spec:
        schedule: "0 2 * * *"
        jobTemplate:
          spec:
            template:
              spec:
                restartPolicy: Never
                containers:
                  - name: cleanup
                    image: myorg/cleaner:1.0.0
                    env:
                      - name: DB_URL
                        valueFrom:
                          secretKeyRef:
                            name: db-secret
                            key: url
```

Same pattern for `job.*` using `kind: Job`. Apply the same env var conversion rules as above.

---

## PrometheusRules

```yaml
# Old
prometheusRules:
  enabled: true
  release: kube-prometheus-stack
  rules:
    - alert: HighErrorRate
      expr: rate(http_errors_total[5m]) > 0.1

# New
templates:
  resources:
    my-rules:
      apiVersion: monitoring.coreos.com/v1
      kind: PrometheusRule
      metadata:
        name: "{{ .Release.Name }}-rules"
        labels:
          release: kube-prometheus-stack
      spec:
        groups:
          - name: alerts
            rules:
              - alert: HighErrorRate
                expr: rate(http_errors_total[5m]) > 0.1
```

---

## extraDeployments and docDeployment

Each extra deployment becomes its own `kitapp` dependency in `Chart.yaml` with an `alias`. The alias becomes the values scope key.

```yaml
# Chart.yaml
dependencies:
  - name: kitapp
    version: "<latest>"
    repository: https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/
  - name: kitapp
    version: "<latest>"
    repository: https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/
    alias: doc-service        # derived from the extraDeployments key name
```

```yaml
# values.yaml
kitapp:
  image:
    repository: myorg/app
    tag: "1.0.0"

doc-service:                  # alias used as scope
  image:
    repository: myorg/doc-service
    tag: "1.0.0"
```

Apply the same migration rules to the aliased block as to the primary `kitapp` block. Derive the alias directly from the `extraDeployments` or `docDeployment` key name — do not ask the user.

---

## Unsupported features — how to handle

If any of these are present, flag them with ⚠️ at the top of your output and do not attempt to migrate them silently.

| Feature | Action |
|---|---|
| `initContainers.*` | Not supported. Ask what the init container does — suggest baking logic into the app image or using a Helm post-renderer. |
| `sidecar.*` | Not supported. Ask what the sidecar does — requires manual resolution per case. |

---

## Multi-file output format

When the user has overlays, produce output in this order:

1. `Chart.yaml` (shared)
2. `values.yaml` (base — all shared config, `env`, `volumes`)
3. `values-test.yaml` (environment-specific additions only: `extraEnv`, `extraVolumes`, hostnames, sealed secrets)
4. `values-prod.yaml` (same)

**Rules:**
- If a key is identical across all environments → `values.yaml` only
- If a list differs per environment → use the `extra*` variant in overlays, keep the base list in `values.yaml`
- Never repeat a full list in an overlay — it will silently overwrite the base
