#!/usr/bin/env bash
set -euo pipefail

TRUSTEE_NAMESPACE="${TRUSTEE_NAMESPACE:-trustee-operator-system}"
TRUSTEE_SECRET_NAME="${TRUSTEE_SECRET_NAME:-kbs-https-certificate}"
TRUSTEE_URL="${TRUSTEE_URL:-https://kbs-service.trustee-operator-system.svc.cluster.local:8080}"
TARGET_NAMESPACE="${TARGET_NAMESPACE:-openshell}"
CONFIGMAP_NAME="${CONFIGMAP_NAME:-openshell-supervisor-initdata}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
CERT_FILE="${TMP_DIR}/kbs-cert.pem"
INITDATA_FILE="${TMP_DIR}/initdata.toml"
INITDATA_B64_FILE="${TMP_DIR}/initdata.b64"

if oc get secret "${TRUSTEE_SECRET_NAME}" -n "${TRUSTEE_NAMESPACE}" >/dev/null 2>&1; then
  oc get secret "${TRUSTEE_SECRET_NAME}" -n "${TRUSTEE_NAMESPACE}" \
    -o jsonpath='{.data.tls\.crt}' | base64 -d > "${CERT_FILE}"
else
  oc get configmap kube-root-ca.crt -n "${TRUSTEE_NAMESPACE}" \
    -o jsonpath='{.data.ca\.crt}' > "${CERT_FILE}"
fi

openssl x509 -in "${CERT_FILE}" -noout >/dev/null

cat > "${INITDATA_FILE}" <<INITDATA_EOF
algorithm = "sha256"
version = "0.1.0"

[data]
"aa.toml" = '''
[token_configs]
[token_configs.coco_as]
url = '${TRUSTEE_URL}'
[token_configs.kbs]
url = '${TRUSTEE_URL}'
cert = """
$(cat "${CERT_FILE}")
"""
'''

"cdh.toml" = '''
socket = 'unix:///run/confidential-containers/cdh.sock'
credentials = []

[kbc]
name = 'cc_kbc'
url = '${TRUSTEE_URL}'
kbs_cert = """
$(cat "${CERT_FILE}")
"""
'''
INITDATA_EOF

gzip -c "${INITDATA_FILE}" | base64 | tr -d '\n' > "${INITDATA_B64_FILE}"
INITDATA_B64="$(cat "${INITDATA_B64_FILE}")"

cat <<CONFIGMAP_EOF | oc apply -n "${TARGET_NAMESPACE}" -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CONFIGMAP_NAME}
  namespace: ${TARGET_NAMESPACE}
data:
  INITDATA: "${INITDATA_B64}"
CONFIGMAP_EOF

echo "Created ConfigMap ${CONFIGMAP_NAME} in namespace ${TARGET_NAMESPACE}."
