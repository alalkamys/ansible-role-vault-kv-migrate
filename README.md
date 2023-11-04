# Vault KV Migrate Role

[![CI](https://github.com/alalkamys/ansible-role-vault-kv-migrate/actions/workflows/ci.yaml/badge.svg)](https://github.com/alalkamys/ansible-role-vault-kv-migrate/actions/workflows/ci.yaml)
[![Percentage of issues still open](http://isitmaintained.com/badge/open/alalkamys/ansible-role-vault-kv-migrate.svg)](http://isitmaintained.com/project/alalkamys/ansible-role-vault-kv-migrate "Percentage of issues still open")
[![License](https://img.shields.io/badge/license-MIT%20License-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Ansible Role](https://img.shields.io/badge/galaxy-alalkamys.vault_kv_migrate-blue.svg)](https://galaxy.ansible.com/alalkamys/vault_kv_migrate/)
[![GitHub tag](https://img.shields.io/github/tag/alalkamys/ansible-role-vault-kv-migrate.svg)](https://github.com/alalkamys/ansible-role-vault-kv-migrate/tags)

## Overview

The `vault_kv_migrate` role automates the migration of secrets from one HashiCorp Vault Key-Value (KV) engine to multiple engines. It can also export HashiCorp KV secrets for a given path recursively and save them to a file named `'secrets.json'` for backups. `vault_kv_migrate` is perfect for operational tasks where you need to either replicate HashiCorp KV secrets to one or more Vault servers, KV engines within the same Vault server or a mix of both. It is also handful when you want to export the KV secrets to your machine as a backup.

`vault_kv_migrate` can also write migrate KV secrets of HashiCorp Vault sitting behind [Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/).

> **Note:** `vault_kv_migrate` is meant for operation tasks.

## Requirements

- Ansible 2.11.5 or higher
- jmespath 0.10.0 or higher
- vault CLI v1.15 or higher
- HashiCorp Vault installed and configured

## Role Variables

| Variable                                    | Default Value                             | Description                                                                                                                                                          |
| ------------------------------------------- | ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vault_kv_migrate_vault_api_version`        | `v1`                                      | Vault API version to use.                                                                                                                                            |
| `vault_kv_migrate_vault_api_validate_certs` | `no`                                      | Whether to validate SSL certificates for Vault API requests. Set to `yes` to enable certificate validation.                                                          |
| `vault_kv_migrate_remove_backup`            | `no`                                      | Whether to remove `'secrets.json'` backup file after migration. Set to `yes` to remove the local backup file after the migration.                                    |
| `vault_kv_migrate_cf_token`                 | `""`                                      | Cloudflare token for Zero trust authentication. If not used, keep it empty.                                                                                          |
| `vault_kv_migrate_src_vault_addr`           | `"http://localhost:8200"`                 | Address of the source Vault server.                                                                                                                                  |
| `vault_kv_migrate_src_vault_token`          | `""`                                      | Token for authentication with the source Vault server.                                                                                                               |
| `vault_kv_migrate_src_vault_namespace`      | `""`                                      | Namespace for the source Vault server.                                                                                                                               |
| `vault_kv_migrate_src_engine`               | `secret`                                  | Source Vault KV engine from which secrets will be migrated. Don't add trailing `/` to the engine.                                                                    |
| `vault_kv_migrate_src_secret_path`          | `""`                                      | Path to the source secret within the source engine. if the value is `""` `vault_kv_migrate` will export/migrate all the secrets under `vault_kv_migrate_src_engine`. |
| `vault_kv_migrate_dest_kv_engines`          | [See example playbook](#example-playbook) | List of destination Vault KV engines with configurations. See example playbook for structure.                                                                        |

## Example Playbook

```yaml
- hosts: localhost
  become: no
  roles:
    - vault_kv_migrate
  vars:
    vault_kv_migrate_vault_api_version: "v1"
    vault_kv_migrate_vault_api_validate_certs: no
    vault_kv_migrate_remove_backup: no
    vault_kv_migrate_cf_token: ""
    vault_kv_migrate_src_vault_addr: "http://localhost:8200"
    vault_kv_migrate_src_vault_token: ""
    vault_kv_migrate_src_vault_namespace: ""
    vault_kv_migrate_src_engine: "secret"
    vault_kv_migrate_src_secret_path: ""
    vault_kv_migrate_dest_kv_engines:
      - vault_addr: "http://localhost:8200"
        vault_token: ""
        vault_namespace: ""
        engine: "secret2"
```

## Role Workflow

### 1. Export Source Secrets

The role first exports secrets from the specified source Vault KV engine and path. It securely retrieves the secrets and saves them to a temporary file named `'secrets.json'`.

### 2. Transfer to Destination Engines

The exported secrets are then transferred to multiple destination Vault KV engines. For each secret, the role makes secure POST requests to the corresponding destination paths in the destination Vault KV engines. This ensures that the secrets are securely and accurately transferred.

### 3. Backup and Cleanup

After the migration is completed, the backup file `'secrets.json'` can be removed based on the value of the `vault_kv_migrate_remove_backup` variable. Removing the backup file is optional and can be configured as per your requirements.

## Role Tags

| Tag             | Action                                                                                                       | Example                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------- |
| `export`        | exports the kv secrets only and saves it to your machine in `secrets.json`                                   | ansible-playbook site.yml --tags export        |
| `write_secrets` | writes secrets in `secrets.json` found under your `{{ playbook_dir }}` to your list of Vault KV engines only | ansible-playbook site.yml --tags write_secrets |
| `remove_backup` | removes `{{ playbook_dir }}/secrets.json` only                                                               | ansible-playbook site.yml --tags remove_backup |

## Secrets Backup File

The exported secrets data will be stored in `{{ playboook_dir }}/secrets.json`, an example can be seen down below

```json
[
  {
    "path": "secret/path/to/secret1",
    "value": {
      "data": {
        "data": {
          "key": "value",
        },
        "metadata": {
          "created_time": "2023-11-04T14:30:44.5094809Z",
          "custom_metadata": null,
          "deletion_time": "",
          "destroyed": false,
          "version": 1
        }
      }
    }
  },
  {
    "path": "secret/path/to/secret2",
    "value": {
      "data": {
        "data": {
          "key1": "value",
          "key2": "value",
        },
        "metadata": {
          "created_time": "2023-11-04T14:30:45.217227213Z",
          "custom_metadata": null,
          "deletion_time": "",
          "destroyed": false,
          "version": 1
        }
      }
    }
  }
]
```

## License

This role is licensed under the MIT License. For more details, refer to the [LICENSE](LICENSE) file.

## Author Information

- **Author:** Shehab El-Deen Alalkamy
- **Email:** [shehabeldeenalalkamy@gmail.com](mailto:shehabeldeenalalkamy@gmail.com)
- **GitHub:** [alalkamys](https://github.com/alalkamys)

For more information and updates, please visit the [GitHub repository](https://github.com/alalkamys/ansible-role-vault-kv-migrate).
