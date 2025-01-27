{{- range $app := list "rancher" "argocd" "vault" }}
{{- with index $.Values.global $app }}
{{- if .certificate }}
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ .certificate.name }}
  namespace: {{ .certificate.namespace }}
spec:
  secretName: {{ .certificate.secretName }}
  dnsNames:
    - {{ .certificate.dnsName }}
  issuerRef:
    name: http01-clusterissuer
    kind: ClusterIssuer
    group: cert-manager.io
---
{{- end }}
{{- end }}
{{- end }} 