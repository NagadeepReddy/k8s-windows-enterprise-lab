{{/*
  Helper to build the full name for this chart.
  Keeping it simple — <release>-<chart>.
*/}}
{{- define "enterprise-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
  Chart name — usually not needed outside labels, but keeping it here.
*/}}
{{- define "enterprise-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
  Basic labels. These are intentionally minimal so it’s easier to read in `kubectl get`.
*/}}
{{- define "enterprise-app.labels" -}}
app.kubernetes.io/name: {{ include "enterprise-app.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
  Labels that must match between Deployment and Service selector.
*/}}
{{- define "enterprise-app.selectorLabels" -}}
app: {{ include "enterprise-app.name" . }}
{{- end }}

{{/*
  Image reference — this keeps image logic in one place.
*/}}
{{- define "enterprise-app.image" -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}

{{/*
  Common pod annotations (optional). Good place for Prometheus scrape, checksum, etc.
*/}}
{{- define "enterprise-app.podAnnotations" -}}
{{- if .Values.podAnnotations }}
{{- toYaml .Values.podAnnotations | nindent 2 }}
{{- end }}
{{- end }}
