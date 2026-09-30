# Vault

A portable Obsidian vault template for dropping into project folders, so note
taking starts with the same editor, keybindings, and plugins everywhere.

## What's included

- **Vim mode** with a persistent config in `.obsidian.vimrc` (loaded by the
  Vimrc Support plugin):
  - `<Space>va` select all
  - `<Space>ff` open quick switcher (find files)
  - `<Space>fw` search the whole vault
  - `<Space>w` save, `<Space>q` close tab
  - `<Space>1`..`<Space>8` jump to tab N, `<Space>9` last tab
- **Community plugins** (binaries committed, so a fresh clone works offline):
  - [obsidian-vimrc-support](https://github.com/esm7/obsidian-vimrc-support)
  - [obsidian-excalidraw-plugin](https://github.com/zsviczian/obsidian-excalidraw-plugin)
  - [sticky-heading](https://github.com/onlyjus/obsidian-sticky-heading)
  - [obsidian-relative-line-numbers](https://github.com/nadavspi/obsidian-relative-line-numbers)
  - [oz-clear-unused-images](https://github.com/ozntel/oz-clear-unused-images)
- Sensible core settings: absolute line numbers, readable line length off,
  pasted media routed to `! Pasted Media`.

## Scaffold a new vault

```sh
./new-vault.sh ~/Projects/my-app
```

This copies `.obsidian/`, `.obsidian.vimrc`, and a starter `Welcome.md` into the
target folder (creating it if needed) and adds the transient Obsidian paths to
the project's `.gitignore`. Re-running against a folder that already has
`.obsidian` fails unless you pass `--force`.

To call it from anywhere, put the script on your `PATH`:

```sh
ln -s "$PWD/new-vault.sh" ~/.local/bin/new-vault
new-vault ~/Projects/another-project
```

## Git & nested repos

`new-vault.sh` copies files with `rsync` and never copies `.git`, so vaults it
creates are plain folders and cannot trigger nested-repo / submodule problems.

If you instead `git clone` this template into a project, strip its git metadata
so it is not a repository of its own:

```sh
./unlink-git.sh ~/Projects/my-app
```

You can also mark this repo as a
[GitHub template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository)
so "Use this template" produces a clean copy with no history.

## Notes

- `.obsidian/workspace.json` (open tabs, cursor, recent files) and `.trash/`
  are intentionally git-ignored — they are per-machine state and can leak note
  names.
- `.obsidian/appearance.json` enables a CSS snippet named `obsidian-void-theme`.
  The snippet file is not committed; either add it back under
  `.obsidian/snippets/` or clear the `enabledCssSnippets` list.
- `new-vault.sh`, `unlink-git.sh`, and this README are hidden from the Obsidian
  file explorer via `userIgnoreFilters` in `.obsidian/app.json`.

## Security

There are no secrets in this repo. The Excalidraw plugin's API key fields are
empty, and Vimrc Support's "Support JS commands" is left at its default (off),
so notes cannot execute JavaScript.
