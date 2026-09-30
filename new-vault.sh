#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${VAULT_REPO_URL:-https://github.com/limxuan/vault.git}"

usage() {
  cat <<'EOF'
Usage: new-vault.sh [--force] [folder-name]

Creates an Obsidian vault in the current directory, prompting for the folder
name (default: vault).

  --force     overwrite an existing vault folder
  -h, --help  show this help

  cd ~/Projects/my-app
  curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash
EOF
}

FORCE=0
VAULT_NAME=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; usage >&2; exit 1 ;;
    *) VAULT_NAME="$arg" ;;
  esac
done

if [[ -z "$VAULT_NAME" ]]; then
  if [[ -t 0 ]]; then
    read -rp "Vault folder name [vault]: " VAULT_NAME || true
  elif { exec 3</dev/tty; } 2>/dev/null; then
    read -rp "Vault folder name [vault]: " VAULT_NAME <&3 || true
    exec 3<&-
  fi
  VAULT_NAME="${VAULT_NAME:-vault}"
fi

TARGET="$PWD/$VAULT_NAME"

if [[ -e "$TARGET" && "$FORCE" -ne 1 ]]; then
  echo "error: '$TARGET' already exists (use --force to overwrite)" >&2
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
  command -v git >/dev/null 2>&1 || { echo "error: git is required" >&2; exit 1; }
  TMP_DIR="$(mktemp -d)"
  echo "Fetching vault template from $REPO_URL ..."
  git clone --depth 1 --quiet "$REPO_URL" "$TMP_DIR/template"
  SRC="$TMP_DIR/template"
fi

command -v rsync >/dev/null 2>&1 || { echo "error: rsync is required" >&2; exit 1; }

if [[ "$FORCE" -eq 1 ]]; then
  rm -rf -- "$TARGET"
fi
mkdir -p -- "$TARGET"

rsync -a \
  --exclude '/.git/' \
  --exclude '/.trash/' \
  --exclude '/new-vault.sh' \
  --exclude '/README.md' \
  --exclude '/.obsidian/workspace.json' \
  --exclude '/.obsidian/workspace-mobile.json' \
  --exclude '/.obsidian/cache/' \
  "$SRC"/ "$TARGET"/

echo "Created vault at: $TARGET"
