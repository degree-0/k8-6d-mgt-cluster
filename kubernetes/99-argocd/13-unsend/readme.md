# Unsend Email Service

Kubernetes deployment for Unsend email service with SMTP proxy server.

## Components

### Main Application
- **Deployment**: `unsend-deployment.yaml` - Main Unsend application
- **Service**: `unsend-service.yaml` - ClusterIP service for web interface
- **Ingress**: `unsend-ingress.yaml` - External access to web interface

### SMTP Server
- **Deployment**: `smtp-deployment.yaml` - SMTP proxy server
- **Service**: `smtp-service.yaml` - SMTP service with multiple ports
- **Ingress**: `smtp-ingress.yaml` - External SMTP access
- **ConfigMap**: `smtp-cm.yaml` - TCP services configuration

### Configuration
- **ConfigMap**: `unsend-cm.yaml` - Environment variables
- **ExternalSecret**: `unsend-es.yaml` - Secrets from Vault

## Environment Variables

### ConfigMap (`unsend-configmap`)
- `REDIS_URL`: Redis connection string
- `NEXTAUTH_URL`: Authentication callback URL
- `SMTP_HOST`: SMTP server hostname
- `SMTP_USER`: SMTP authentication user
- `AWS_DEFAULT_REGION`: AWS region for SES
- `UNSEND_BASE_URL`: Base URL for Unsend instance

### Secrets (`unsend-secret`)
- Database credentials (POSTGRES_*)
- Authentication secrets (NEXTAUTH_SECRET, GITHUB_*)
- AWS credentials (AWS_ACCESS_KEY, AWS_SECRET_KEY)

## SMTP Ports

The SMTP server exposes multiple ports:
- **25**: Standard SMTP
- **587**: SMTP Submission (recommended)
- **2587**: Alternative SMTP Submission
- **465**: SMTPS (SSL/TLS)
- **2465**: Alternative SMTPS

## Access URLs

- **Web Interface**: `https://unsend.6degrees.com.sa`
- **SMTP Server**: `smtp.unsend.6degrees.com.sa`

## Deployment

Apply all files in this directory:
```bash
kubectl apply -f .
```

## Configuration Requirements

1. Ensure Vault contains required secrets under `six-degrees/unsend/secrets`
2. Configure nginx ingress controller with TCP services support
3. Update DNS records for hostnames
4. Verify Redis service is available in cluster
