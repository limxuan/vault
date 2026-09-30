# Vault

Portable Obsidian vault template with my Vim keybindings and plugins.

Run this in the folder you want the vault in:

```sh
curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash
```

It creates `./vault`. Pass a name for a different folder:

```sh
curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash -s -- notes
```

Requires `git` and `rsync`. The script never keeps `.git`, so there are no
nested-repo or submodule issues.
