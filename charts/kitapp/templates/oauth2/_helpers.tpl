{{- define "kitapp.oauth2.configMapName" -}}
{{- printf "%s-oauth2" (include "kitapp.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kitapp.oauth2.effectiveClientId" -}}
{{- if .Values.oauth2.clientId }}
{{- .Values.oauth2.clientId }}
{{- else if .Values.oauth2.realm }}
{{- include "kitapp.name" . }}
{{- end }}
{{- end -}}

{{- define "kitapp.oauth2.effectiveIssuerUrl" -}}
{{- if .Values.oauth2.issuerUrl }}
{{- .Values.oauth2.issuerUrl }}
{{- else if and .Values.oauth2.keycloakUrl .Values.oauth2.realm }}
{{- printf "%s/realms/%s" .Values.oauth2.keycloakUrl .Values.oauth2.realm }}
{{- end }}
{{- end -}}

{{- define "kitapp.oauth2.effectiveSecretRef" -}}
{{- if .Values.oauth2.secretRef }}
{{- .Values.oauth2.secretRef }}
{{- else if .Values.oauth2.realm }}
{{- printf "%s-keycloak-client" (include "kitapp.name" .) }}
{{- end }}
{{- end -}}

{{- define "kitapp.oauth2.injectorAnnotations" -}}
{{- $annotations := dict
      "oauth2-proxy.kitkube.dk/configmap" (include "kitapp.oauth2.configMapName" .)
      "oauth2-proxy.kitkube.dk/secret" (include "kitapp.oauth2.effectiveSecretRef" .)
      "oauth2-proxy.kitkube.dk/configKey" "oauth2-proxy.cfg"
  -}}
{{- with .Values.oauth2.image }}
{{- $_ := set $annotations "oauth2-proxy.kitkube.dk/image" . -}}
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
