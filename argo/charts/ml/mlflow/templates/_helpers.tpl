{{- define "playground.mlflow.fullname" -}}
{{- if .Values.mlflow.fullnameOverride }}
{{- .Values.mlflow.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
