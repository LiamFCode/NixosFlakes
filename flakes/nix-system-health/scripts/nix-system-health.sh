
#!/usr/bin/env bash

set -euo pipefail

DISK_THRESHOLD=85

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk-threshold)
      DISK_THRESHOLD="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

echo "================================"
echo "       SYSTEM HEALTH REPORT"
echo "================================"

ISSUES=0

echo
echo "[ DISK USAGE ]"

while read -r filesystem usage; do
  if [[ "$usage" =~ ^[0-9]+$ ]]; then
    printf "%-35s %s%%\n" "$filesystem" "$usage"

    if (( usage >= DISK_THRESHOLD )); then
      echo "WARNING: Disk usage above threshold!"
      ISSUES=$((ISSUES + 1))
    fi
  fi
done < <(df -P -x tmpfs -x devtmpfs | awk 'NR > 1 {print $1, $5}' | sed 's/%//')

echo
echo "[ MEMORY ]"

free -h

echo
echo "[ FAILED SYSTEMD SERVICES ]"

FAILED=$(systemctl --failed --no-legend --plain 2>/dev/null || true)

if [[ -n "$FAILED" ]]; then
  echo "$FAILED"
  ISSUES=$((ISSUES + 1))
else
  echo "No failed services"
fi

echo
echo "[ NIX STORE ]"

if [[ -d /nix/store ]]; then
  du -sh /nix/store 2>/dev/null || true
fi

echo
echo "================================"

if (( ISSUES > 0 )); then
  echo "Health check completed with $ISSUES warning(s)."
  exit 1
else
  echo "Health check completed with zero issues found"
fi
