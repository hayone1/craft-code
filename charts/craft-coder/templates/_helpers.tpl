{{- define "craft-coder.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 50 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 50 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "craft-coder.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: craft-coder
{{- end -}}

{{- define "craft-coder.selector" -}}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/name: {{ .name }}
{{- end -}}

{{/* The address people open: publicUrl, else https://<host>. */}}
{{- define "craft-coder.publicUrl" -}}
{{- if .Values.publicUrl -}}
{{- .Values.publicUrl | trimSuffix "/" -}}
{{- else if .Values.host -}}
{{- printf "https://%s" .Values.host -}}
{{- else -}}
{{- fail "set host (e.g. coder.example.com) or publicUrl" -}}
{{- end -}}
{{- end -}}

{{- define "craft-coder.secretName" -}}
{{- .Values.existingSecret | default (include "craft-coder.fullname" .) -}}
{{- end -}}

{{/* Coder's address inside the cluster, for the bootstrap job and the workspace agents. */}}
{{- define "craft-coder.internalUrl" -}}
{{- printf "http://%s.%s.svc" (include "craft-coder.fullname" .) .Release.Namespace -}}
{{- end -}}

{{/* The wildcard address for Coder, e.g. *.coder.example.com. */}}
{{- define "craft-coder.wildcardUrl" -}}
{{- if .Values.wildcardHost -}}
{{- $scheme := ternary "http" "https" (hasPrefix "http://" (include "craft-coder.publicUrl" .)) -}}
{{- printf "%s://%s" $scheme .Values.wildcardHost -}}
{{- end -}}
{{- end -}}
