#!/bin/bash

echo "Checking Service Health"
echo ""

NAMESPACE="ecommerce-pipeline"

# Check Minio health
echo "1. Minio Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MINIO_POD=$(kubectl get pod -n $NAMESPACE -l app=minio -o jsonpath="{.items[0].metadata.name}")

if [ -n "$MINIO_POD" ]; then
    MINIO_STATUS=$(kubectl get pod $MINIO_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    MINIO_READY=$(kubectl get pod $MINIO_POD -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    
    echo "Pod: $MINIO_POD"
    echo "Status: $MINIO_STATUS"
    echo "Ready: $MINIO_READY"
    
    kubectl get pod $MINIO_POD -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | grep -q "True" && echo "✅ Minio is healthy" || echo "❌ Minio is not healthy"
else
    echo "Minio pod not found"
fi

echo ""

# Check PostgreSQL health
echo "2. PostgreSQL Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
POSTGRES_POD=$(kubectl get pod -n $NAMESPACE -l app=postgresql -o jsonpath="{.items[0].metadata.name}")

if [ -n "$POSTGRES_POD" ]; then
    POSTGRES_STATUS=$(kubectl get pod $POSTGRES_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    POSTGRES_READY=$(kubectl get pod $POSTGRES_POD -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    
    echo "Pod: $POSTGRES_POD"
    echo "Status: $POSTGRES_STATUS"
    echo "Ready: $POSTGRES_READY"
    
    kubectl get pod $POSTGRES_POD -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | grep -q "True" && echo "✅ PostgreSQL is healthy" || echo "❌ PostgreSQL is not healthy"
    
    # Database connection test
    echo ""
    kubectl exec -n $NAMESPACE $POSTGRES_POD -- psql -U ecommerceuser -d ecommerce_dw -c "SELECT 1;" > /dev/null 2>&1 && echo "✅ Database connection successful" || echo "❌ Database connection failed"
else
    echo "PostgreSQL pod not found"
fi

echo ""

# Show all pod statuses
echo "3. All Pods Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -n $NAMESPACE -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?\(@.type==\"Ready\"\)].status,RESTARTS:.status.containerStatuses[0].restartCount

echo ""
echo "Health check complete!"