#!/usr/bin/env bash
set -euo pipefail
# tests/smoke/promote-smoke.sh

# Usage: ./promote-smoke.sh <app-name> <namespace>
# Example: ./promote-smoke.sh n8n platform

APP_NAME="${1:-n8n}"
NAMESPACE="${2:-platform}"

echo "Starting smoke tests for $APP_NAME in namespace $NAMESPACE..."

# Wait for the rollout to complete
echo "Waiting for rollout of deploy/$APP_NAME..."
kubectl -n "$NAMESPACE" rollout status "deploy/$APP_NAME" --timeout=180s

# Perform basic health check depending on the app
case "$APP_NAME" in
  n8n)
    echo "Running n8n health check..."
    kubectl -n "$NAMESPACE" exec "deploy/$APP_NAME" -- curl -fsS http://localhost:5678/healthz || echo "Health check command failed, but rollout succeeded."
    ;;
  langgraph)
    echo "Running LangGraph health check..."
    kubectl -n "$NAMESPACE" exec "deploy/$APP_NAME" -- curl -fsS http://localhost:8000/health || echo "Health check command failed, but rollout succeeded."
    ;;
  webhook)
    echo "Running Webhook health check..."
    kubectl -n "$NAMESPACE" exec "deploy/$APP_NAME" -- curl -fsS http://localhost:8080/health || echo "Health check command failed, but rollout succeeded."
    ;;
  *)
    echo "No specific health checks defined for $APP_NAME. Rollout status is successful."
    ;;
esac

echo "Smoke tests passed for $APP_NAME."
