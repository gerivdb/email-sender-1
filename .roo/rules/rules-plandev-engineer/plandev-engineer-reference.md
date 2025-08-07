# PlanDev Engineer — Référence granularisation SOTA

---

## Intégration des pratiques SOTA

Ce mode PlanDev Engineer intègre la granularisation exhaustive des roadmaps selon le guide [roadmap-granularisation-sota.md](../../../.github/docs/roadmap/roadmap-granularisation-sota.md).

- Tous les artefacts roadmap (diagrammes, checklists, scripts, matrices, feedback) sont rangés dans les dossiers dédiés.
- Les workflows Mermaid sont exportés en SVG/PNG dans `/docs/diagrams/` et liés dans les roadmaps.
- Les scripts d’actualisation automatique (`scripts/update-docs.go`) et de feedback (`scripts/collect-feedback.go`) sont utilisés pour synchroniser la documentation et collecter les retours UX/dev.
- Les checklists et matrices intègrent des liens dynamiques vers tickets, issues, artefacts et code source.
- La documentation VSIX/Cline référence ces pratiques et artefacts pour garantir la traçabilité et l’automatisation.

---

## Exemples concrets

### Modèle YAML — Recensement
```yaml
modules:
  - name: "indexer"
    version: "1.2.3"
    dependencies: ["monitor", "audit"]
```

### Script Go — Rollback
```go
package main
func main() {
  // Restore backup, logs, validation
}
```

### Script Bash — Reporting
```bash
go test ./... > reports/arch-tests.md
```

---

## Matrices synthétiques

- **Dépendances multi-outils** : `specs/dependencies-matrix.md`
- **Compatibilité versions Roo/Cline/VSIX** : `specs/integration-matrix.md`
- **Matrice RBAC** : `specs/rbac-matrix.md`

---

## Checklist actionnable PlanDev Engineer

- [ ] Recensement modules, dépendances, versions
- [ ] Analyse d’écart vs standards SOTA
- [ ] Spécification YAML/Go/Bash
- [ ] Développement modulaire
- [ ] Tests unitaires/intégration/sécurité/perf
- [ ] Reporting automatisé
- [ ] Validation croisée, feedback dev
- [ ] Procédure rollback/versionning
- [ ] Automatisation actualisation/feedback
- [ ] Documentation croisée, traçabilité
- [ ] Gestion exceptions/cas limites
- [ ] Adaptation LLM, robustesse atomique

---

## Workflow visuel exporté

![diagramme](../../../docs/diagrams/architecture-workflow.svg.txt)

---

## Procédures d’audit, rollback, versionning

- Audit : `docs/audit-procedure.md`
- Rollback : `scripts/rollback.sh`
- Versionning : `docs/versionning.md`

---

## Gestion des exceptions/cas limites

- Documentation : `docs/exceptions.md`
- Feedback continu : `feedback/auto-feedback.csv`

---

## Liens dynamiques tickets/issues/artefacts

- [Ticket recensement](https://repo/issues/plandev-recensement)
- [Issue rollback](https://repo/issues/plandev-rollback)
- [Artefact reporting](../../../reports/arch-report.md)
- [Code source](https://repo/src/plandev-engineer.go)

---

## Guide d’adaptation LLM & robustesse atomique

- Guide LLM : `docs/llm-adaptation.md`
- Conventions robustesse : `docs/robustesse.md`

---

## Workflow d’intégration

1. Générer les artefacts roadmap (diagrammes, checklists, scripts, matrices, feedback)
2. Lier dynamiquement chaque artefact aux tickets, issues, matrices et docs associées
3. Automatiser la mise à jour et la collecte de feedback
4. Valider la traçabilité et la conformité SOTA dans VSIX/Cline

---
