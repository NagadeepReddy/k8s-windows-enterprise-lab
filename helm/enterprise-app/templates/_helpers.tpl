{{/*
Generate the fullname for resources
*/}}
{{- define "enterprise-app.fullname" -}}
{{- if .Chart.Name -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{ .Release.Name }}
{{- end -}}
{{- end }}


{{/*
Common labels
*/}}
{{- define "enterprise-app.labels" -}}
app.kubernetes.io/name: {{ include "enterprise-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: Helm
{{- end }}

{{/*
Selector labels
*/}}
{{- define "enterprise-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "enterprise-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
App name helper
*/}}
{{- define "enterprise-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}
