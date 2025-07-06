# Guide d’usage des scripts d’automatisation Go/YAML

## 1. Orchestration complète

Pour lancer l’ensemble des audits, corrections, tests et reporting en une seule commande :

```bash
go run scripts/auto-roadmap-runner.go
```

## 2. Exécution individuelle

Chaque script peut être exécuté séparément pour cibler une étape précise :

- **Lister les go.mod/go.work** :
  ```bash
  go run scripts/list-go-mods.go
  ```
- **Analyser les go.mod/go.work** :
  ```bash
  go run scripts/analyze-go-mods.go
  ```
- **Corriger les go.mod/go.work** :
  ```bash
  go run scripts/fix-go-mods.go
  ```
- **Lister les fichiers YAML** :
  ```bash
  go run scripts/list-yaml-files.go
  ```
- **Lint YAML** :
  ```bash
  go run scripts/lint-yaml.go
  ```
- **Correction YAML** :
  ```bash
  go run scripts/fix-yaml.go
  ```
- **Restauration des backups** :
  ```bash
  go run scripts/backup-restore.go
  ```
- **Agrégation des diagnostics** :
  ```bash
  go run scripts/aggregate-diagnostics.go
  ```

## 3. CI/CD

Le pipeline GitHub Actions `.github/workflows/ci-go-yaml-automation.yml` exécute automatiquement tous les scripts à chaque push/PR sur les branches principales.

## 4. Bonnes pratiques

- Toujours vérifier les backups `.bak` avant toute correction de masse.
- Consulter les rapports générés dans `audit-reports/`.
- Ajouter des tests unitaires pour tout nouveau script ou évolution.
- Utiliser l’orchestrateur pour garantir la reproductibilité et la traçabilité.
