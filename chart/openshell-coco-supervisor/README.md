# OpenShell CoCo Supervisor chart

This umbrella chart deploys:

- OpenShift sandboxed containers Operator
- Agent Sandbox Operator
- Red Hat build of Trustee
- the confidential Kata runtime
- OpenShell
- the supervisor-specific initdata ConfigMap
- a directly rendered confidential supervisor Deployment

## Install

```bash
helm upgrade --install openshell-coco \
  chart/openshell-coco-supervisor \
  --namespace openshell
  --create-namespace \
  --wait
```

## Render without installing

```bash
helm template openshell-coco \
  chart/openshell-coco-supervisor \
  --namespace openshell
```

## Idempotency

The parent chart uses Helm `lookup` during rendering to skip resources that
already exist and are owned by another manager. Resources are rendered when
they are missing or already owned by this Helm release.

This avoids creating duplicate subscriptions, operator groups, KataConfigs,
TrusteeConfigs, or KbsConfigs on clusters that already have those components.

## Supervisor patch

The chart vendors the upstream OpenShell chart and extends its supervisor
values with:

- `runtimeClassName`
- Kata guest memory
- host cgroup memory request and limit
- initdata ConfigMap reference

This keeps the supervisor configuration in native Helm values.

## Initdata

The chart runs a pre-install and pre-upgrade hook Job that:

1. reads the Trustee certificate,
2. builds `initdata.toml`,
3. compresses and base64-encodes it,
4. creates the supervisor initdata ConfigMap.

The certificate is read from the cluster at deployment time and is not stored
in this repository.

## Greenfield install note

The initdata hook reads an existing Trustee certificate during Helm rendering.
On a cluster where Trustee is not installed yet, disable the hook for the first
install:

```bash
helm upgrade --install openshell-coco \
  chart/openshell-coco-supervisor \
  --namespace openshell \
  --create-namespace \
  --set initdata.enabled=false \
  --set openshell.supervisor.initdataConfigMap="" \
  --wait
```

After Trustee is available, run the same command with `initdata.enabled=true`
or remove the override.
