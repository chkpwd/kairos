#!/usr/bin/env bash

# Set the KUBECONFIG environment variable
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Function to display information messages
info() {
  echo "INFO: $1"
}

# Function to display error messages and exit
error() {
  echo "ERROR: $1"
  exit 1
}

# Check if the Kubernetes cluster is operational
if ! systemctl is-active --quiet k3s || ! kubectl cluster-info &>/dev/null; then
  error "Kubernetes cluster is not operational. Please ensure the k3s service is running and the cluster is functional."
fi

# Check if Flux is already bootstrapped
if flux version &>/dev/null; then
  info "Flux is already bootstrapped, exiting..."
  exit 0
fi

# Function to apply Kubernetes manifests using server-side apply
apply_manifests() {
  local directory="$1"
  if [ -d "$directory" ]; then
    info "Applying manifests in $directory with server-side apply"
    kubectl apply -k "$directory" --server-side
  else
    error "Directory $directory does not exist."
  fi
}

# Check if bootstrapping is set to true and apply the manifests
bootstrap_value=$(kairos-agent config get flux.bootstrap | tr -d '\n')
if [ "$bootstrap_value" == "true" ]; then
  # Find and iterate over all directories in /manifests
  for dir in /manifests/*; do
    # Check if the path is a directory
    if [ -d "$dir" ]; then
      apply_manifests "$dir"
    fi
  done
else
  info "Bootstrap is not set to true. Exiting..."
  exit 0
fi
