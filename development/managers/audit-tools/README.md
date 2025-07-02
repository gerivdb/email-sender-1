# Audit automatique du manager

Ce dossier contient les scripts d’audit et d’inventaire pour ce manager.

## Exécution locale

```bash
cd audit-tools
bash run_all_audits.sh
```

Les rapports générés seront :
- `audit_inventory.md`
- `audit_gap_report.md`
- `standards_inventory.md`
- `duplication_report.md`
- `roadmaps_index.md`
- `cross_doc_inventory.md`

## Intégration CI/CD

Ajoutez ce job dans `.github/workflows/audit.yml` :

```yaml
name: Audit Manager

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - name: Exécuter tous les audits
        run: |
          cd audit-tools
          bash run_all_audits.sh
```

## Centralisation des rapports

Pour centraliser les rapports de plusieurs managers, utilisez un script de collecte à la racine du repo.

---