#!/usr/bin/env bash

set -euo pipefail

VERSION="0.1.0"

CONFIG="${QUICK_ACTIONS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/quick-actions/actions.json}"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

info() {
  printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

success() {
  printf "${GREEN}[OK]${RESET} %s\n" "$*"
}

warning() {
  printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"
}

error() {
  printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

require_config() {
  if [[ ! -f "$CONFIG" ]]; then
    error "Action configuration not found: $CONFIG"
    exit 1
  fi
}

usage() {
  cat <<'EOF'
quick-actions - Declarative Linux quick actions

USAGE:
  quick-actions <command> [arguments]

COMMANDS:
  list                  List all available actions
  run <name>            Execute an action
  info <name>           Display action information
  search <query>        Search available actions
  help                  Show this help
  version               Show version

ENVIRONMENT:
  QUICK_ACTIONS_CONFIG  Custom JSON configuration path
EOF
}

list_actions() {
  require_config

  echo "Available actions:"
  echo

  jq -r '
    to_entries[] |
    "  \(.key)\n    \(.value.description // "No description")"
  ' "$CONFIG"
}

action_info() {
  require_config

  local name="$1"

  if ! jq -e --arg name "$name" \
    'has($name)' "$CONFIG" >/dev/null; then
    error "Unknown action: $name"
    exit 1
  fi

  jq -r --arg name "$name" '
    .[$name] |
    "Name:        \($name)\n" +
    "Description: \(.description // "None")\n" +
    "Category:    \(.category // "General")\n" +
    "Command:     \(.command)\n" +
    "Confirmation: \(.confirm // false)"
  ' "$CONFIG"
}

search_actions() {
  require_config

  local query="${1,,}"

  jq -r --arg query "$query" '
    to_entries[] |
    select(
      ((.key + " " + (.value.description // "") + " " +
        (.value.category // "")) | ascii_downcase)
      | contains($query)
    ) |
    "\(.key) - \(.value.description // "No description")"
  ' "$CONFIG"
}

run_action() {
  require_config

  local name="$1"
  local command
  local confirm

  if ! jq -e --arg name "$name" \
    'has($name)' "$CONFIG" >/dev/null; then
    error "Unknown action: $name"
    exit 1
  fi

  command="$(jq -r --arg name "$name" \
    '.[$name].command' "$CONFIG")"

  confirm="$(jq -r --arg name "$name" \
    '.[$name].confirm // false' "$CONFIG")"

  if [[ -z "$command" || "$command" == "null" ]]; then
    error "Action has no command"
    exit 1
  fi

  if [[ "$confirm" == "true" ]]; then
    warning "You are about to execute: $name"
    printf "Are you sure? [y/N] "

    local answer
    read -r answer

    case "$answer" in
      y|Y|yes|YES)
        ;;
      *)
        info "Action cancelled"
        return 0
        ;;
    esac
  fi

  info "Running action: $name"

  bash -c "$command"
}

case "${1:-help}" in
  list)
    list_actions
    ;;
  run)
    [[ $# -ge 2 ]] || {
      error "Please specify an action"
      exit 2
    }
    run_action "$2"
    ;;
  info)
    [[ $# -ge 2 ]] || {
      error "Please specify an action"
      exit 2
    }
    action_info "$2"
    ;;
  search)
    [[ $# -ge 2 ]] || {
      error "Please specify a search query"
      exit 2
    }
    search_actions "$2"
    ;;
  version|--version)
    echo "quick-actions v${VERSION}"
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
