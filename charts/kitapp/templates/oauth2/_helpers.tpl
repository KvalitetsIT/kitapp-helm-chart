{{- define "kitapp.oauth2.configMapName" -}}
{{- printf "%s-oauth2" (include "kitapp.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kitapp.oauth2.clientId" -}}
{{- if .Values.oauth2.clientId }}
{{- .Values.oauth2.clientId }}
{{- else if .Values.oauth2.realm }}
{{- include "kitapp.name" . }}
{{- end }}
{{- end -}}

{{- define "kitapp.oauth2.issuerUrl" -}}
{{- printf "%s/realms/%s" .Values.oauth2.issuerUrl .Values.oauth2.realm }}
{{- end -}}

{{- define "kitapp.oauth2.clientDefinition" -}}
{{- $def := .Values.oauth2.clientDefinition | deepCopy -}}
{{- $_ := set $def "clientId" (include "kitapp.oauth2.clientId" .) -}}
{{- if and (not $def.redirectUris) .Values.route.hostnames -}}
  {{- $uris := list -}}
  {{- range .Values.route.hostnames -}}{{- $uris = append $uris (printf "https://%s/*" .) -}}{{- end -}}
  {{- $_ := set $def "redirectUris" $uris -}}
{{- end -}}
{{- if $def.defaultClientScopes }}
{{- $_ := set $def "defaultClientScopes" (without $def.defaultClientScopes "openid") -}}
{{- else }}
{{- $_ := set $def "defaultClientScopes" (without (splitList " " .Values.oauth2.config.scope) "openid") -}}
{{- end -}}
{{- toYaml $def -}}
{{- end -}}

{{- define "kitapp.oauth2.injectorAnnotations" -}}
{{- $annotations := dict
      "oauth2-proxy.kitkube.dk/configmap" (include "kitapp.oauth2.configMapName" .)
      "oauth2-proxy.kitkube.dk/secret" .Values.oauth2.existingSecret
      "oauth2-proxy.kitkube.dk/configKey" "oauth2-proxy.cfg"
  -}}
{{- /* Pin to a known-good version when alpha config is enabled - alpha schema can change between minor releases */ -}}
{{- $defaultImage := ternary "quay.io/oauth2-proxy/oauth2-proxy:v7.15.0" "" .Values.oauth2.useAlphaConfig }}
{{- with .Values.oauth2.image | default $defaultImage }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/image" . -}}
{{- end }}
{{- if .Values.oauth2.useAlphaConfig }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/useAlphaConfig" "true" -}}
{{- end }}
{{- with .Values.oauth2.sidecar.requests.cpu }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/sidecar.requests.cpu" . -}}
{{- end }}
{{- with .Values.oauth2.sidecar.requests.memory }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/sidecar.requests.memory" . -}}
{{- end }}
{{- with .Values.oauth2.sidecar.limits.cpu }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/sidecar.limits.cpu" . -}}
{{- end }}
{{- with .Values.oauth2.sidecar.limits.memory }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/sidecar.limits.memory" . -}}
{{- end }}
{{- with .Values.oauth2.providerCA.configMap }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/provider.ca.configmap" . -}}
{{- end }}
{{- with .Values.oauth2.providerCA.key }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/provider.ca.key" . -}}
{{- end }}
{{- toYaml $annotations -}}
{{- end -}}
