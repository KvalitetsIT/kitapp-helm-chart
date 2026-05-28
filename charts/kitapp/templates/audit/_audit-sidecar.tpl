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
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: APP_LABEL
      value: {{ include "kitapp.fullname" . | quote }}
  args:
    - --config
    - /etc/vector/vector.yaml
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: true
  {{- with (.Values.audit).resources }}
  resources:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  volumeMounts:
    - name: vector-audit-config
      mountPath: /etc/vector
      readOnly: true
{{- end -}}
