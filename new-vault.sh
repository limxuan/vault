#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: new-vault.sh [--force] <target-dir>

Stamps this Obsidian vault template into <target-dir>, creating the directory
if needed. Existing .obsidian config is only overwritten with --force.

Options:
  --force     overwrite .obsidian in the target if it already exists
  -h, --help  show this help

Examples:
  ./new-vault.sh ~/Projects/my-app
  ./new-vault.sh --force ~/Projects/my-app
EOF
}

FORCE=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; usage >&2; exit 1 ;;
    *) TARGET="$arg" ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  usage >&2
  exit 1
fi

if [[ -e "$TARGET/.obsidian" && "$FORCE" -ne 1 ]]; then
  echo "error: '$TARGET/.obsidian' already exists (use --force to overwrite)" >&2
  exit 1
fi

mkdir -p -- "$TARGET"

rsync -a \
  --exclude '/.git/' \
  --exclude '/.trash/' \
  --exclude '/.gitignore' \
  --exclude '/new-vault.sh' \
  --exclude '/unlink-git.sh' \
  --exclude '/README.md' \
  --exclude '/.obsidian/workspace.json' \
  --exclude '/.obsidian/workspace-mobile.json' \
  --exclude '/.obsidian/cache/' \
  "$TEMPLATE_DIR"/ "$TARGET"/

if [[ ! -e "$TARGET/Welcome.md" ]]; then
  cp -- "$TEMPLATE_DIR/Welcome.md" "$TARGET/Welcome.md"
fi

GITIGNORE="$TARGET/.gitignore"
MARKER="# >>> obsidian-vault-template >>>"
if [[ ! -f "$GITIGNORE" ]] || ! grep -qF "$MARKER" "$GITIGNORE" 2>/dev/null; then
  {
    echo ""
    echo "$MARKER"
    echo ".trash/"
    echo ".obsidian/workspace.json"
    echo ".obsidian/workspace-mobile.json"
    echo ".obsidian/cache/"
    echo "# <<< obsidian-vault-template <<<"
  } >> "$GITIGNORE"
fi

echo "Installed Obsidian vault template into: $TARGET"
