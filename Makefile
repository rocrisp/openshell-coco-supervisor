SHELL := /bin/bash
.DEFAULT_GOAL := help

NAMESPACE ?= openshell
RUNTIME_CLASS ?= kata-remote

.PHONY: help deploy test clean
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

deploy: ## Deploy all components in order
	oc apply -f deploy/00-namespaces.yaml
	oc apply -f deploy/01-openshift-sandboxed-containers-operator.yaml
	oc apply -f deploy/02-agent-sandbox-operator.yaml
	oc apply -f deploy/03-trustee-operator.yaml
	@echo "Waiting for operators to settle..."
	sleep 60
	oc apply -f config/trustee-config.yaml
	oc apply -f config/kbs-config.yaml
	helm upgrade --install openshell oci://ghcr.io/nvidia/openshell/helm-chart \
	  --version 0.1.8 \
	  --namespace $(NAMESPACE) \
	  --create-namespace \
	  --values config/openshell-values.yaml
	oc patch deployment openshell-supervisor \
	  --namespace $(NAMESPACE) \
	  --type merge \
	  --patch-file deploy/05-supervisor-runtimeclass-patch.yaml

test: ## Run all test gates
	bash tests/01-cluster.sh
	bash tests/02-runtimeclass.sh
	bash tests/03-agent-sandbox.sh
	bash tests/04-trustee.sh
	bash tests/05-openshell.sh
	bash tests/06-end-to-end.sh

clean: ## Remove OpenShell release only; operators remain
	helm uninstall openshell --namespace $(NAMESPACE)
