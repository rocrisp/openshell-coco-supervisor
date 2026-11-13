# OpenShell Confidential Container Stack

Deploy the **OpenShell supervisor inside a confidential container** on OpenShift, with attestation-gated secret release through **Red Hat build of Trustee**.

This repository is a PoC deployment and test harness. It is intentionally small and sequential: each phase has a deploy step and a test gate.

## Target versions

| Component | Version / status |
|---|---|
| OpenShift Container Platform | 4.19 or later |
| OpenShift sandboxed containers | **1.13.1** |
| Red Hat build of Agent Sandbox Operator | **Technology Preview**, shipped with OpenShift sandboxed containers 1.13 |
| Red Hat build of Trustee | **1.2.1** |
| OpenShell | **0.1.8** |

## Deployment sequence

See [docs/deployment-sequence.md](docs/deployment-sequence.md) for the ordered deployment and test gates.

## Repository layout

```text
├── README.md
├── Makefile
├── deploy/
│   ├── 00-namespaces.yaml
│   ├── 01-openshift-sandboxed-containers-operator.yaml
│   ├── 02-agent-sandbox-operator.yaml
│   ├── 03-trustee-operator.yaml
│   ├── 04-kataconfig.yaml
│   └── 05-openshell-supervisor-confidential.yaml
├── config/
│   ├── openshell-values.yaml
│   ├── trustee-config.yaml
│   └── kbs-config.yaml
├── scripts/
│   └── run_tests.py
├── test/
│   ├── README.md
│   ├── 00-cluster-readiness.yml
│   ├── 01-sandboxed-containers.yml
│   ├── 02-agent-sandbox.yml
│   ├── 03-trustee.yml
│   ├── 04-openshell.yml
│   ├── 05-supervisor-confidential.yml
│   └── 06-end-to-end.yml
├── requirements.txt
└── docs/
    ├── deployment-sequence.md
    ├── deployment-sequence.png
    └── kata-containers.md
```

## Quick start

```bash
make deploy
make test
```

The Makefile runs each phase in order and stops on the first failure. Tests are declarative YAML files under `test/` and are executed by `scripts/run_tests.py`.

## Kata Containers and confidential containers

- **Kata** = VM-isolated container runtime
- **Confidential containers** = Kata VM + TEE hardware + attestation + Trustee secret release

See [docs/kata-containers.md](docs/kata-containers.md) for the full explanation.

## Security claim

This stack protects the **OpenShell supervisor’s in-use state and credentials** by running it inside a confidential VM and releasing secrets only after successful attestation.

It does **not** by itself protect secrets that remain outside the confidential VM, such as secrets stored in the gateway, Kubernetes, or Vault.

## Important implementation note

The OpenShell Helm chart does not expose a `runtimeClassName` field for the shared supervisor Deployment. To avoid modifying OpenShell, this repo:

1. sets `gatewayConfig.openshell.drivers.kubernetes.supervisor_topology: gateway`, which makes the supervisor a chart-managed Deployment;
2. patches that Deployment with `runtimeClassName: kata-remote` or `kata-cc`.

That is a configuration-only path and requires no OpenShell code changes.
