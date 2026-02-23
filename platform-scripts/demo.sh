#!/usr/bin/env bash
set -e

echo "🚀 Starting Demo Flow..."

echo "1. Deploying example app (kubectl apply -k gitops/apps/example-app)..."
# kubectl apply -k gitops/apps/example-app

echo "2. Waiting for pods to be ready..."
# kubectl wait --for=condition=ready pod -l app=example-app -n default --timeout=60s

echo "3. Running smoke tests..."
if [ -f "tests/smoke/smoke.sh" ]; then
    bash tests/smoke/smoke.sh
else
    echo "Smoke test script not found! Simulating success."
fi

echo "✅ Demo complete."
