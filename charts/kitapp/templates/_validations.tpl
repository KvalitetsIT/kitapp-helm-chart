{{- define "kitapp.validate.requiredImage" -}}
  {{- if not .Values.image.repository -}}
    {{- fail "values.image.repository is required" -}}
  {{- end -}}
  {{- if and (not .Values.image.tag) (not .Values.image.digest) -}}
    {{- fail "one of values.image.tag or values.image.digest is required" -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.requiredApplicationPort" -}}
  {{- if not .Values.applicationPort.name -}}
    {{- fail "values.applicationPort.name is required" -}}
  {{- end -}}
  {{- if empty .Values.applicationPort.port -}}
    {{- fail "values.applicationPort.port is required" -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.portNumbers" -}}
  {{- if and (not (empty .Values.applicationPort.port)) (le (.Values.applicationPort.port | int) 0) -}}
    {{- fail "values.applicationPort.port must be greater than 0 when set" -}}
  {{- end -}}
  {{- if and (not (empty .Values.servicePort.port)) (le (.Values.servicePort.port | int) 0) -}}
    {{- fail "values.servicePort.port must be greater than 0 when set" -}}
  {{- end -}}
  {{- if and .Values.metrics.enabled (not (empty .Values.metrics.port)) (le (.Values.metrics.port | int) 0) -}}
    {{- fail "values.metrics.port must be greater than 0 when set" -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.portNames" -}}
  {{- $appPortNames := dict -}}
  {{- $_ := set $appPortNames .Values.applicationPort.name true -}}
  {{- range .Values.additionalApplicationPorts }}
    {{- if not .name -}}
      {{- fail "each entry in values.additionalApplicationPorts requires a name" -}}
    {{- end -}}
    {{- if le (.port | int) 0 -}}
      {{- fail "each entry in values.additionalApplicationPorts requires port > 0" -}}
    {{- end -}}
    {{- if hasKey $appPortNames .name -}}
      {{- fail (printf "duplicate port name detected: %s" .name) -}}
    {{- end -}}
    {{- $_ := set $appPortNames .name true -}}
  {{- end -}}

  {{- $servicePortNames := dict -}}
  {{- range $n, $_ := $appPortNames }}
    {{- $_ = set $servicePortNames $n true -}}
  {{- end -}}
  {{- if and (not (empty .Values.servicePort.name)) (hasKey $servicePortNames .Values.servicePort.name) -}}
    {{- fail (printf "primary service port name '%s' conflicts with existing port names" .Values.servicePort.name) -}}
  {{- end -}}
  {{- if not (empty .Values.servicePort.name) -}}
    {{- $_ = set $servicePortNames .Values.servicePort.name true -}}
  {{- end -}}
  {{- range .Values.additionalServicePorts }}
    {{- if not .name -}}
      {{- fail "each entry in values.additionalServicePorts requires a name" -}}
    {{- end -}}
    {{- if le (.port | int) 0 -}}
      {{- fail "each entry in values.additionalServicePorts requires port > 0" -}}
    {{- end -}}
    {{- if hasKey $servicePortNames .name -}}
      {{- fail (printf "duplicate service port name detected: %s" .name) -}}
    {{- end -}}
    {{- $_ := set $servicePortNames .name true -}}
  {{- end -}}
  {{- if and .Values.metrics.enabled (hasKey $servicePortNames "metrics") -}}
    {{- fail "metrics port name 'metrics' conflicts with existing service port names" -}}
  {{- end -}}
  {{- if and .Values.oauth2.enabled (hasKey $servicePortNames "oauth2-proxy") -}}
    {{- fail "reserved oauth2 service port name 'oauth2-proxy' conflicts with service port names" -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.gateway" -}}
  {{- if .Values.route.enabled -}}
    {{- if not (has .Values.route.type (list "HTTPRoute" "TLSRoute")) -}}
      {{- fail "values.route.type must be HTTPRoute or TLSRoute" -}}
    {{- end -}}
    {{- if and (eq .Values.route.type "TLSRoute") .Values.oauth2.enabled -}}
      {{- fail "oauth2 cannot be used with route.type=TLSRoute (TLS passthrough - gateway cannot inspect HTTP)" -}}
    {{- end -}}
    {{- if empty .Values.route.hostnames -}}
      {{- fail "values.route.hostnames is required when route.enabled=true" -}}
    {{- end -}}
    {{- if not .Values.route.gateway.name -}}
      {{- fail "values.route.gateway.name is required when route.enabled=true" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.autoscaling" -}}
  {{- if .Values.autoscaling.enabled -}}
    {{- $minReplicas := .Values.autoscaling.minReplicas | int -}}
    {{- $maxReplicas := .Values.autoscaling.maxReplicas | int -}}
    {{- if le $minReplicas 0 -}}
      {{- fail "values.autoscaling.minReplicas must be greater than 0 when autoscaling.enabled=true" -}}
    {{- end -}}
    {{- if lt $maxReplicas $minReplicas -}}
      {{- fail "values.autoscaling.maxReplicas must be greater than or equal to values.autoscaling.minReplicas when autoscaling.enabled=true" -}}
    {{- end -}}
    {{- if and (empty .Values.autoscaling.targetCPUUtilizationPercentage) (empty .Values.autoscaling.targetMemoryUtilizationPercentage) -}}
      {{- fail "set at least one of values.autoscaling.targetCPUUtilizationPercentage or values.autoscaling.targetMemoryUtilizationPercentage when autoscaling.enabled=true" -}}
    {{- end -}}
    {{- if and (not (empty .Values.autoscaling.targetCPUUtilizationPercentage)) (le (.Values.autoscaling.targetCPUUtilizationPercentage | int) 0) -}}
      {{- fail "values.autoscaling.targetCPUUtilizationPercentage must be greater than 0 when set" -}}
    {{- end -}}
    {{- if and (not (empty .Values.autoscaling.targetMemoryUtilizationPercentage)) (le (.Values.autoscaling.targetMemoryUtilizationPercentage | int) 0) -}}
      {{- fail "values.autoscaling.targetMemoryUtilizationPercentage must be greater than 0 when set" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.oauth2" -}}
  {{- if and .Values.oauth2.enabled (not .Values.oauth2.realm) -}}
    {{- fail "values.oauth2.realm is required when oauth2.enabled=true" -}}
  {{- end -}}
  {{- if and .Values.oauth2.enabled (not .Values.oauth2.issuerUrl) -}}
    {{- fail "values.oauth2.issuerUrl is required when oauth2.enabled=true" -}}
  {{- end -}}
  {{- if and .Values.oauth2.enabled (not .Values.oauth2.provisionClient) (not .Values.oauth2.existingSecret) -}}
    {{- fail "values.oauth2.existingSecret is required when oauth2.provisionClient=false" -}}
  {{- end -}}
  {{- if and .Values.oauth2.enabled .Values.oauth2.provisionClient (not (.Capabilities.APIVersions.Has "keycloak.hostzero.com/v1beta1")) -}}
    {{- fail "oauth2.provisionClient=true requires the KeycloakClient CRD (keycloak.hostzero.com/v1beta1) - install the Hostzero Keycloak operator or set provisionClient=false" -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.envNames" -}}
  {{- $envNames := dict -}}
  {{- range .Values.env }}
    {{- if not .name -}}
      {{- fail "each entry in values.env requires a name" -}}
    {{- end -}}
    {{- if hasKey $envNames .name -}}
      {{- fail (printf "duplicate env name detected: %s" .name) -}}
    {{- end -}}
    {{- $_ := set $envNames .name true -}}
  {{- end -}}
  {{- range .Values.extraEnvs }}
    {{- if not .name -}}
      {{- fail "each entry in values.extraEnvs requires a name" -}}
    {{- end -}}
    {{- if hasKey $envNames .name -}}
      {{- fail (printf "duplicate env name detected across env/extraEnvs: %s" .name) -}}
    {{- end -}}
    {{- $_ := set $envNames .name true -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.volumes" -}}
  {{- $allVolumes := concat (.Values.volumes | default (list)) (.Values.extraVolumes | default (list)) -}}
  {{- $volumeNames := dict -}}
  {{- range $idx, $volume := $allVolumes }}
    {{- if not $volume.name -}}
      {{- fail (printf "merged volumes[%d].name is required (volumes + extraVolumes)" $idx) -}}
    {{- end -}}
    {{- if hasKey $volumeNames $volume.name -}}
      {{- fail (printf "duplicate volume name detected across volumes/extraVolumes: %s" $volume.name) -}}
    {{- end -}}
    {{- $_ := set $volumeNames $volume.name true -}}
    {{- if not $volume.mountPath -}}
      {{- fail (printf "merged volumes[%d].mountPath is required (volumes + extraVolumes)" $idx) -}}
    {{- end -}}
    {{- if not $volume.volumeSpec -}}
      {{- fail (printf "merged volumes[%d].volumeSpec is required (volumes + extraVolumes)" $idx) -}}
    {{- end -}}
    {{- if $volume.volumeSpec.persistentVolumeClaim -}}
      {{- $pvc := $volume.volumeSpec.persistentVolumeClaim -}}
      {{- if and (not $pvc.existingClaim) (ne (default true $pvc.create) false) (not $pvc.size) -}}
        {{- fail (printf "merged volumes[%d].volumeSpec.persistentVolumeClaim.size is required when creating a PVC (volumes + extraVolumes)" $idx) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.oauth2RawConfig" -}}
  {{- if and .Values.oauth2.enabled .Values.oauth2.rawConfig -}}
    {{- if hasKey .Values.oauth2.rawConfig "cookie_secret" -}}
      {{- fail "oauth2.rawConfig must not contain 'cookie_secret' - use oauth2.existingSecret or provisionClient to manage credentials" -}}
    {{- end -}}
    {{- if hasKey .Values.oauth2.rawConfig "client_secret" -}}
      {{- fail "oauth2.rawConfig must not contain 'client_secret' - use oauth2.existingSecret or provisionClient to manage credentials" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "kitapp.validate.envFromRefs" -}}
{{- $allEnvFrom := concat (.Values.envFrom | default (list)) (.Values.extraEnvFrom | default (list)) -}}
{{- $seen := dict -}}
{{- range $idx, $entry := $allEnvFrom }}
  {{- /* Allow only one ref type per envFrom entry and require a name. */ -}}
  {{- $hasConfigMapRef := not (empty $entry.configMapRef) -}}
  {{- $hasSecretRef := not (empty $entry.secretRef) -}}
  {{- if and $hasConfigMapRef $hasSecretRef -}}
    {{- fail (printf "merged envFrom[%d] must not contain both configMapRef and secretRef (envFrom + extraEnvFrom)" $idx) -}}
  {{- end -}}
  {{- if and (not $hasConfigMapRef) (not $hasSecretRef) -}}
    {{- fail (printf "merged envFrom[%d] must contain either configMapRef or secretRef (envFrom + extraEnvFrom)" $idx) -}}
  {{- end -}}

  {{- /* Build canonical key for duplicate detection across merged lists. */ -}}
  {{- $kind := "configMapRef" -}}
  {{- $name := "" -}}
  {{- if $hasConfigMapRef -}}
    {{- $name = $entry.configMapRef.name -}}
  {{- else -}}
    {{- $kind = "secretRef" -}}
    {{- $name = $entry.secretRef.name -}}
  {{- end -}}
  {{- if empty $name -}}
    {{- fail (printf "merged envFrom[%d].%s.name is required (envFrom + extraEnvFrom)" $idx $kind) -}}
  {{- end -}}

  {{- $key := printf "%s:%s" $kind $name -}}
  {{- if hasKey $seen $key -}}
    {{- fail (printf "duplicate envFrom reference detected across envFrom/extraEnvFrom: %s" $key) -}}
  {{- end -}}
  {{- $_ := set $seen $key true -}}
{{- end -}}
{{- end -}}
