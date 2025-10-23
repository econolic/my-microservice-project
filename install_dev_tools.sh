#!/usr/bin/env bash
# install_dev_tools.sh
# Purpose: Install Docker, Docker Compose, Python (>=3.9) and Django (via pip) on Ubuntu/Debian (incl. WSL)
# Usage:
#   ./install_dev_tools.sh           # real install (may ask for sudo)
#   ./install_dev_tools.sh --check   # dry-run: show what would be done

set -euo pipefail

CHECK_MODE=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_MODE=true
fi

log() { echo -e "\e[34m[INFO]\e[0m $*"; }
ok()  { echo -e "\e[32m[OK]\e[0m   $*"; }
warn(){ echo -e "\e[33m[WARN]\e[0m $*"; }
err() { echo -e "\e[31m[ERR]\e[0m  $*"; }

die() { err "$*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run() {
  if $CHECK_MODE; then
    echo "+ $*"
  else
    "$@"
  fi
}

need_sudo() {
  if [[ $(id -u) -ne 0 ]]; then
    echo "sudo"
  else
    echo ""
  fi
}

ensure_apt() {
  require_cmd apt-get || die "This script supports only Debian/Ubuntu systems with apt-get."
}

compare_versions() {
  # returns 0 if $1 >= $2 using dpkg --compare-versions
  if dpkg --compare-versions "$1" ge "$2"; then return 0; else return 1; fi
}

is_wsl() {
  grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null || return 1
}

setup_apt_https() {
  local SUDO=($(need_sudo))
  run "${SUDO[@]}" apt-get update -y
  run "${SUDO[@]}" apt-get install -y ca-certificates curl gnupg lsb-release software-properties-common
}

install_docker() {
  if require_cmd docker; then
    ok "Docker already installed: $(docker --version | head -n1)"
    return 0
  fi

  log "Installing Docker Engine from Docker's official repository"
  setup_apt_https
  local SUDO=($(need_sudo))

  # Detect OS distribution from /etc/os-release
  local OS_ID
  OS_ID=$(. /etc/os-release && echo "$ID")
  local CODENAME
  CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
  
  # Determine Docker repo base URL based on distribution
  local DOCKER_REPO_BASE
  case "$OS_ID" in
    ubuntu)
      DOCKER_REPO_BASE="https://download.docker.com/linux/ubuntu"
      ;;
    debian)
      DOCKER_REPO_BASE="https://download.docker.com/linux/debian"
      ;;
    *)
      warn "Unsupported distribution: $OS_ID. Attempting to use Ubuntu repository."
      DOCKER_REPO_BASE="https://download.docker.com/linux/ubuntu"
      ;;
  esac

  run "${SUDO[@]}" install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    if $CHECK_MODE; then
      echo "+ curl -fsSL ${DOCKER_REPO_BASE}/gpg | ${SUDO[*]} gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
    else
      curl -fsSL "${DOCKER_REPO_BASE}/gpg" | "${SUDO[@]}" gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    fi
    run "${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  local ARCH
  ARCH=$(dpkg --print-architecture)

  local SOURCE_LINE="deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] ${DOCKER_REPO_BASE} ${CODENAME} stable"
  if [[ ! -f /etc/apt/sources.list.d/docker.list ]] || ! grep -q "download.docker.com" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
    if $CHECK_MODE; then
      echo "+ echo '${SOURCE_LINE}' | ${SUDO[*]} tee /etc/apt/sources.list.d/docker.list > /dev/null"
    else
      echo "${SOURCE_LINE}" | "${SUDO[@]}" tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi
  fi

  run "${SUDO[@]}" apt-get update -y
  run "${SUDO[@]}" apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  ok "Docker installed"

  # Post-install: allow non-root usage
  if getent group docker >/dev/null 2>&1; then
    if id -nG "$USER" | grep -qw docker; then
      ok "User '$USER' already in 'docker' group"
    else
      log "Adding user '$USER' to 'docker' group (you may need to log out/in)"
      run "${SUDO[@]}" usermod -aG docker "$USER"
    fi
  else
    log "Creating 'docker' group and adding user"
    if $CHECK_MODE; then
      echo "+ ${SUDO[*]} groupadd docker || true"
    else
      "${SUDO[@]}" groupadd docker || true
    fi
    run "${SUDO[@]}" usermod -aG docker "$USER"
  fi

  if is_wsl; then
    warn "Detected WSL. You may need Docker Desktop or to enable systemd for dockerd to run as a service."
  fi
}

