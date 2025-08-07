# Cline — Intégration granularisation SOTA

---

Ce guide décrit l’intégration des pratiques de granularisation SOTA dans la documentation Cline.

## Artefacts et liens

- [Granularisation SOTA](../roadmap/roadmap-granularisation-sota.md)
- [Checklist architecture](../../docs/checklist-architecture.md)
- [Diagramme architecture](../../docs/diagrams/architecture-workflow.svg.txt)
- [Script actualisation](../../scripts/update-docs.go)
- [Script feedback](../../scripts/collect-feedback.go)
- [PlanDev Engineer référence](../../.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md)

## Workflow d’intégration

1. Générer et ranger les artefacts roadmap dans les dossiers dédiés
2. Lier dynamiquement chaque artefact aux tickets, issues, matrices et docs associées
3. Automatiser la mise à jour et la collecte de feedback
4. Valider la traçabilité et la conformité SOTA dans Cline

## Exemples d’usage

- Utiliser les diagrammes exportés dans les présentations et pipelines CI/CD
- Synchroniser la documentation avec `scripts/update-docs.go`
- Collecter et analyser les feedbacks avec `scripts/collect-feedback.go`
- Naviguer entre artefacts via les liens dynamiques dans les checklists et matrices

---
