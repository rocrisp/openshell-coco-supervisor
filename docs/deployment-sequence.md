# Deployment sequence

## Phase 0 — Cluster readiness

Deploy nothing yet.

Verify:

- OpenShift 4.19 or later
- cluster-admin or equivalent RBAC
- a CNI that enforces ingress and egress NetworkPolicy
- a default or named StorageClass
- confidential VM SKU or peer-pod support
- Azure quota, region, and identity configuration if using ARO

Test:

```bash
oc get clusterversion
oc get nodes
oc get storageclass
```

## Phase 1 — OpenShift sandboxed containers 1.13.1

Install:

- **OpenShift sandboxed containers Operator 1.13.1**

Test:

- a RuntimeClass such as `kata-remote` or `kata-cc` exists
- a simple Pod starts under that RuntimeClass

## Phase 1a — KataConfig

Create:

- `osc-feature-gates` ConfigMap with `confidential: "true"`
- `KataConfig` named `openshell-coco`
- `enablePeerPods: true`

This asks the OpenShift sandboxed containers Operator to enable confidential peer pods and create the `kata-remote` RuntimeClass.

Test:

```bash
oc apply -f deploy/04-kataconfig.yaml
oc wait --for=condition=InProgress=False kataconfig/openshell-coco --timeout=600s
oc get runtimeclass kata-remote
```

## Phase 2 — Agent Sandbox

Install:

- **Red Hat build of Agent Sandbox Operator** (Technology Preview)

Test:

- `Sandbox`, `SandboxTemplate`, `SandboxClaim`, and `SandboxWarmPool` CRDs exist
- the controller is running in `agent-sandbox-system`

## Phase 3 — Trustee 1.2.1

Install:

- **Red Hat build of Trustee Operator 1.2.1**

Configure:

- `TrusteeConfig`
- `KbsConfig`
- TLS and attestation policy

Test:

- Trustee reconciles successfully
- an attested workload can retrieve a secret
- an unattested workload cannot

## Phase 4 — OpenShell 0.1.8

Install:

- **OpenShell Helm chart 0.1.8**

Configure:

- `gatewayConfig.openshell.drivers.kubernetes.supervisor_topology: gateway`
- `server.defaultRuntimeClassName: kata-remote` or `kata-cc`
- OpenShift SCC-compatible UID/GID values

Test:

- gateway, supervisor, and sandbox Pods are healthy
- OpenShell CLI can reach the gateway
- a sandbox can be created

## Phase 5 — Confidential supervisor

Patch:

- `openshell-supervisor` Deployment
- `spec.template.spec.runtimeClassName: kata-remote` or `kata-cc`

Test:

- supervisor still starts
- gateway can reach it
- sandbox can reach it
- Trustee releases credentials only after attestation

## Phase 6 — End-to-end

Run:

1. create an OpenShell sandbox
2. run an agent command
3. request an approved external endpoint
4. verify policy blocks unauthorized network and filesystem access
5. verify credentials are not visible to the agent

## Parallelism

After the baseline works, these can proceed in parallel:

- Trustee setup
- Agent Sandbox setup
- OpenShell chart preparation
- Azure/ARO peer-pod resource preparation

These remain hard dependencies:

- Kata runtime must exist before confidential workloads
- Agent Sandbox CRDs must exist before OpenShell
- OpenShell must work normally before moving the supervisor into CoCo
- Trustee must be configured before testing attestation-gated secrets
