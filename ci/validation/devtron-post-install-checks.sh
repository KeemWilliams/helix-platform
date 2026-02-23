#!/usr/bin/env bash
set -euo pipefail

# ci/validation/devtron-post-install-checks.sh
# Validates that Devtron was installed correctly (No embedded DBs, successful connections).

NAMESPACE="devtroncd"

echo "=== Devtron Post-Install Validation ==="

# 1. Check for Rouge Embedded Stateful Components
ROGUE_PODS=$(kubectl get pods -n "$NAMESPACE" | grep -E "postgres|redis|nats" || true)
if [ -n "$ROGUE_PODS" ]; type; then
  echo "❌ FAILED: Embedded Postgres, Redis, or NATS pods found running in $NAMESPACE namespace! Devtron did not respect external state values."
  echo "$ROGUE_PODS"
  exit 1
else
  echo "✅ PASS: No embedded DB/Cache/Queue pods are running."
fi

# 2. Check Devtron Operator Health
operator_status=$(kubectl get deployment devtron -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
if [ "$operator_status" == "True" ]; then
  echo "✅ PASS: Devtron deployment is Available and Ready."
else
  echo "❌ FAILED: Devtron deployment is not Available."
  exit 1
fi

# 3. Check OIDC/Ingress Shielding
echo "Verifying Ingress redirects to OIDC provider..."
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" -I https://devtron.example.com || true)

if [ "$HTTP_STATUS" == "302" ]; then
  echo "✅ PASS: Devtron URL returns 302 (Expected redirect to OIDC provider)."
else
  echo "⚠️ WARNING: Devtron URL did not return 302. Current status: $HTTP_STATUS. Ensure SSO and Ingress are configured correctly."
fi

echo "All critical Devtron checks completed."
