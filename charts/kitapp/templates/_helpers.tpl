{{- define "kitapp.name" -}}
{{- .Values.nameOverride | default .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kitapp.labels" -}}
app.kubernetes.io/name: {{ include "kitapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end -}}

{{- define "kitapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kitapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "kitapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "kitapp.name" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "kitapp.volumeClaimName" -}}
{{- $defaultClaimName := printf "%s-%s" (include "kitapp.name" .) .volume.name -}}
{{- default $defaultClaimName .volume.volumeSpec.persistentVolumeClaim.claimName -}}
{{- end -}}

{{- define "kitapp.metricsPort" -}}
{{- if not (empty .Values.metrics.port) -}}
{{- .Values.metrics.port | int -}}
{{- else -}}
{{- .Values.applicationPort.port | int -}}
{{- end -}}
{{- end -}}

{{- define "kitapp.hasOwnMetricsPort" -}}
{{- if and (not (empty .Values.metrics.port)) (ne (include "kitapp.metricsPort" .) (toString .Values.applicationPort.port)) -}}
true
{{- end -}}
{{- end -}}

{{- define "kitapp.image" -}}
{{- $repository := .Values.image.repository -}}
{{- $tag := .Values.image.tag -}}
{{- $digest := .Values.image.digest -}}
{{- if and $digest $tag -}}
{{- printf "%s:%s@%s" $repository $tag $digest -}}
{{- else if $digest -}}
{{- printf "%s@%s" $repository $digest -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}

{{- define "kitapp.volumeMount" -}}
- name: {{ .name }}
  mountPath: {{ .mountPath }}
  {{- if .readOnly }}
  readOnly: true
  {{- end }}
  {{- if .subPath }}
  subPath: {{ .subPath }}
  {{- end }}
{{- end -}}

{{- define "kitapp.podVolume" -}}
- name: {{ .volume.name }}
  {{- if .volume.volumeSpec.persistentVolumeClaim }}
  persistentVolumeClaim:
    {{- if .volume.volumeSpec.persistentVolumeClaim.existingClaim }}
    claimName: {{ .volume.volumeSpec.persistentVolumeClaim.existingClaim }}
    {{- else }}
    claimName: {{ include "kitapp.volumeClaimName" .context }}
    {{- end }}
  {{- else }}
  {{- toYaml .volume.volumeSpec | nindent 2 }}
  {{- end }}
{{- end -}}
