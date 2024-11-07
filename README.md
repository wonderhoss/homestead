# Homestead - a local Kubernetes Development Environment

This repository contains some plumbing to set up a local Kubernetes cluster with [kind](https://kind.sigs.k8s.io/).

It includes:
 * an example multi-node cluster definition
 * an nginx Ingress controller
 * automation to inject local container images into the cluster


## Prerequisites

The two main requirements are `kind` and a container runtime. On Mac, the recommended choice is `podman`.
In addition, `make` and the usual shell utilities should be available.


### Installing podman

Podman can be installed using Homebrew:
```shell
$ brew install podman
```

On MacOS, `podman` uses a virtual machine to host Linux containers. The integration is relatively seamless, but the machine needs to be initialised once and started on each system boot.

```shell
$ podman machine init

$ porman machine start
```

The virtual machine can be stopped when not in use to conserve resources, but it is recommended to first tear down the `kind` cluster.


### Installing kind

The easiest way to install `kind` is to [download the binary](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries).
Place it somewhere within your PATH.


## Getting Started

### 1. Clone the Repository
Since this repository uses git submodules to handle local image sources, please make sure to clone with `--recursive-submodules`.
This will automatically clone the image sources.

### 2. Configure your PATH
Ensure that both `podman` and `kind` are in your PATH.

### 3. Start the Cluster
Running `make` or `make all` will start up the kind cluster, build each container image from source and inject it into the cluster.

Next, it will deploy the default manifests, making sure that the ingress controller's admission webhook is online before attempting further deployments.

Kind also automatically configures a corresponding `kubectl` context, so that `kubectl` commands should "just work(tm)".
The same goes for other tools that rely on Kubernetes contexts, like `k9s`.

### 4. Tranquillity
Once the cluster is ready, the Tranquillity example page should be accessible through the ingress at http://localhost:8080/tranquility/
In addition, two text-only echo endpoints are deployed at http://localhost:8080/foo and [/bar](http://localhost:8080/bar) respectively:

```shell
$ curl localhost:8080/foo
foo-app%
$ curl localhost:8080/bar
bar-app%
```

### 5. Teardown
The cluster and all container image archives can be deleted with `make clean`.
Please note that this currently does not remove the images from the local podman container cache. If desired, this can be done manually with `podman rmi`.


## Sample Cluster Configuration

The cluster, as provided, consists of four nodes:
 * one control plane
 * one worker with exposed ports for the ingress
 * three workers with taint to test tolerations

The ingress node exposes ports 8080 and 8443 to the host machine. This allows a browser or command-line tool to connect to `http://localhost:8080` and reach the ingress controller.
Note: While 8443 is exposed and configured in the ingress controller, no certificates or certificate management is included.
The ingress node is labelled "ingress-ready=true", which allows the included ingress controller Deployment to target it specifically and take advantage of the exposed ports.

Non-privileged ports were chosen to allow compatibility with rootless podman, the default on MacOS.

The other nodes use `kubeadm` patches to add a `NoSchedule` taint. This is meant to allow for the testing of resources that benefit from tolerations.
These can be removed / modified at runtime using `kubectl` or by changing the cluster .yaml and rebuilding the cluster.


## Local Images

The cluster is able to pull images from public registries like docker.io by default.
In order to use local images that do not reside in a registry, e.g. for development and testing, these have to be built locally and then injected into the cluster.

This repository utilises git submodules to allow a convenient mechanism for doing this.

### Adding an image repository
To add a new image repository, simply clone it as submodule into `images/`:

```shell
$ git submodule add <git_repo_url> <repo_name>
$ git submodule update --init --recursive
```

Please note that the Makefile assumes a `Dockerfile` at the root of each submodule.

### Image Tags
The Makefile will attempt to derive a container tag from the git revision (tag or sha) of each submodule.
This means that if the current commit is tagged, e.g. v1.0, then the corresponding container image will be tagged and injected as `localhost/<repo_name>:v1.0`

If the current commit is not tagged, a short-form sha will be used instead. The suffix `-dirty` indicates that the image was built from a repository with local, uncommitted  changes.

