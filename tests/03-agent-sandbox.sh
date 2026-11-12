#!/usr/bin/env bash
set -euo pipefail
echo "==> Agent Sandbox"
oc get crd | grep -E 'sandboxes\.agents\.x-k8s\.io|sandboxtemplates|sandboxclaims|sandboxwarmpools'
oc get pods -n agent-sandbox-system
