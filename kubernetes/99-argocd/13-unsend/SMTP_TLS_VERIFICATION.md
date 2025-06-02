# SMTP TLS Certificate Configuration Verification

## ✅ **Configuration Summary**

### 1. **Certificate Generation** (`smtp-certificate.yaml`)
- Uses DNS-01 challenge via `dns01-clusterissuer`
- Generates certificate for `smtp.unsend.6degrees.com.sa`
- Stores certificate in `smtp-tls-secret`

### 2. **SMTP Deployment** (`smtp-deployment.yaml`)
✅ **Certificate Mounting**:
- Volume: `smtp-tls-certs` → Secret: `smtp-tls-secret`
- Mount path: `/certs` (read-only)

✅ **Environment Variables**:
- `UNSEND_API_KEY_PATH`: `/certs/tls.key`
- `UNSEND_API_CERT_PATH`: `/certs/tls.crt`

✅ **Ports Configuration**:
- 25 (SMTP), 587 (Submission), 2587 (Alt Submission)
- 465 (SMTPS), 2465 (Alt SMTPS) ← **SSL/TLS enabled**

### 3. **Service Configuration** (`smtp-service.yaml`)
✅ **ClusterIP service** exposing all SMTP ports

### 4. **External Access**
✅ **TCP Proxy**: `smtp-tcp-proxy.yaml` configures nginx for raw TCP
✅ **Ingress**: `smtp-ingress.yaml` handles HTTPS management interface

## 🔧 **Deployment Steps**

```bash
# 1. Deploy certificate
kubectl apply -f smtp-certificate.yaml

# 2. Wait for certificate (1-2 minutes)
kubectl get certificate smtp-tls-certificate -n six-degrees-apps -w

# 3. Deploy TCP proxy configuration
kubectl apply -f smtp-tcp-proxy.yaml

# 4. Deploy/update SMTP server
kubectl apply -f smtp-deployment.yaml
kubectl apply -f smtp-service.yaml
kubectl apply -f smtp-ingress.yaml
```

## 🔍 **Verification Commands**

### Certificate Status
```bash
# Check certificate
kubectl describe certificate smtp-tls-certificate -n six-degrees-apps

# Check secret
kubectl get secret smtp-tls-secret -n six-degrees-apps
kubectl describe secret smtp-tls-secret -n six-degrees-apps
```

### Deployment Status
```bash
# Check deployment
kubectl get deployment unsend-smtp-server -n six-degrees-apps
kubectl describe deployment unsend-smtp-server -n six-degrees-apps

# Check pods
kubectl get pods -n six-degrees-apps -l app=unsend-smtp-server
kubectl logs -n six-degrees-apps -l app=unsend-smtp-server
```

### Certificate Files in Container
```bash
# Verify certificates are mounted
kubectl exec -n six-degrees-apps deployment/unsend-smtp-server -- ls -la /certs/
kubectl exec -n six-degrees-apps deployment/unsend-smtp-server -- cat /certs/tls.crt | head -3
```

### SMTP Connectivity
```bash
# Test SMTP ports (from external)
telnet smtp.unsend.6degrees.com.sa 587
openssl s_client -connect smtp.unsend.6degrees.com.sa:465 -servername smtp.unsend.6degrees.com.sa
```

## 📋 **Expected Behavior**

1. **Ports 25, 587, 2587**: Plain SMTP (can upgrade to TLS)
2. **Ports 465, 2465**: Immediate SSL/TLS connection
3. **Certificate**: Valid Let's Encrypt certificate for `smtp.unsend.6degrees.com.sa`
4. **Auto-renewal**: cert-manager handles renewal automatically

## ⚠️ **Important Notes**

- **nginx-controller**: Must be configured to use TCP services ConfigMap
- **DNS**: Ensure `smtp.unsend.6degrees.com.sa` points to your ingress IP
- **Firewall**: SMTP ports must be open on your cluster
- **Email clients**: Can connect using SSL/TLS on ports 465/2465 