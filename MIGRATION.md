# Migration: `service` → `kitapp` + `templates`

## Chart.yaml

Replace the `service` dependency with `kitapp`. Add `templates` only if the old values had `sealedSecret`, `netpol`, `cronjob`, `job`, or `prometheusRules`.

```yaml
dependencies:
  - name: kitapp
    version: "<latest>"
    repository: https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/
  - name: templates
    version: "<latest>"
    repository: https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/
```

All values are scoped under the chart name:

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

| Old | New |
|---|---|
| `replicaCount` | `replicas` |
| `deployment.containerPort` | `applicationPort.port` (only set if not `8080`) |
| `deployment.commands` | `command` |
| `deployment.args` | `args` |
| `deployment.readinessProbe` | `readinessProbe` |
| `deployment.livenessProbe` | `livenessProbe` |
| `deployment.securityContext` | `containerSecurityContext` |
| `service.port` | `servicePort.port` (omit if equal to `applicationPort.port`) |
| `serviceMonitor.enabled` | `metrics.enabled` |
| `serviceMonitor.path` | `metrics.path` |
| `serviceMonitor.targetPort` | `metrics.port` |
| `serviceMonitor.interval` | `metrics.interval` |
| `serviceMonitor.release` | `metrics.labels.release` |
| `serviceAccount.automount` | `serviceAccount.automountServiceAccountToken` |

Drop: `deployment.enabled`, `service.enabled`, `service.targetPort`.

---

## Env vars

The old format was a map with a `type` discriminator. The new format is a standard Kubernetes list.

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

---

## Volumes

Three old mechanisms (`configMapMountPaths`, `extraVolumeMounts`/`extraVolumes`, `pvc.*`) become one unified `volumes[]` list.

```yaml
# Old
deployment:
  configMapMountPaths:
    my-config:
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
    - name: my-config
      mountPath: /etc/app
      subPath: config.yaml
      volumeSpec:
        configMap:
          name: my-config
    - name: tmp
      mountPath: /tmp
      volumeSpec:
        emptyDir: {}
    - name: app-data
      mountPath: /data  # confirm — old pvc.* did not store mountPath
      volumeSpec:
        persistentVolumeClaim:
          create: true
          accessMode: ReadWriteOnce
          size: 5Gi
          storageClass: nfs
```

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

Only set `gateway.name`, `gateway.namespace`, or `clusterIssuer` if they differ from the defaults (`ingressgateway`, `istio-ingress`, `letsencrypt-prod-istio`).

`nginx.ingress.kubernetes.io/*` annotations have no equivalent — drop them.

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
        type: Opaque  # omit if Opaque
```

---

## NetworkPolicy

Old format was custom. New format is standard Kubernetes. Ports change from `{80: TCP}` to `[{port: 80, protocol: TCP}]`. Drop `allowLetsEncrypt`.

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
    my-netpol:
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

---

## CronJobs and Jobs

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

Same pattern for `job.*` using `kind: Job`.

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

## Not supported

- **`initContainers.*`** — not supported and will not be. Bake init logic into the application image, or use a Helm post-renderer.
- **`sidecar.*`** — not supported. Flag immediately for manual resolution.
- **`extraDeployments.*` / `docDeployment.*`** — each needs its own `kitapp` dependency in `Chart.yaml`.
