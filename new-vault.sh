#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${VAULT_REPO_URL:-https://github.com/limxuan/vault.git}"

usage() {
  cat <<'EOF'
Usage: new-vault.sh [--force] [folder-name]
       new-vault.sh --sync [vault-path]

Create a new vault in the current directory (prompts for the folder name,
default: vault), or pull the latest template config into an existing vault
with --sync. Syncing only touches .obsidian/ and .obsidian.vimrc; your notes
and workspace layout are left alone.

  --force     overwrite an existing vault folder (create mode)
  --sync      update the config of an existing vault
  -h, --help  show this help

  cd ~/Projects/my-app
  curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash
  curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash -s -- --sync
EOF
}

MODE="create"
FORCE=0
ARG_NAME=""
for arg in "$@"; do
  case "$arg" in
    --sync) MODE="sync" ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; usage >&2; exit 1 ;;
    *) ARG_NAME="$arg" ;;
  esac
done

if [[ "$MODE" == "create" ]]; then
  VAULT_NAME="$ARG_NAME"
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
else
  if [[ -n "$ARG_NAME" ]]; then
    TARGET="$PWD/$ARG_NAME"
  elif [[ -e "$PWD/.obsidian" ]]; then
    TARGET="$PWD"
  elif [[ -e "$PWD/vault/.obsidian" ]]; then
    TARGET="$PWD/vault"
  else
    echo "error: no vault found (run inside one or pass its path)" >&2
    exit 1
  fi
  [[ -e "$TARGET/.obsidian" ]] || { echo "error: '$TARGET' is not an Obsidian vault" >&2; exit 1; }
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

if [[ "$MODE" == "create" ]]; then
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
else
  rsync -a \
    --exclude 'workspace.json' \
    --exclude 'workspace-mobile.json' \
    --exclude 'cache/' \
    "$SRC/.obsidian/" "$TARGET/.obsidian/"
  cp -- "$SRC/.obsidian.vimrc" "$TARGET/.obsidian.vimrc"
  if [[ ! -e "$TARGET/.gitignore" && -e "$SRC/.gitignore" ]]; then
    cp -- "$SRC/.gitignore" "$TARGET/.gitignore"
  fi
  echo "Synced config into: $TARGET"
fi
