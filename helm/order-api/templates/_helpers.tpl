{{- define "order-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "order-api.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" (include "order-api.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "order-api.labels" -}}
app.kubernetes.io/name: {{ include "order-api.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.environment | quote }}
{{- end }}

{{- define "order-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "order-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
