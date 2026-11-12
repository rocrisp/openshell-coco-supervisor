#!/usr/bin/env bash
set -euo pipefail
echo "==> Cluster"
oc whoami
oc get clusterversion
oc get nodes
oc get storageclass
