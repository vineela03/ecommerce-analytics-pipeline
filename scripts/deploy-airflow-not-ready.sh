#!/bin/bash
set -e

echo "🚀 Deploying Apache Airflow"
echo ""

# Step 1: Deploy Airflow
echo "1. Deploying Airflow to Kubernetes..."
kubectl apply -f kubernetes/airflow.yaml

# Step 2: Wait for Airflow to be ready
echo "2. Waiting for Airflow to be ready..."
kubectl wait --for=condition=ready pod -l app=airflow -n ecommerce-pipeline --timeout=300s

# Step 3: Copy DAG
echo "3. Deploying DAG..."
sleep 15  # Wait for volume mount

AIRFLOW_POD=$(kubectl get pod -n ecommerce-pipeline -l app=airflow -o jsonpath="{.items[0].metadata.name}")

# Create DAGs directory in pod
kubectl exec -n ecommerce-pipeline $AIRFLOW_POD -c airflow-webserver -- mkdir -p /opt/airflow/dags

# Copy DAG file
kubectl cp airflow/dags/ecommerce_pipeline_dag.py \
  ecommerce-pipeline/$AIRFLOW_POD:/opt/airflow/dags/ecommerce_pipeline_dag.py \
  -c airflow-webserver

# Step 4: Verify DAG
echo "4. Verifying DAG..."
sleep 10  # Wait for Airflow to detect DAG

kubectl exec -n ecommerce-pipeline $AIRFLOW_POD -c airflow-webserver -- \
  airflow dags list | grep ecommerce_pipeline && echo "✅ DAG loaded successfully" || echo "⚠️  DAG not found yet (may take a minute)"

echo ""
echo "✅ Airflow deployed successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Access Airflow UI:"
echo "  URL: http://localhost:30080"
echo "  Username: admin"
echo "  Password: admin"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Port forward (alternative):"
echo "  kubectl port-forward -n ecommerce-pipeline svc/airflow-service 8080:8080"
echo ""
echo "View Airflow logs:"
echo "  kubectl logs -n ecommerce-pipeline -l app=airflow -c airflow-webserver -f"
echo "  kubectl logs -n ecommerce-pipeline -l app=airflow -c airflow-scheduler -f"
echo ""
echo "Trigger DAG manually:"
echo "  kubectl exec -n ecommerce-pipeline $AIRFLOW_POD -c airflow-webserver -- airflow dags trigger ecommerce_pipeline"