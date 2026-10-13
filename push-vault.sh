#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${VAULT_REPO_URL:-git@github.com:limxuan/vault.git}"
GH_USER="${VAULT_GH_USER:-limxuan}"
GIT_NAME="${VAULT_GIT_NAME:-limxuan}"
GIT_EMAIL="${VAULT_GIT_EMAIL:-reconlx.official@gmail.com}"

usage() {
  cat <<'EOF'
Usage: push-vault.sh [vault-path]

Push an existing vault's Obsidian config (.obsidian/ and .obsidian.vimrc) back
to the vault template repo, so `new-vault.sh --sync` can distribute it. Notes
are never read or pushed.

  vault-path  vault to push from (default: detect in the current directory)
  -h, --help  show this help

  cd ~/Projects/my-vault
  curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/push-vault.sh | bash
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

say() {
  if have gum; then gum style --foreground 212 "$*"; else printf '%s\n' "$*"; fi
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Run a gum prompt against the terminal even when stdin is a pipe (curl | bash).
gum_ui() {
  if [[ -t 0 ]]; then
    gum "$@"
  elif { exec 3</dev/tty; } 2>/dev/null; then
    local rc=0
    gum "$@" <&3 || rc=$?
    exec 3<&-
    return "$rc"
  else
    gum "$@"
  fi
}

ask() {
  local prompt="$1" ans
  if [[ -t 0 ]]; then
    read -rp "$prompt" ans
  elif { exec 3</dev/tty; } 2>/dev/null; then
    read -rp "$prompt" ans <&3
    exec 3<&-
  else
    read -rp "$prompt" ans || return 1
  fi
  printf '%s' "$ans"
}

confirm() {
  if have gum; then
    gum_ui confirm "$1"
  else
    local ans
    ans="$(ask "$1 [y/N] ")" || return 1
    [[ "$ans" == [yY]* ]]
  fi
}

ARG_NAME=""
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; usage >&2; exit 1 ;;
    *) ARG_NAME="$arg" ;;
  esac
done

if [[ -n "$ARG_NAME" ]]; then
  VAULT="$PWD/$ARG_NAME"
  [[ "$ARG_NAME" == /* ]] && VAULT="$ARG_NAME"
elif [[ -e "$PWD/.obsidian" ]]; then
  VAULT="$PWD"
elif [[ -e "$PWD/vault/.obsidian" ]]; then
  VAULT="$PWD/vault"
else
  die "no vault found (run inside one or pass its path)"
fi
[[ -e "$VAULT/.obsidian" ]] || die "'$VAULT' is not an Obsidian vault"

for dep in git rsync; do
  have "$dep" || die "$dep is required"
done

if [[ "$(git -C "$VAULT" remote get-url origin 2>/dev/null </dev/null || true)" == "$REPO_URL" ]]; then
  die "$VAULT is the template repo itself"
fi

if ! git ls-remote "$REPO_URL" HEAD >/dev/null 2>&1 </dev/null; then
  die "cannot access $REPO_URL (check your credentials/key)"
fi

if [[ "$REPO_URL" == *github.com* ]]; then
  SSH_ID="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com </dev/null 2>&1 || true)"
  if [[ "$SSH_ID" != *"Hi ${GH_USER}!"* ]]; then
    die "not authenticated to GitHub as '${GH_USER}' (got: ${SSH_ID:-no response})"
  fi
  say "Authenticated to GitHub as ${GH_USER}."
fi

TMP_DIR=""
cleanup() { [[ -n "$TMP_DIR" ]] && rm -rf -- "$TMP_DIR" || true; }
trap cleanup EXIT

TMP_DIR="$(mktemp -d)"
echo "Fetching template from $REPO_URL ..."
git clone --quiet "$REPO_URL" "$TMP_DIR/template" </dev/null
CLONE="$TMP_DIR/template"

list_dirs() {
  [[ -d "$1" ]] || return 0
  local d
  for d in "$1"/*/; do
    [[ -d "$d" ]] || continue
    basename "$d"
  done | sort
}

plugin_diff() {
  local src="$VAULT/.obsidian/$1" dst="$CLONE/.obsidian/$1" p
  local src_dirs dst_dirs
  src_dirs="$(list_dirs "$src")"
  dst_dirs="$(list_dirs "$dst")"
  ADDED=(); REMOVED=(); UPDATED=()
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    if ! grep -qxF "$p" <<<"$dst_dirs"; then ADDED+=("$p")
    elif ! diff -rq "$src/$p" "$dst/$p" >/dev/null 2>&1; then UPDATED+=("$p"); fi
  done <<<"$src_dirs"
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    grep -qxF "$p" <<<"$src_dirs" || REMOVED+=("$p")
  done <<<"$dst_dirs"
}

config_diff() {
  local rel
  CONFIG_ADDED=(); CONFIG_REMOVED=(); CONFIG_UPDATED=()
  for rel in \
    .obsidian/app.json .obsidian/appearance.json \
    .obsidian/community-plugins.json .obsidian/core-plugins.json \
    .obsidian/hotkeys.json .obsidian/page-preview.json \
    .obsidian/types.json .obsidian/.gitignore .obsidian.vimrc .gitignore; do
    local a="$VAULT/$rel" b="$CLONE/$rel"
    if [[ -e "$a" && ! -e "$b" ]]; then CONFIG_ADDED+=("$rel")
    elif [[ ! -e "$a" && -e "$b" ]]; then
      [[ "$rel" == ".obsidian.vimrc" || "$rel" == ".gitignore" ]] || CONFIG_REMOVED+=("$rel")
    elif [[ -e "$a" && -e "$b" ]] && ! cmp -s "$a" "$b"; then CONFIG_UPDATED+=("$rel"); fi
  done
}

plugin_diff plugins; P_ADD=("${ADDED[@]}"); P_REM=("${REMOVED[@]}"); P_UPD=("${UPDATED[@]}")
plugin_diff themes;   T_ADD=("${ADDED[@]}"); T_REM=("${REMOVED[@]}"); T_UPD=("${UPDATED[@]}")
config_diff

print_list() {
  local label="$1"; shift
  [[ $# -eq 0 ]] && return 0
  printf '%s\n' "$label"
  local it
  for it in "$@"; do printf '    %s\n' "$it"; done
}

say "Changes to push to ${GH_USER}/vault:"
printf '\n'
print_list "  Plugins added:"   "${P_ADD[@]}"
print_list "  Plugins removed:" "${P_REM[@]}"
print_list "  Plugins updated:" "${P_UPD[@]}"
print_list "  Themes added:"    "${T_ADD[@]}"
print_list "  Themes removed:"  "${T_REM[@]}"
print_list "  Themes updated:"  "${T_UPD[@]}"
print_list "  Config added:"    "${CONFIG_ADDED[@]}"
print_list "  Config removed:"  "${CONFIG_REMOVED[@]}"
print_list "  Config updated:"  "${CONFIG_UPDATED[@]}"
printf '\n'

TOTAL=$(( ${#P_ADD[@]} + ${#P_REM[@]} + ${#P_UPD[@]} + ${#T_ADD[@]} + ${#T_REM[@]} \
        + ${#T_UPD[@]} + ${#CONFIG_ADDED[@]} + ${#CONFIG_REMOVED[@]} + ${#CONFIG_UPDATED[@]} ))
if [[ "$TOTAL" -eq 0 ]]; then
  say "Nothing to push; vault already matches the template."
  exit 0
fi

confirm "Push these changes to ${GH_USER}/vault main?" || { echo "Aborted."; exit 0; }

rsync -a --delete \
  --exclude 'workspace.json' \
  --exclude 'workspace-mobile.json' \
  --exclude 'cache/' \
  "$VAULT/.obsidian/" "$CLONE/.obsidian/" </dev/null
[[ -e "$VAULT/.obsidian.vimrc" ]] && cp -- "$VAULT/.obsidian.vimrc" "$CLONE/.obsidian.vimrc"
[[ -e "$VAULT/.gitignore" ]] && cp -- "$VAULT/.gitignore" "$CLONE/.gitignore"

git -C "$CLONE" add -A </dev/null
if git -C "$CLONE" diff --cached --quiet </dev/null; then
  say "Nothing to push; vault already matches the template."
  exit 0
fi

DEFAULT_MSG="Sync vault config ($(git -C "$CLONE" diff --cached --name-only </dev/null | wc -l) files)"
if have gum; then
  MSG="$(gum_ui input --header "Commit message" --value "$DEFAULT_MSG" || true)"
  [[ -z "$MSG" ]] && MSG="$DEFAULT_MSG"
else
  MSG="$(ask "Commit message [$DEFAULT_MSG]: ")" || true
  MSG="${MSG:-$DEFAULT_MSG}"
fi

git -C "$CLONE" -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" \
  commit --quiet -m "$MSG" </dev/null
git -C "$CLONE" push --quiet origin HEAD:main </dev/null

say "Pushed $(git -C "$CLONE" rev-parse --short HEAD </dev/null) to ${GH_USER}/vault main."
