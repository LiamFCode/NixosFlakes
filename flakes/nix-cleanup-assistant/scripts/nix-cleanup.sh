
#!/usr/bin/env bash

set -euo pipefail

VERSION="0.1.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

info() {
  echo -e "${BLUE}[INFO]${RESET} $*"
}

success() {
  echo -e "${GREEN}[OK]${RESET} $*"
}

warning() {
  echo -e "${YELLOW}[WARNING]${RESET} $*"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $*" >&2
}

header() {
  echo
  echo "========================================"
  echo " $*"
  echo "========================================"
  echo
}

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    error "This operation requires root privileges"
    echo "Try running it with sudo"
    exit 1
  fi
}

check_command() {
  command -v "$1" >/dev/null 2>&1
}

disk_report() {
  header "FILESYSTEM USAGE"

  df -h -x tmpfs -x devtmpfs
}

store_report() {
  header "NIX STORE"

  if [[ ! -d /nix/store ]]; then
    warning "Nix store not found"
    return
  fi

  info "Current Nix store size:"
  du -sh /nix/store

  echo
  info "Largest top-level store directories:"

  du -sh /nix/store/* 2>/dev/null |
    sort -hr |
    head -n 10 || true
}

generation_report() {
  header "NIXOS GENERATIONS"

  local profile="/nix/var/nix/profiles/system"

  if [[ ! -e "$profile" ]]; then
    warning "NixOS system profile not found"
    return
  fi

  nix-env --list-generations --profile "$profile" ||
    warning "Unable to list generations"
}

journal_report() {
  header "SYSTEM JOURNAL"

  if ! check_command journalctl; then
    warning "journalctl is unavailable"
    return
  fi

  journalctl --disk-usage ||
    warning "Unable to inspect journal usage"
}

container_report() {
  header "CONTAINER STORAGE"

  local found=0

  if check_command docker; then
    found=1
    info "Docker storage:"
    docker system df || warning "Unable to inspect Docker"
  fi

  if check_command podman; then
    found=1
    info "Podman storage:"
    podman system df || warning "Unable to inspect Podman"
  fi

  if [[ "$found" -eq 0 ]]; then
    info "No Docker or Podman installation detected"
  fi
}

suggestions() {
  header "CLEANUP SUGGESTIONS"

  echo "Here are some commands you may want to consider:"
  echo

  echo "1. Remove old NixOS generations:"
  echo "   sudo nix-collect-garbage --delete-older-than 30d"
  echo

  echo "2. Remove old system journal entries:"
  echo "   sudo journalctl --vacuum-time=14d"
  echo

  echo "3. Optimize the Nix store:"
  echo "   nix-store --optimise"
  echo

  echo "4. Review Docker storage:"
  echo "   docker system df"
  echo

  echo "5. Review Podman storage:"
  echo "   podman system df"
  echo

  warning "These commands can permanently remove data."
  warning "Review each command before executing it"
}

full_report() {
  header "NIX CLEANUP ASSISTANT v${VERSION}"

  disk_report
  store_report
  generation_report
  journal_report
  container_report
  suggestions

  header "REPORT COMPLETE"
}

usage() {
  cat <<EOF
nix-cleanup v${VERSION}

A safe NixOS disk analysis and cleanup assistant.

USAGE:
  nix-cleanup <command>

COMMANDS:
  disk          Show filesystem usage
  store         Analyze Nix store size
  generations   List NixOS generations
  journal       Show journal disk usage
  containers    Show Docker/Podman usage
  suggest       Show cleanup recommendations
  report        Run all analysis commands
  version       Show version
  help          Show this help

This tool never deletes data automatically.
EOF
}

case "${1:-help}" in
  disk)
    disk_report
    ;;
  store)
    store_report
    ;;
  generations)
    generation_report
    ;;
  journal)
    journal_report
    ;;
  containers)
    container_report
    ;;
  suggest)
    suggestions
    ;;
  report)
    full_report
    ;;
  version|--version|-v)
    echo "nix-cleanup v${VERSION}"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    error "Unknown command: $1"
    usage
    exit 2
    ;;
esac
