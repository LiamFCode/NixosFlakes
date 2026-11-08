#!/usr/bin/env bash

set -euo pipefail

VERSION="0.1.0"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
RESET='\033[0m'

FLAKE_DIR="${NIX_UPDATE_FLAKE:-.}"

info() {
  printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

success() {
  printf "${GREEN}[OK]${RESET} %s\n" "$*"
}

warning() {
  printf "${YELLOW}[UPDATE]${RESET} %s\n" "$*"
}

error() {
  printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

usage() {
  cat <<'EOF'
nix-update - Flake input update checker

USAGE:
  nix-update <command> [options]

COMMANDS:
  check       Check for available updates
  list        List direct flake inputs
  outdated    Show outdated inputs
  notify      Send a desktop notification if updates exist
  json        Output update information as JSON
  update      Explicitly update the flake lockfile
  help        Show this help
  version     Show version

OPTIONS:
  -f, --flake PATH    Flake directory (default: current directory)

ENVIRONMENT:
  NIX_UPDATE_FLAKE    Default flake directory

The check command does not modify flake.lock
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--flake)
      FLAKE_DIR="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

COMMAND="${1:-help}"

if [[ ! -f "$FLAKE_DIR/flake.lock" ]]; then
  error "No flake.lock found in $FLAKE_DIR"
  exit 1
fi

FLAKE_DIR="$(cd "$FLAKE_DIR" && pwd)"

resolve_latest() {
  local node="$1"
  local type owner repo ref url

  type="$(jq -r '.original.type // empty' <<< "$node")"

  case "$type" in
    github|gitlab)
      owner="$(jq -r '.original.owner // empty' <<< "$node")"
      repo="$(jq -r '.original.repo // empty' <<< "$node")"
      ref="$(jq -r '.original.ref // empty' <<< "$node")"

      if [[ -z "$owner" || -z "$repo" ]]; then
        return 1
      fi

      url="${type}:${owner}/${repo}"

      if [[ -n "$ref" ]]; then
        url="${url}?ref=${ref}"
      fi
      ;;
    git)
      url="$(jq -r '.original.url // empty' <<< "$node")"

      if [[ -z "$url" ]]; then
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac

  nix flake metadata \
    --refresh \
    --json \
    "$url" 2>/dev/null |
    jq -r '.locked.rev // empty'
}

collect_updates() {
  local lockfile="$FLAKE_DIR/flake.lock"

  jq -c '
    . as $lock |
    $lock.nodes.root.inputs
    | to_entries[]
    | select(.value | type == "string")
    | {
        name: .key,
        node: $lock.nodes[.value]
      }
  ' "$lockfile" |
  while IFS= read -r entry; do
    local name node current latest

    name="$(jq -r '.name' <<< "$entry")"
    node="$(jq -c '.node' <<< "$entry")"
    current="$(jq -r '.locked.rev // "unknown"' <<< "$node")"

    if latest="$(resolve_latest "$node")" && [[ -n "$latest" ]]; then
      if [[ "$current" != "$latest" ]]; then
        jq -cn \
          --arg name "$name" \
          --arg current "$current" \
          --arg latest "$latest" \
          '{name:$name,current:$current,latest:$latest,status:"outdated"}'
      else
        jq -cn \
          --arg name "$name" \
          --arg current "$current" \
          '{name:$name,current:$current,latest:$current,status:"current"}'
      fi
    else
      jq -cn \
        --arg name "$name" \
        --arg current "$current" \
        '{name:$name,current:$current,latest:null,status:"unsupported"}'
    fi
  done
}

list_inputs() {
  jq -r '
    .nodes.root.inputs
    | to_entries[]
    | "\(.key) -> \(.value)"
  ' "$FLAKE_DIR/flake.lock"
}

check_updates() {
  info "Checking flake inputs in $FLAKE_DIR"
  echo

  collect_updates |
  while IFS= read -r entry; do
    local name status current latest

    name="$(jq -r '.name' <<< "$entry")"
    status="$(jq -r '.status' <<< "$entry")"
    current="$(jq -r '.current' <<< "$entry")"
    latest="$(jq -r '.latest // "unavailable"' <<< "$entry")"

    case "$status" in
      outdated)
        warning "$name"
        echo "  Current: $current"
        echo "  Latest:  $latest"
        ;;
      current)
        success "$name is up to date"
        ;;
      unsupported)
        info "$name could not be checked automatically"
        ;;
    esac

    echo
  done
}

outdated_inputs() {
  collect_updates |
    jq -r 'select(.status == "outdated") |
      "\(.name): \(.current) -> \(.latest)"'
}

json_report() {
  jq -s '.' < <(collect_updates)
}

notify_updates() {
  local results count

  results="$(collect_updates)"
  count="$(jq -s '[.[] | select(.status == "outdated")] | length' <<< "$results")"

  if [[ "$count" -eq 0 ]]; then
    success "No available updates detected."
    return
  fi

  if ! command -v notify-send >/dev/null 2>&1; then
    error "notify-send is unavailable."
    exit 1
  fi

  notify-send \
    "Nix flake updates available" \
    "$count flake input(s) have updates available."
}

case "$COMMAND" in
  check)
    check_updates
    ;;
  list)
    list_inputs
    ;;
  outdated)
    outdated_inputs
    ;;
  json)
    json_report
    ;;
  notify)
    notify_updates
    ;;
  update)
    nix flake update --flake "$FLAKE_DIR"
    ;;
  version|--version)
    echo "nix-update v$VERSION"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    error "Unknown command: $COMMAND"
    usage
    exit 2
    ;;
esac
