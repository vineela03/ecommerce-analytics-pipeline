#!/bin/bash
set -e

POD_NAME="transform-data-$(date +%s)"

echo "🚀 Running dbt transformations..."
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
    command: ["dbt", "run", "--target", "prod"]
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
echo "Waiting for pod to start..."
sleep 5

kubectl logs $POD_NAME -n ecommerce-pipeline -f

echo ""
echo "✅ Transformations complete!"
echo ""
echo "Cleanup: kubectl delete pod $POD_NAME -n ecommerce-pipeline"