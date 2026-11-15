{{- define "craft-studio.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 50 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 50 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "craft-studio.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: craft-studio
{{- end -}}

{{- define "craft-studio.selector" -}}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/name: {{ .name }}
{{- end -}}

{{/* The address people open: publicUrl, else https://<host>. */}}
{{- define "craft-studio.publicUrl" -}}
{{- if .Values.publicUrl -}}
{{- .Values.publicUrl | trimSuffix "/" -}}
{{- else if .Values.host -}}
{{- printf "https://%s" .Values.host -}}
{{- else -}}
{{- fail "set host (e.g. studio.example.com) or publicUrl" -}}
{{- end -}}
{{- end -}}

{{- define "craft-studio.secretName" -}}
{{- .Values.auth.existingSecret | default (include "craft-studio.fullname" .) -}}
{{- end -}}
