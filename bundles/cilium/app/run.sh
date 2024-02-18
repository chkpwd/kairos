#!/usr/bin/env bash

set -ex

info() {
  echo "INFO: $1"
}

# Don't install cilium if it is already installed
if cilium version &>/dev/null; then
  info "Cilium is already installed, exiting..."
  exit 0
fi

install_cilium_cli() {
  local CILIUM_CLI_VERSION="$(kairos-agent config get "cilium.version" | tr -d '\n')"
  local CLI_ARCH=amd64

  if [ -z "$CILIUM_CLI_VERSION" ]; then
      CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
  fi

  curl -L --fail --remote-name-all "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}"

  sha256sum --check "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum"
  sudo tar xzvf "cilium-linux-${CLI_ARCH}.tar.gz" -C /usr/local/bin

  rm "cilium-linux-${CLI_ARCH}.tar.gz" "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum"
}

# Base Command
cilium_install_cmd="cilium install"

# Check if there are any arguments for Cilium configuration
if [[ -n $(kairos-agent config get cilium.config.args 2>/dev/null) ]]; then
    # Command-line arguments (args)
    mapfile -t args < <(kairos-agent config get "cilium.config.args" 2>/dev/null)

    cilium_args=""

    # Concatenate arguments
    for arg in "${args[@]}"; do
      if [[ $arg != "null" ]]; then
        cilium_args+="$arg "
      fi
    done

    if [[ -n $cilium_args ]]; then
        cilium_install_cmd+=" $cilium_args"
    fi

    url=$(kairos-agent config get "cilium.config.url" 2>/dev/null)
    if [[ -n $url ]]; then
        cilium_install_cmd+=" -f $url"
    fi
fi

eval "$cilium_install_cmd"
