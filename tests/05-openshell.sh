#!/usr/bin/env bash
set -euo pipefail
echo "==> OpenShell"
oc get pods -n openshell
oc get deployment openshell-supervisor -n openshell \
  -o jsonpath='{.spec.template.spec.runtimeClassName}{"\n"}'
