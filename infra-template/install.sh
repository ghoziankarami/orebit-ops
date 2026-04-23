#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

info() {
  printf '[infra-template] %s\n' "$*"
}

warn() {
  printf '[infra-template][WARN] %s\n' "$*" >&2
}

die() {
  printf '[infra-template][ERROR] %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_pkg_manager() {
  if command_exists apt-get; then
    printf 'apt-get'
    return 0
  fi
  if command_exists dnf; then
    printf 'dnf'
    return 0
  fi
  if command_exists yum; then
    printf 'yum'
    return 0
  fi
  return 1
}

install_packages() {
  local manager="$1"
  shift
  local -a packages=("$@")

  case "$manager" in
    apt-get)
      if [[ "$(id -u)" -eq 0 ]]; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
        return $?
      fi

      if command_exists sudo; then
        sudo apt-get update
        sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
        return $?
      fi
      ;;
    dnf|yum)
      if [[ "$(id -u)" -eq 0 ]]; then
        "$manager" install -y "${packages[@]}"
        return $?
      fi

      if command_exists sudo; then
        sudo "$manager" install -y "${packages[@]}"
        return $?
      fi
      ;;
  esac

  return 1
}

ensure_command_or_install() {
  local command_name="$1"
  local apt_package="$2"
  local rpm_package="$3"
  local label="$4"

  if command_exists "$command_name"; then
    info "Found $label: $(command -v "$command_name")"
    return 0
  fi

  local manager
  if ! manager="$(detect_pkg_manager)"; then
    die "Missing required prerequisite: $label (no supported package manager found)"
  fi

  local package_name="$rpm_package"
  if [[ "$manager" == "apt-get" ]]; then
    package_name="$apt_package"
  fi

  info "Missing $label; attempting installation with $manager package '$package_name'."
  if ! install_packages "$manager" "$package_name"; then
    die "Unable to install $label with $manager package '$package_name'."
  fi

  command_exists "$command_name" || die "$label install attempt completed but the command is still unavailable"
  info "Installed $label: $(command -v "$command_name")"
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || die "Missing required file: $path"
}

run_installer() {
  local installer="$1"
  info "Running $(basename "$installer")"
  bash "$installer"
}

if [[ $# -ne 0 ]]; then
  die "This installer takes no arguments. Run: bash install.sh"
fi

ensure_command_or_install docker docker.io moby "Docker"
ensure_command_or_install python3 python3 python3 "Python 3"
ensure_command_or_install rclone rclone rclone "rclone"

require_file "$SCRIPT_DIR/.env.example"
require_file "$SCRIPT_DIR/.env.template"
require_file "$SCRIPT_DIR/.env.template.master"

mkdir -p "$SCRIPT_DIR"
chmod 644 "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env.template" "$SCRIPT_DIR/.env.template.master"

run_installer "$SCRIPT_DIR/../obsidian-system/install.sh"
run_installer "$SCRIPT_DIR/../rag-system/install.sh"
run_installer "$SCRIPT_DIR/../research-data/install.sh"

info "Summary: prerequisites are present or installed, delegated installers completed successfully."
info "Infra template install complete."
