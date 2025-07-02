# Scripts d’automatisation Go/YAML

Ce dossier contient tous les scripts Go pour l’audit, la correction, le lint, le reporting et l’orchestration de l’écosystème Go/YAML.

## Scripts disponibles

- [`list-go-mods.go`](list-go-mods.go) : Recense tous les fichiers `go.mod` et `go.work`.
- [`analyze-go-mods.go`](analyze-go-mods.go) : Analyse les directives interdites et imports locaux dans les fichiers Go.
- [`fix-go-mods.go`](fix-go-mods.go) : Corrige automatiquement les fichiers Go, backup `.bak` avant modif.
- [`list-yaml-files.go`](list-yaml-files.go) : Recense tous les fichiers YAML (Helm, CI/CD).
- [`lint-yaml.go`](lint-yaml.go) : Valide la syntaxe YAML.
- [`fix-yaml.go`](fix-yaml.go) : Corrige indentation et scalaires YAML, backup `.bak`.
- [`backup-restore.go`](backup-restore.go) : Restaure tous les fichiers `.bak` générés.
- [`aggregate-diagnostics.go`](aggregate-diagnostics.go) : Agrège les diagnostics Go/YAML/CI dans un rapport Markdown.
- [`auto-roadmap-runner.go`](auto-roadmap-runner.go) : Orchestrateur global, exécute tous les scripts dans l’ordre.

## Utilisation

```bash
go run scripts/list-go-mods.go
go run scripts/analyze-go-mods.go
go run scripts/fix-go-mods.go
go run scripts/list-yaml-files.go
go run scripts/lint-yaml.go
go run scripts/fix-yaml.go
go run scripts/backup-restore.go
go run scripts/aggregate-diagnostics.go
go run scripts/auto-roadmap-runner.go
```

## Prérequis

- Go 1.21+
- Module `gopkg.in/yaml.v3` pour les scripts YAML :  
  `go get gopkg.in/yaml.v3`
- Outils externes : `golangci-lint`, `go vet`

## Convention

- Chaque script crée un backup `.bak` avant modification.
- Les rapports sont générés dans `audit-reports/`.
- L’orchestrateur (`auto-roadmap-runner.go`) exécute toutes les étapes de façon atomique.

## Tests

Des tests unitaires sont à ajouter pour chaque script critique (voir roadmap).
