#!/bin/bash
set -e

COMMAND=${1:-run}
POD_NAME="dbt-$(date +%s)"

echo "🚀 Running: dbt $COMMAND"
echo ""

# Create pod with env vars from secrets
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: ecommerce-pipeline
spec:
  restartPolicy: Never
  containers:
  - name: dbt
    image: dbt:latest
    imagePullPolicy: Never
    command: ["sh", "-c", "dbt $COMMAND --target prod"]
    env:
    - name: POSTGRES_USER
      valueFrom:
        secretKeyRef:
          name: postgres-secret
          key: user
    - name: POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: postgres-secret
          key: password
    - name: POSTGRES_DB
      valueFrom:
        secretKeyRef:
          name: postgres-secret
          key: database
EOF

# Wait and show logs
sleep 5
kubectl logs $POD_NAME -n ecommerce-pipeline -f

echo ""
echo "Status:"
kubectl get pod $POD_NAME -n ecommerce-pipeline