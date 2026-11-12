#!/usr/bin/env bash
set -euo pipefail
echo "==> End-to-end smoke test"
# Replace with your real OpenShell CLI workflow after the gateway is registered.
openshell status
openshell sandbox list
