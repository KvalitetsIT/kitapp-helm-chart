{{- define "kitapp.oauth2.alpha.provider" -}}
id: default
provider: keycloak-oidc
clientID: {{ include "kitapp.oauth2.clientId" . }}
scope: {{ .Values.oauth2.config.scope }}
oidcConfig:
  issuerURL: {{ include "kitapp.oauth2.issuerUrl" . }}
  insecureAllowUnverifiedEmail: {{ .Values.oauth2.config.insecureOidcAllowUnverifiedEmail }}
{{- if not .Values.oauth2.clientDefinition.publicClient }}
clientSecret: "${OAUTH2_PROXY_CLIENT_SECRET}"
{{- end }}
{{- end -}}

{{- define "kitapp.oauth2.alpha.upstream" -}}
id: default
path: /
uri: {{ .Values.oauth2.upstream | default (printf "http://127.0.0.1:%d" (.Values.applicationPort.port | int)) }}
{{- end -}}

{{- define "kitapp.oauth2.alpha.derived" -}}
{{- $provider := include "kitapp.oauth2.alpha.provider" . | fromYaml }}
{{- $upstream := include "kitapp.oauth2.alpha.upstream" . | fromYaml }}
{{- $headers := list }}
{{- if .Values.oauth2.config.passUserHeaders }}
{{- $headers = concat $headers (include "kitapp.oauth2.alpha.headers.user" . | fromYaml).items }}
{{- end }}
{{- if .Values.oauth2.config.passAuthorizationHeader }}
{{- $headers = concat $headers (include "kitapp.oauth2.alpha.headers.authorization" . | fromYaml).items }}
{{- end }}
{{- if .Values.oauth2.config.passAccessToken }}
{{- $headers = concat $headers (include "kitapp.oauth2.alpha.headers.accessToken" . | fromYaml).items }}
{{- end }}
{{- $derived := dict
    "server" (dict "bindAddress" (printf "0.0.0.0:%d" (.Values.oauth2.proxyPort | int)))
    "providers" (list $provider)
    "upstreamConfig" (dict "upstreams" (list $upstream)) }}
{{- if $headers }}
{{- $_ := set $derived "injectRequestHeaders" $headers }}
{{- end }}
{{- $derived | toYaml }}
{{- end -}}

{{- define "kitapp.oauth2.alpha.headers.user" -}}
items:
- name: X-Forwarded-User
  values:
    - claimSource:
        claim: user
- name: X-Forwarded-Email
  values:
    - claimSource:
        claim: email
- name: X-Forwarded-Preferred-Username
  values:
    - claimSource:
        claim: preferred_username
{{- end -}}

{{- define "kitapp.oauth2.alpha.headers.authorization" -}}
items:
- name: Authorization
  values:
    - claimSource:
        claim: id_token
        prefix: "Bearer "
{{- end -}}

{{- define "kitapp.oauth2.alpha.headers.accessToken" -}}
items:
- name: X-Forwarded-Access-Token
  values:
    - claimSource:
        claim: access_token
{{- end -}}
