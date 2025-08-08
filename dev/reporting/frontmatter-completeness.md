# Rapport de complétude frontmatter — Audit SOTA

| Fichier | Statut | Clés manquantes |
|---------|--------|-----------------|
| [`0-point-de-depart.md`](projet/roadmaps/plans/audits/2025-0808-Transfo-SOTa/projet/0-point-de-depart.md:1) | ✅ Complet | - |
| [`1-dispatch-operationnel.md`](projet/roadmaps/plans/audits/2025-0808-Transfo-SOTa/projet/1-dispatch-operationnel.md:1) | ❌ Incomplet | slo_p95, uptime_target, mttr_target, parents, enfants, artefacts, cross_refs |
| [`2-dispatch-ope-vers-doc.md`](projet/roadmaps/plans/audits/2025-0808-Transfo-SOTa/projet/2-dispatch-ope-vers-doc.md:1) | ❌ Absent | frontmatter standard |
| [`3-dispatch-documentaire.md`](projet/roadmaps/plans/audits/2025-0808-Transfo-SOTa/projet/3-dispatch-documentaire.md:1) | ❌ Absent | frontmatter standard |
| [`dispatch-workflow.md`](projet/roadmaps/plans/audits/2025-0808-Transfo-SOTa/projet/dispatch-workflow.md:1) | ✅ Complet | - |

**Instructions :**
- Ajouter le frontmatter standard dans chaque fichier KO avant CI documentaire.
- Proposer autofix pour chaque fichier manquant.
- Lier ce rapport dans [`dev/reporting/README.md`](dev/reporting/README.md:1).

STATUS Phase 1: FAIL (frontmatter incomplet sur 3 fichiers, autofix requis avant CI documentaire).