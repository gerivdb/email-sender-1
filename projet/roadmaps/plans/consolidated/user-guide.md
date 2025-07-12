# Guide utilisateur – Workflow de migration et synchronisation Roadmap

## Prérequis

- Go 1.22+
- Accès au dossier `projet/roadmaps/plans/consolidated/`
- Qdrant opérationnel (optionnel pour la synchronisation finale)

## Étapes

1. **Inventaire** : Vérifiez `inventory-report.md`
2. **Analyse d’écart** : Consultez `gap-analysis-report.md`
3. **Migration** : Exécutez `go run cmd/auto-roadmap-runner/main.go`
4. **Tests** : Lancez `go test ./cmd/auto-roadmap-runner/...`
5. **CI/CD** : Automatisation via GitHub Actions
6. **Synchronisation Qdrant** : Utilisez les scripts dédiés
7. **Visualisation** : Utilisez le CLI ou ouvrez `roadmap-viewer.html`
8. **Reporting** : Consultez `migration-report.md`, `traceability-report.md`, `coverage_badge.md`
9. **Rollback** : Utilisez les fichiers `.bak` ou git

## Validation

- Badge de couverture >90%
- Reporting CI/CD
- Revue croisée
