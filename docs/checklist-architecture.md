# Checklist actionnable — Architecture logicielle SOTA

---

## Recensement
- [ ] Inventaire des modules, dépendances, versions
- [ ] Lien vers tickets d’évolution : [#arch-001](https://repo/issues/arch-001)
- [ ] Mapping artefacts : `specs/architecture.yaml`, `docs/diagrams/architecture-workflow.svg.txt`

## Analyse d’écart
- [ ] Comparaison vs standards Roo/Cline/VSIX
- [ ] Lien vers issue : [#arch-gap](https://repo/issues/arch-gap)
- [ ] Documentation des écarts : `reports/arch-gap.md`

## Spécification
- [ ] Rédaction des specs YAML/Go
- [ ] Lien vers artefact : `specs/architecture.yaml`
- [ ] Validation croisée : [#spec-review](https://repo/issues/spec-review)

## Développement
- [ ] Implémentation modulaire Go
- [ ] Lien vers PR : [#arch-dev](https://repo/pulls/arch-dev)
- [ ] Tests unitaires : `tests/quality-checklist.md`

## Tests
- [ ] Couverture >90% : `reports/coverage-badge.svg`
- [ ] Lien vers rapport : `reports/arch-tests.md`
- [ ] Validation automatisée CI/CD

## Reporting
- [ ] Génération reporting HTML/Markdown
- [ ] Lien vers artefact : `reports/arch-report.md`
- [ ] Badge validation : `reports/validation-badge.svg`

## Validation
- [ ] Revue croisée, feedback dev
- [ ] Lien feedback : `feedback/dev-feedback.csv`
- [ ] Issue validation : [#arch-validate](https://repo/issues/arch-validate)

## Rollback/versionning
- [ ] Procédure rollback : `scripts/rollback.sh`
- [ ] Documentation versionning : `docs/versionning.md`
- [ ] Lien vers backup : `backups/data-backup.sql`

## Automatisation
- [ ] Script d’actualisation : `scripts/update-docs.go`
- [ ] Lien vers workflow CI/CD : `.github/workflows/roadmap.yml`
- [ ] Notification automatisée : `reports/ci-status.log`

## Documentation & traçabilité
- [ ] Documentation croisée : [roadmap-granularisation-sota.md](../.github/docs/roadmap/roadmap-granularisation-sota.md)
- [ ] Liens dynamiques vers tickets, artefacts, docs
- [ ] Historique des modifications

## Feedback
- [ ] Collecte feedback UX/dev : `scripts/collect-feedback.go`
- [ ] Suivi dans `/feedback/auto-feedback.csv`
- [ ] Boucle d’amélioration continue

---
