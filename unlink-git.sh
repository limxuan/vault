#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: unlink-git.sh <target-dir>

Removes the .git directory from <target-dir>, so a cloned vault template stops
being its own git repository. Use this when the vault lives inside a larger
project repo and you do not want a nested repo / accidental gitlink.

Your notes and config are untouched. Any unpushed history is lost.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi
case "$1" in
  -h|--help) usage; exit 0 ;;
esac

TARGET="$1"
if [[ ! -d "$TARGET/.git" ]]; then
  echo "error: '$TARGET/.git' not found; nothing to unlink" >&2
  exit 1
fi

rm -rf -- "$TARGET/.git"
echo "Removed git metadata from: $TARGET"
