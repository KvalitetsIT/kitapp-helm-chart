{{- define "kitapp.name" -}}
{{- .Values.nameOverride | default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kitapp.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Values.nameOverride | default .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
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
{{- default (include "kitapp.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "kitapp.volumeClaimName" -}}
{{- $defaultClaimName := printf "%s-%s" (include "kitapp.fullname" .) .volume.name -}}
{{- default $defaultClaimName .volume.volumeSpec.persistentVolumeClaim.claimName -}}
{{- end -}}

{{- define "kitapp.metricsPort" -}}
{{- if not (empty .Values.metrics.port) -}}
{{- .Values.metrics.port | int -}}
{{- else -}}
{{- .Values.applicationPort.port | int -}}
{{- end -}}
{{- end -}}

{{- define "kitapp.allVolumes" -}}
{{- toYaml (concat (.Values.volumes | default (list)) (.Values.extraVolumes | default (list))) -}}
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
