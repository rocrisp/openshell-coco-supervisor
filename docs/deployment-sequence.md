# Deployment sequence

![Deployment sequence](deployment-sequence.png)

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
- `io.katacontainers.config.hypervisor.default_memory: "2048"`
- `coco.io/initdata-configmap: "openshell-supervisor-initdata"`
- `resources.requests.memory` and `resources.limits.memory` set to `2560Mi`

Initdata:

- Create `openshell-supervisor-initdata` with:

```bash
./scripts/create-supervisor-initdata.sh
```

- The script reads the Trustee certificate, builds `initdata.toml`, compresses and base64-encodes it, and stores it in the ConfigMap.
- Kyverno reads that ConfigMap and injects `io.katacontainers.config.hypervisor.cc_init_data` into the supervisor Pod.

Memory sizing:

- `default_memory` is the Kata guest VM RAM.
- `resources.requests.memory` and `resources.limits.memory` are enforced by the host cgroup around the Kata/QEMU process.
- For confidential containers, VM memory is pinned at boot and requires host-side headroom.
- Use the Red Hat formula:

```text
default_memory + 512 MiB host overhead
2048 MiB + 512 MiB = 2560 MiB
```

Test:

- supervisor still starts
- gateway can reach it
- sandbox can reach it
- supervisor Pod uses the confidential runtime class

Secret-path requirement:

- credentials should be stored in Trustee,
- released only to the attested confidential supervisor,
- and not delivered in plaintext through the gateway or an unencrypted Kubernetes Secret.

The current PoC does not yet complete the direct Trustee-to-supervisor credential integration. See [security-model.md](security-model.md).

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
