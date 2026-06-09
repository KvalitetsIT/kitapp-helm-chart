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
{{- $clientId := include "kitapp.oauth2.clientId" . }}
{{- $defaults := dict
    "enabled" true
    "publicClient" false
    "standardFlowEnabled" true
    "directAccessGrantsEnabled" false
    "serviceAccountsEnabled" false
    "webOrigins" (list "+")
    "attributes" (dict "post.logout.redirect.uris" "+")
    "defaultClientScopes" (list "openid" "profile" "email")
-}}
{{- $def := mergeOverwrite (deepCopy $defaults) (.Values.oauth2.definition | default dict) }}
{{- $_ := set $def "clientId" $clientId }}
{{- if not $def.redirectUris }}
{{- $uris := list }}
{{- range .Values.route.hostnames }}
{{- $uris = append $uris (printf "https://%s/*" .) }}
{{- end }}
{{- if $uris }}{{- $_ := set $def "redirectUris" $uris }}{{- end }}
{{- end }}
{{- toYaml $def }}
{{- end -}}

{{- define "kitapp.oauth2.secretData" -}}
{{- $secretName := include "kitapp.oauth2.secretRef" . }}
{{- $existing := (lookup "v1" "Secret" .Release.Namespace $secretName).data | default dict }}
{{- $cookieSecret := index $existing "OAUTH2_PROXY_COOKIE_SECRET" | default "" | b64dec }}
{{- if not $cookieSecret }}{{- $cookieSecret = randAlphaNum 32 }}{{- end }}
OAUTH2_PROXY_COOKIE_SECRET: {{ $cookieSecret | b64enc }}
{{- if not ((.Values.oauth2.definition | default dict).publicClient | default false) }}
{{- $clientSecret := index $existing "OAUTH2_PROXY_CLIENT_SECRET" | default "" | b64dec }}
{{- if not $clientSecret }}{{- $clientSecret = randAlphaNum 32 }}{{- end }}
OAUTH2_PROXY_CLIENT_SECRET: {{ $clientSecret | b64enc }}
{{- end }}
{{- end -}}

{{- define "kitapp.oauth2.secretRef" -}}
{{- if .Values.oauth2.secretRef }}
{{- .Values.oauth2.secretRef }}
{{- else if .Values.oauth2.provisionClient }}
{{- .Values.oauth2.secretName | default (printf "%s-keycloak-client" (include "kitapp.name" .)) }}
{{- end }}
{{- end -}}

{{- define "kitapp.oauth2.injectorAnnotations" -}}
{{- $annotations := dict
      "oauth2-proxy.kitkube.dk/configmap" (include "kitapp.oauth2.configMapName" .)
      "oauth2-proxy.kitkube.dk/secret" (include "kitapp.oauth2.secretRef" .)
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
