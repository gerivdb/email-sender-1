# Checklist Roo Code — Déplacement documentaire multi-fichiers

- [ ] Configuration YAML conforme au schéma [`file-moves.schema.yaml`](file-moves.schema.yaml)
- [ ] Scripts d’orchestration présents et testés (`move-files.go`, `move-files.sh`, `move-files.ps1`, `scripts/move-files.py`)
- [ ] Hooks documentés et implémentés [`file-moves.hooks.md`](file-moves.hooks.md)
- [ ] Rapport Markdown généré et archivé [`rapport-move-files.md`](rapport-move-files.md)
- [ ] Rapport JSON généré et archivé [`rapport-move-files.json`](rapport-move-files.json)
- [ ] Guide d’utilisation à jour [`GUIDE.file-moves.md`](GUIDE.file-moves.md)
- [ ] Tâches VS Code configurées [`tasks.file-moves.json`](tasks.file-moves.json)
- [ ] Workflow CI opérationnel [`.github/workflows/move-files-ci.yml`](.github/workflows/move-files-ci.yml)
- [ ] Validation YAML automatisée (lint + schéma)
- [ ] Rollback et sauvegardes testés
- [ ] Documentation centrale à jour ([`README.file-moves.md`](README.file-moves.md))
- [ ] Liens utiles centralisés [`LIENS.file-moves.md`](LIENS.file-moves.md)
- [ ] Tests unitaires et dry-run validés
- [ ] Archivage automatique des rapports
- [ ] Respect des standards Roo Code et [référentiel plandev-engineer](.roo/rules/plandev-engineer-reference.md)