{{/*
Resolved backend port for the gateway route.
Priority: route.port → oauth2.proxyPort (when oauth2 enabled) → applicationPort.port.
*/}}
{{- define "kitapp.gateway.resolvedPort" -}}
{{- if not (empty .Values.route.port) -}}
{{- .Values.route.port | int -}}
{{- else if .Values.oauth2.enabled -}}
{{- .Values.oauth2.proxyPort | int -}}
{{- else -}}
{{- .Values.applicationPort.port | int -}}
{{- end -}}
{{- end -}}
