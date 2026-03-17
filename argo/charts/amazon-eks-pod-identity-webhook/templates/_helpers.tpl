{{- define "amazon-eks-pod-identity-webhook.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "amazon-eks-pod-identity-webhook.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default "pod-identity-webhook" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "amazon-eks-pod-identity-webhook.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "amazon-eks-pod-identity-webhook.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- required "serviceAccount.name must be set when serviceAccount.create is false" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "amazon-eks-pod-identity-webhook.serviceName" -}}
{{- default (include "amazon-eks-pod-identity-webhook.fullname" .) .Values.service.name -}}
{{- end -}}

{{- define "amazon-eks-pod-identity-webhook.certificateName" -}}
{{- default (include "amazon-eks-pod-identity-webhook.fullname" .) .Values.certManager.certificate.name -}}
{{- end -}}

{{- define "amazon-eks-pod-identity-webhook.certificateSecretName" -}}
{{- default (printf "%s-cert" (include "amazon-eks-pod-identity-webhook.fullname" .)) .Values.certManager.certificate.secretName -}}
{{- end -}}

{{- define "amazon-eks-pod-identity-webhook.clusterIssuerName" -}}
{{- default "selfsigned" .Values.certManager.clusterIssuer.name -}}
{{- end -}}

{{- define "amazon-eks-pod-identity-webhook.caInjectFrom" -}}
{{- if .Values.certManager.caInjectionAnnotation -}}
{{- .Values.certManager.caInjectionAnnotation -}}
{{- else -}}
{{- printf "%s/%s" .Release.Namespace (include "amazon-eks-pod-identity-webhook.certificateName" .) -}}
{{- end -}}
{{- end -}}
