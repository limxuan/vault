# Vault

Portable Obsidian vault template.

Create a vault in the current directory (prompts for the folder name):

```sh
curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash
```

Update an existing vault's config, keeping your notes:

```sh
cd path/to/vault
curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/new-vault.sh | bash -s -- --sync
```

Push an existing vault's config back to this template (notes are never touched):

```sh
cd path/to/vault
curl -fsSL https://raw.githubusercontent.com/limxuan/vault/main/push-vault.sh | bash
```
