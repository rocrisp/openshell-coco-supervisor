# OpenShell CoCo Supervisor

Deploy the **OpenShell supervisor inside a confidential container** on OpenShift, with Trustee-based attestation and secret-release configuration.

This repository is now **Helm-first**. The umbrella chart owns the operators, runtime resources, OpenShell release, initdata hook, and supervisor patch.

## Target versions

| Component | Version / status |
|---|---|
| OpenShift Container Platform | 4.19 or later |
| OpenShift sandboxed containers | **1.13.1** |
| Red Hat build of Agent Sandbox Operator | **Technology Preview** |
| Red Hat build of Trustee | **1.2.1** |
| OpenShell | **0.1.8** |

## Quick start

```bash
make deploy
```

Equivalent Helm command:

```bash
helm upgrade --install openshell-coco \
  chart/openshell-coco-supervisor \
  --namespace openshell \
  --create-namespace \
  --wait
```

Run the tests:

```bash
make test
```

On a cluster where Trustee is not installed yet, disable the initdata hook and the supervisor initdata reference for the first install:

```bash
helm upgrade --install openshell-coco \
  chart/openshell-coco-supervisor \
  --namespace openshell \
  --create-namespace \
  --set initdata.enabled=false \
  --set openshell.supervisor.initdataConfigMap="" \
  --wait
```

## Helm-first deployment

The chart in [`chart/openshell-coco-supervisor`](chart/openshell-coco-supervisor) deploys:

- OpenShift sandboxed containers Operator
- Agent Sandbox Operator
- Red Hat build of Trustee
- the confidential Kata runtime
- OpenShell
- the supervisor initdata ConfigMap
- the confidential supervisor Deployment

The chart uses Helm `lookup` during rendering to skip resources that already exist and are owned by another manager. Resources are created only when they are missing or already owned by this release.

The upstream OpenShell chart is vendored under
`chart/openshell-coco-supervisor/charts/helm-chart`, so no separate `helm
dependency update` step is required.

See [`chart/openshell-coco-supervisor/README.md`](chart/openshell-coco-supervisor/README.md) for the chart-specific details.

## Repository layout

```text
├── README.md
├── Makefile
├── chart/
│   └── openshell-coco-supervisor/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── charts/
│       ├── files/
│       └── templates/
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
    ├── architecting-the-zero-trust-ai-sandbox.mp4
    ├── kata-containers.md
    └── security-model.md
```

## Supervisor patch

The repository vendors the upstream OpenShell chart and extends the shared
supervisor Deployment with native Helm values for:

```yaml
runtimeClassName: kata-remote

annotations:
  io.katacontainers.config.hypervisor.default_memory: "2048"
  coco.io/initdata-configmap: "openshell-supervisor-initdata"

resources:
  requests:
    memory: "2560Mi"
  limits:
    memory: "2560Mi"
```

## Memory sizing

For confidential containers:

```text
Kata guest memory
  + host-side Kata/QEMU overhead
  = Kubernetes memory request and limit
```

The chart uses:

```text
2048 MiB guest VM RAM
+ 512 MiB host overhead
= 2560 MiB host cgroup request and limit
```

## Reference video

Watch [Architecting the Zero-Trust AI Sandbox](docs/architecting-the-zero-trust-ai-sandbox.mp4) for the broader product and security context.

## Kata Containers and confidential containers

- **Kata** = VM-isolated container runtime
- **Confidential containers** = Kata VM + TEE hardware + attestation + Trustee secret release

See [docs/kata-containers.md](docs/kata-containers.md) for the full explanation.

## Security claim

This PoC protects the **OpenShell supervisor’s in-use memory and runtime state** by running it inside a confidential Kata VM.

It does **not** automatically make the entire system confidential. If a credential is stored in an unencrypted Kubernetes Secret or passes through a non-confidential gateway, an attacker can steal it upstream without compromising the supervisor’s protected memory.

For end-to-end security, credentials must be stored in Trustee and released directly to the attested confidential supervisor. See [docs/security-model.md](docs/security-model.md).
