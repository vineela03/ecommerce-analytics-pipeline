#!/bin/bash
set -e

POD_NAME="export-curated-$(date +%s)"

echo "📤 Exporting Analytics Data to Curated Zone"
echo ""

# Create pod for curated export
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  namespace: ecommerce-pipeline
spec:
  restartPolicy: Never
  containers:
  - name: export-curated
    image: data-export:latest
    imagePullPolicy: Never
    command: ["python", "/app/src/export_curated.py"]
    env:
    - name: MINIO_USER
      valueFrom:
        secretKeyRef:
          name: minio-secret
          key: user
    - name: MINIO_PASSWORD
      valueFrom:
        secretKeyRef:
          name: minio-secret
          key: password
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

kubectl logs ${POD_NAME} -n ecommerce-pipeline -f

echo ""
echo "Status:"
kubectl get pod ${POD_NAME} -n ecommerce-pipeline

echo ""
echo "Cleanup: kubectl delete pod ${POD_NAME} -n ecommerce-pipeline"