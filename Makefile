CLUSTER_NAME := homestead
DEPLOY_WAIT := 2

.NOTPARALLEL:

.PHONY: all
all: kind-cluster load-images deploy

.PHONY: kind-cluster
kind-cluster:
	kind create cluster --config $(CLUSTER_NAME)-cluster.yaml

.PHONY: build-images
build-images:
	$(MAKE) -C images

.PHONY: load-images
load-images: build-images
	$(foreach archive, $(wildcard images/*.tar), kind load image-archive $(archive) -n $(CLUSTER_NAME))

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


.PHONY: clean
clean:
	$(MAKE) -C images clean
	kind delete cluster -n $(CLUSTER_NAME)
