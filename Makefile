SHELL := /bin/bash
.DEFAULT_GOAL := help

CHART_DIR ?= chart/openshell-coco-supervisor
RELEASE ?= openshell-coco
NAMESPACE ?= openshell
HELM ?= helm

.PHONY: help deploy template lint test clean
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

deploy: ## Deploy or upgrade the full stack through Helm
	$(HELM) upgrade --install $(RELEASE) $(CHART_DIR) \
	  --namespace $(NAMESPACE) \
	  --create-namespace \
	  --wait

template: ## Render the Helm chart locally
	$(HELM) template $(RELEASE) $(CHART_DIR) \
	  --namespace $(NAMESPACE) \
	  --set openshell.agentSandbox.preflight.enabled=false

lint: ## Lint the Helm chart
	$(HELM) lint $(CHART_DIR)

test: .venv/bin/python ## Run all YAML test suites
	.venv/bin/python scripts/run_tests.py 'test/*.yml'

.venv/bin/python: requirements.txt
	python3 -m venv .venv
	.venv/bin/pip install --quiet --upgrade pip
	.venv/bin/pip install --quiet -r requirements.txt

clean: ## Remove the Helm release only
	$(HELM) uninstall $(RELEASE) --namespace $(NAMESPACE)
