#!/usr/bin/env bash
set -euo pipefail
echo "==> Trustee"
oc get csv -n trustee-operator-system
oc get pods -n trustee-operator-system
oc get trusteeconfig -n trustee-operator-system
oc get kbsconfig -n trustee-operator-system
