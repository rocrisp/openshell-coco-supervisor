#!/usr/bin/env bash
set -euo pipefail
echo "==> OpenShift sandboxed containers"
oc get csv -n openshift-sandboxed-containers-operator
oc get runtimeclass | grep -E 'kata(-remote|-cc)?'
