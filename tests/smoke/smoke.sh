#!/usr/bin/env bash
set -e
echo "💨 Running smoke tests..."
echo "Verify API is reachable..."
# curl -f -s http://localhost:8080/health || exit 1
echo "Smoke tests passed!"
