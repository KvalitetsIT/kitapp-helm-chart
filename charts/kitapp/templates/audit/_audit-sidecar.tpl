{{- define "kitapp.audit.sidecar" -}}
- name: vector-audit
  restartPolicy: Always
  image: "{{ .Values.audit.image.repository }}:{{ .Values.audit.image.tag }}"
  imagePullPolicy: {{ .Values.audit.image.pullPolicy }}
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: APP_LABEL
      value: {{ include "kitapp.fullname" . | quote }}
  args:
    - --watch-config
    - --config
    - /etc/vector/vector.yaml
  {{- with (.Values.audit).securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with (.Values.audit).resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    - name: vector-audit-rules
      mountPath: /etc/vector
      readOnly: true
{{- end -}}
