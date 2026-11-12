# Test suites

Each YAML file in this directory is a declarative test suite.

Run all suites:

```bash
make test
```

Run a single suite:

```bash
python3 scripts/run_tests.py test/01-sandboxed-containers.yml
```

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
