{{/*
Resolved backend port for the gateway route.
Priority: gateway.port → 4180 (when oauth2 enabled) → applicationPort.port / servicePort.port.
*/}}
{{- define "kitapp.gateway.resolvedPort" -}}
{{- if not (empty .Values.gateway.port) -}}
{{- .Values.gateway.port | int -}}
{{- else if .Values.oauth2.enabled -}}
{{- 4180 -}}
{{- else if not (empty .Values.applicationPort.port) -}}
{{- .Values.applicationPort.port | int -}}
{{- else -}}
{{- .Values.servicePort.port | int -}}
{{- end -}}
{{- end -}}
