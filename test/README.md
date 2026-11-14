# Test suites

Each YAML file in this directory is a declarative test suite.

Run all suites:

```bash
make test
```

Run a single suite:

```bash
.venv/bin/python scripts/run_tests.py test/01-sandboxed-containers.yml
```

The `make test` target creates a local `.venv` and installs `PyYAML` automatically.

## Cluster-agnostic checks

The suites use:

- label selectors,
- resource-type discovery,
- generic `oc get` commands.

They do not depend on a specific cluster name, KataConfig name, TrusteeConfig name, KbsConfig name, or OpenShell release name.

## Schema

```yaml
apiVersion: openshell.coco/v1alpha1
kind: TestSuite
metadata:
  name: suite-name
spec:
  description: What this suite validates.
  steps:
    - name: Human-readable step name
      command: shell command to run
      expect:
        exitCode: 0
        outputContains: optional substring
```

The runner executes steps in order and stops the suite on the first failure.
