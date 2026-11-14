SHELL := /bin/bash
.DEFAULT_GOAL := help

NAMESPACE ?= openshell
RUNTIME_CLASS ?= kata-remote

.PHONY: help deploy initdata test clean
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

deploy: ## Deploy all components in order
	oc apply -f deploy/00-namespaces.yaml
	oc apply -f deploy/01-openshift-sandboxed-containers-operator.yaml
	oc apply -f deploy/02-agent-sandbox-operator.yaml
	oc apply -f deploy/03-trustee-operator.yaml
	@echo "Waiting for operators to settle..."
	sleep 60
	oc apply -f deploy/04-kataconfig.yaml
	@echo "Waiting for confidential Kata runtime..."
	oc wait --for=condition=InProgress=False kataconfig/openshell-coco --timeout=600s
	oc apply -f config/trustee-config.yaml
	oc apply -f config/kbs-config.yaml
	helm upgrade --install openshell oci://ghcr.io/nvidia/openshell/helm-chart \
	  --version 0.1.8 \
	  --namespace $(NAMESPACE) \
	  --create-namespace \
	  --values config/openshell-values.yaml
	$(MAKE) initdata
	oc patch deployment openshell-supervisor \
	  --namespace $(NAMESPACE) \
	  --type merge \
	  --patch-file deploy/05-openshell-supervisor-confidential.yaml

initdata: ## Create the supervisor initdata ConfigMap from Trustee
	./scripts/create-supervisor-initdata.sh

test: ## Run all YAML test suites
	python3 scripts/run_tests.py 'test/*.yml'

clean: ## Remove OpenShell release only; operators remain
	helm uninstall openshell --namespace $(NAMESPACE)
