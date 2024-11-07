CLUSTER_NAME := homestead
DEPLOY_WAIT := 2

.NOTPARALLEL:

.PHONY: kind-cluster
kind-cluster:
	kind create cluster --config $(CLUSTER_NAME)-cluster.yaml

.PHONY: load-images
load-images:
	$(MAKE) -C images
	$(foreach archive, $(wildcard images/*.tgz), kind load image-archive $(archive)) -n $(CLUSTER_NAME)

.PHONY: deploy
deploy:
	kubectl --context kind-$(CLUSTER_NAME) apply -f deploy/nginx-ingress.yaml
	until $$(kubectl get endpoints -n ingress-nginx ingress-nginx-controller-admission -o json | jq --exit-status '.subsets' > /dev/null); do \
		echo "  Still waiting for admission controller..."; \
		sleep $(DEPLOY_WAIT) ;\
	done
	until $$(kubectl get endpoints -n ingress-nginx ingress-nginx-controller-admission -o json | jq --exit-status '.subsets[].addresses' > /dev/null); do \
		echo "  Still waiting for admission controller endpoint..."; \
		sleep $(DEPLOY_WAIT) ;\
	done
	kubectl --context kind-$(CLUSTER_NAME) apply -f deploy/

.PHONY: all
all: kind-cluster load-images deploy

.PHONY: clean
clean:
	$(MAKE) -C images clean
	kind delete cluster -n $(CLUSTER_NAME)
