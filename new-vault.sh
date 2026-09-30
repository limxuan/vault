#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${VAULT_REPO_URL:-https://github.com/limxuan/vault.git}"

usage() {
  cat <<'EOF'
Usage: new-vault.sh [--force] <target-dir>

Install the Obsidian vault template into <target-dir> (created if needed).

  --force     overwrite an existing .obsidian in the target
  -h, --help  show this help

Run locally:
  ./new-vault.sh ~/Projects/my-app

Or straight from GitHub, no checkout needed:
  curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash -s -- ~/Projects/my-app
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

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi

TMP_DIR=""
cleanup() { [[ -n "$TMP_DIR" ]] && rm -rf -- "$TMP_DIR" || true; }
trap cleanup EXIT

if [[ -n "$SCRIPT_DIR" && -e "$SCRIPT_DIR/.obsidian" ]]; then
  SRC="$SCRIPT_DIR"
else
  command -v git >/dev/null 2>&1 || {
    echo "error: git is required when running this script without a local checkout" >&2
    exit 1
  }
  TMP_DIR="$(mktemp -d)"
  echo "Fetching vault template from $REPO_URL ..."
  git clone --depth 1 --quiet "$REPO_URL" "$TMP_DIR/template"
  SRC="$TMP_DIR/template"
fi

command -v rsync >/dev/null 2>&1 || {
  echo "error: rsync is required" >&2
  exit 1
}

mkdir -p -- "$TARGET"

rsync -a \
  --exclude '/.git/' \
  --exclude '/.trash/' \
  --exclude '/.gitignore' \
  --exclude '/new-vault.sh' \
  --exclude '/README.md' \
  --exclude '/.obsidian/workspace.json' \
  --exclude '/.obsidian/workspace-mobile.json' \
  --exclude '/.obsidian/cache/' \
  "$SRC"/ "$TARGET"/

if [[ ! -e "$TARGET/Welcome.md" ]]; then
  cp -- "$SRC/Welcome.md" "$TARGET/Welcome.md"
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
