# Vault

A portable Obsidian vault template. Drops the same editor (Vim), keybindings,
and plugins into any project folder.

## Install into a project

One-liner, no checkout needed:

```sh
curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash -s -- ~/Projects/my-app
```

Or from a local clone:

```sh
./new-vault.sh ~/Projects/my-app
```

The target is created if missing. It refuses to touch a folder that already has
a `.obsidian` directory unless you pass `--force`.

The script copies files and never keeps the template's `.git`, so the vault is a
plain folder and will not cause nested-repo or submodule issues.

Requires `git` and `rsync`.

## What you get

- `.obsidian/` with community plugins committed, so it works offline
- `.obsidian.vimrc` keybindings:
  - `<Space>va` select all
  - `<Space>ff` find files, `<Space>fw` search the vault
  - `<Space>w` save, `<Space>q` close tab
  - `<Space>1`..`<Space>8` jump to tab N, `<Space>9` last tab
- A starter `Welcome.md`
- Transient state (`.obsidian/workspace.json`, `.trash/`) added to the project's
  `.gitignore`

Plugins: Vimrc Support, Excalidraw, Sticky Heading, Relative Line Numbers, Clear
Unused Images.

## Notes

- `.obsidian/appearance.json` references an `obsidian-void-theme` snippet that is
  not committed; add it under `.obsidian/snippets/` or clear
  `enabledCssSnippets`.
- No secrets: Excalidraw's API key fields are empty and Vimrc Support's
  "Support JS commands" is off.