install_docker_compose() {
  # Prefer the docker compose v2 plugin
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose (v2 plugin) already available: $(docker compose version | head -n1)"
    return 0
  fi

  # Check legacy docker-compose
  if require_cmd docker-compose; then
    ok "Docker Compose (legacy) already installed: $(docker-compose --version)"
    return 0
  fi

  log "Ensuring Docker Compose via docker-compose-plugin"
  local SUDO=($(need_sudo))
  run "${SUDO[@]}" apt-get install -y docker-compose-plugin

  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose v2 plugin installed"
    return 0
  fi

  warn "Falling back to legacy docker-compose installation"
  local LATEST="1.29.2"
  local DEST="/usr/local/bin/docker-compose"
  local COMPOSE_URL="https://github.com/docker/compose/releases/download/${LATEST}/docker-compose-$(uname -s)-$(uname -m)"
  run "${SUDO[@]}" curl -L "${COMPOSE_URL}" -o "${DEST}"
  run "${SUDO[@]}" chmod +x "${DEST}"
  ok "Legacy docker-compose installed at ${DEST}"
}

select_python_cmd() {
  # Decide which python to use to satisfy >=3.9 requirement
  local PY=python3
  if require_cmd python3; then
    local VER
    VER=$(python3 -c 'import sys; print("%d.%d"%sys.version_info[:2])')
    if compare_versions "$VER" "3.9"; then
      echo python3; return 0
    fi
  fi

  # Try python3.10 or newer if available
  for CAND in python3.12 python3.11 python3.10; do
    if require_cmd "$CAND"; then echo "$CAND"; return 0; fi
  done
  echo python3
}

install_python_and_pip() {
  local SUDO=($(need_sudo))
  setup_apt_https

  # Install base python3 and pip if missing
  if ! require_cmd python3; then
    log "Installing python3"
    run "${SUDO[@]}" apt-get install -y python3
  else
    ok "python3 present: $(python3 --version)"
  fi

  if ! require_cmd pip3; then
    log "Installing python3-pip"
    run "${SUDO[@]}" apt-get install -y python3-pip
  else
    ok "pip3 present: $(pip3 --version | head -n1)"
  fi

  # Ensure python >= 3.9, else try deadsnakes
  local CURVER="0.0"
  if require_cmd python3; then
    CURVER=$(python3 -c 'import sys; print("%d.%d"%sys.version_info[:2])') || true
  fi

  if ! compare_versions "$CURVER" "3.9"; then
    warn "python3 is $CURVER (<3.9). Installing a newer Python (3.10) via deadsnakes PPA."
    run "${SUDO[@]}" add-apt-repository -y ppa:deadsnakes/ppa
    run "${SUDO[@]}" apt-get update -y
    run "${SUDO[@]}" apt-get install -y python3.10 python3.10-venv python3.10-distutils
    ok "Installed python3.10"
  fi
}

install_django() {
  local PY
  PY=$(select_python_cmd)

  # Ensure pip for selected interpreter
  if ! "$PY" -m pip --version >/dev/null 2>&1; then
    log "Bootstrapping pip for $PY"
    if $CHECK_MODE; then
      echo "+ $PY -m ensurepip --upgrade || true"
    else
      "$PY" -m ensurepip --upgrade || true
    fi
    
    if $CHECK_MODE; then
      echo "+ $PY -m pip install --upgrade pip setuptools wheel --user"
    else
      "$PY" -m pip install --upgrade pip setuptools wheel --user || {
        local SUDO=($(need_sudo))
        "${SUDO[@]}" "$PY" -m pip install --upgrade pip setuptools wheel
      }
    fi
  fi

  if "$PY" -m django --version >/dev/null 2>&1; then
    ok "Django already installed for $PY: $($PY -m django --version)"
  else
    log "Installing Django for $PY (user scope)"
    run "$PY" -m pip install --user django
    ok "Django installed: $($PY -m django --version)"
  fi
}

main() {
  ensure_apt
  install_docker
  install_docker_compose
  install_python_and_pip
  install_django

  echo
  ok "All done. You may need to restart your shell for group changes (docker) to take effect."
}

main "$@"
