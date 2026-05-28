{{/*
Resolved backend port for the gateway route.
Priority: gateway.port → 4180 (when oauth2 enabled) → applicationPort.port / servicePort.port.
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
