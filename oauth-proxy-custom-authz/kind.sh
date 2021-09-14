#!/bin/sh
#
# Helper script to start KinD
#
# Also adds a docker-registry and an ingress to aid local development
#
# See https://kind.sigs.k8s.io/docs/user/quick-start/ 
#
set -o errexit

[ "$TRACE" ] && set -x

VERBOSE=1
[ "$TRACE" ] && VERBOSE=3


KIND_K8S_IMAGE=${KIND_K8S_IMAGE:-"kindest/node:v1.19.11@sha256:07db187ae84b4b7de440a73886f008cf903fcf5764ba8106a9fd5243d6f32729"}
KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-"oauth"}
KIND_DOCKER_REGISTRY_NAME=${KIND_DOCKER_REGISTRY_NAME:-"kind-docker-registry"}
KIND_DOCKER_REGISTRY_PORT=${KIND_DOCKER_REGISTRY_PORT:-5000}
KIND_DOCKER_HOST_ALIAS=${KIND_DOCKER_HOST_ALIAS:-"docker"}
KIND_FIX_KUBECONFIG="${KIND_FIX_KUBECONFIG:-"false"}"
KIND_NGINX_INGRESS_VERSION=${KIND_NGINX_INGRESS_VERSION:-"master"}
KIND_INSTALL_DOCKER_REGISTRY=${KIND_INSTALL_DOCKER_REGISTRY:-"0"}
KIND_WAIT=${KIND_WAIT:-"120s"}
KIND_API_SERVER_ADDRESS=${KIND_API_SERVER_ADDRESS:-"0.0.0.0"}
KIND_API_SERVER_PORT=${KIND_API_SERVER_PORT:-6443}
KIND_INSTALL_DOCKER_REGISTRY=${KIND_INSTALL_DOCKER_REGISTRY:-0}
KIND_INSTALL_NGINX_INGRESS=${KIND_INSTALL_DOCKER_REGISTRY:-0}

docker_registry_start() {
  running="$(docker inspect -f '{{.State.Running}}' "${KIND_DOCKER_REGISTRY_NAME}" 2>/dev/null || true)"

  if [ "${running}" != 'true' ]; then
    docker run \
      -d --restart=always -p "${KIND_DOCKER_REGISTRY_PORT}:5000" --name "${KIND_DOCKER_REGISTRY_NAME}" \
      registry:2
  fi

  docker network connect "${KIND_CLUSTER_NAME}" "${KIND_DOCKER_REGISTRY_NAME}" || true
}

## Create a cluster with the local registry enabled in container
create() {

cat <<EOF | kind create -v ${VERBOSE}  cluster --name="${KIND_CLUSTER_NAME}" --image="${KIND_K8S_IMAGE}" --wait="${KIND_WAIT}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: ${KIND_API_SERVER_ADDRESS}
  apiServerPort: ${KIND_API_SERVER_PORT}

containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${KIND_DOCKER_REGISTRY_PORT}"]
    endpoint = ["http://${KIND_DOCKER_REGISTRY_NAME}:${KIND_DOCKER_REGISTRY_PORT}"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 32080
    hostPort: 80
    protocol: TCP
  - containerPort: 32443
    hostPort: 443
    protocol: TCP
- role: worker
EOF




 if [ "$KIND_FIX_KUBECONFIG" = "true" ]; then
    sed -i -e "s/server: https:\/\/0\.0\.0\.0/server: https:\/\/$KIND_DOCKER_HOST_ALIAS/" "${HOME}/.kube/config"
  fi

  # https://docs.tilt.dev/choosing_clusters.html#discovering-the-registry
  for node in $(kind get nodes --name "${KIND_CLUSTER_NAME}"); do
    kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${KIND_DOCKER_REGISTRY_PORT}";
  done

  if [ "${KIND_INSTALL_DOCKER_REGISTRY}" = '1' ]; then
    docker_registry_start
  fi
}

## Delete the cluster
delete() {
  kind delete cluster --name "${KIND_CLUSTER_NAME}"
}

## Display usage
usage()
{
    echo "usage: $0 [create|delete]"
}

## Argument parsing
if [ "$#" = "0" ]; then
  usage
  exit 1
fi
    
while [ "$1" != "" ]; do
    case $1 in
        create )                create
                                ;;
        delete )                delete
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
