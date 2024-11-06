TRANQUILITY_VERSION := 2.0
CLUSTER_NAME := homestead

.NOTPARALLEL:

.PHONY: kind-cluster
kind-cluster:
	kind create cluster --config ${CLUSTER_NAME}-cluster.yaml

.PHONY: load-images
load-images:
	podman save -o archive.tar docker.io/library/tranquility:${TRANQUILITY_VERSION} --format docker-archive
	kind load image-archive archive.tar -n ${CLUSTER_NAME}
	rm archive.tar

.PHONY: deploy
deploy:
	kubectl --context kind-${CLUSTER_NAME} apply -f deploy/nginx-ingress.yaml
	until $$(kubectl get endpoints -n ingress-nginx ingress-nginx-controller-admission -o json | jq --exit-status '.subsets' > /dev/null); do \
		echo "  Still waiting for admission controller..."; \
		sleep 1 ;\
	done
	until $$(kubectl get endpoints -n ingress-nginx ingress-nginx-controller-admission -o json | jq --exit-status '.subsets[].addresses' > /dev/null); do \
		echo "  Still waiting for admission controller endpoint..."; \
		sleep 1 ;\
	done
	kubectl --context kind-${CLUSTER_NAME} apply -f deploy/

.PHONY: all
all: kind-cluster load-images deploy

.PHONY: clean
clean:
	kind delete cluster -n ${CLUSTER_NAME}
