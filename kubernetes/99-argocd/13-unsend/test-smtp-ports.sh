#!/bin/bash

# SMTP Port Testing Script
# Tests all SMTP ports for connectivity

SMTP_HOST="172.105.146.116"  # Your LoadBalancer IP
DOMAIN="smtp.unsend.6degrees.com.sa"

echo "🔍 Testing SMTP Ports for $DOMAIN ($SMTP_HOST)"
echo "================================================"

# Test function
test_port() {
    local port=$1
    local desc=$2
    local ssl=$3
    
    echo -n "Testing port $port ($desc): "
    
    if [ "$ssl" = "ssl" ]; then
        # Test SSL ports with openssl
        timeout 5 openssl s_client -connect $SMTP_HOST:$port -servername $DOMAIN -quiet -verify_return_error 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ SSL Connection successful"
        else
            echo "❌ SSL Connection failed"
        fi
    else
        # Test plain ports with telnet
        timeout 5 bash -c "exec 3<>/dev/tcp/$SMTP_HOST/$port && echo 'QUIT' >&3 && cat <&3" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Connection successful"
        else
            echo "❌ Connection failed"
        fi
    fi
}

# Test all SMTP ports
echo "🔧 Standard SMTP Ports:"
test_port 25 "SMTP" "plain"
test_port 587 "SMTP Submission" "plain"
test_port 2587 "Alternative SMTP Submission" "plain"

echo ""
echo "🔒 SSL/TLS SMTP Ports:"
test_port 465 "SMTPS" "ssl"
test_port 2465 "Alternative SMTPS" "ssl"

echo ""
echo "📋 Service Status:"
echo "================================================"

# Check Kubernetes services
echo "SMTP Service:"
kubectl get service unsend-smtp-server -n six-degrees-apps

echo ""
echo "Nginx Controller Service Ports:"
kubectl get service ingress-ingress-nginx-controller -n default -o jsonpath='{.spec.ports[*].port}' | tr ' ' '\n' | sort -n

echo ""
echo "📊 Pod Status:"
echo "================================================"
kubectl get pods -n six-degrees-apps -l app=unsend-smtp-server
kubectl get pods -n default | grep ingress-nginx-controller

echo ""
echo "🔍 TCP ConfigMap:"
kubectl get configmap nginx-tcp-services -n default -o yaml | grep -A 10 data 