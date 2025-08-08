---
source: "dispatch-workflow"
last_update: "2025-08-08T04:08:00+02:00"
owner: "DevOpsLead"
reviewer: "EnterpriseLead"
managers: ["DocManager", "PipelineManager", "MonitoringManager", "RollbackManager"]
contracts: ["Registry", "AGENTS", "Implementation Status"]
slo_p95: "95%"
uptime_target: "99.9%"
mttr_target: "2h"
parents: ["0-point-de-depart.md"]
enfants: ["1-dispatch-operationnel.md", "2-dispatch-ope-vers-doc.md", "3-dispatch-documentaire.md"]
artefacts: ["catalog-complete.md", "AGENTS.md", "audit-procedure.md", "rollback/procedure_rollback.md"]
cross_refs: ["README.md", "bench_targets.md", "audit-procedure.md"]
---

# Workflow théorique du dispatch automatisé Roo/SOTA

Ce fichier formalise le workflow automatisé du dispatch documentaire, modulaire et traçable.

## Diagramme séquentiel

```mermaid
flowchart TD
    A[0-point-de-depart.md] --> B[1-dispatch-operationnel.md]
    B --> C[2-dispatch-ope-vers-doc.md]
    C --> D[3-dispatch-documentaire.md]
    D --> E[Validation CI >95%]
    E --> F{Succès ?}
    F -->|Oui| G[Reporting & Finalisation]
    F -->|Non| H[Rollback via snapshot]
```

## Étapes du workflow

| # | Étape | Description | Managers impliqués | Artefacts/Contrôles |
|---|-------|-------------|--------------------|---------------------|
| 1 | Initialisation | Chargement du contexte et des managers | DocManager, AuditManager | Frontmatter, index |
| 2 | Dispatch opérationnel | Génération index, matrice, prompts | DocManager, PipelineManager | 1-dispatch-operationnel.md |
| 3 | Passerelle transformation | Contrôles, logs, structuration | MonitoringManager, PipelineManager | 2-dispatch-ope-vers-doc.md |
| 4 | Dispatch documentaire | Création fichiers, rattachements | DocManager, MonitoringManager | 3-dispatch-documentaire.md |
| 5 | Validation CI | Quality gates, benchmarks, logs | QualityGateManager, MonitoringManager | CI, logs, rapport |
| 6 | Reporting | Rapport synthétique, log unique | MonitoringManager | audit-procedure.md |
| 7 | Rollback | Restauration snapshot si échec | RollbackManager | rollback/procedure_rollback.md |

## Points de contrôle

- En-têtes standard et index présents à chaque étape
- Graphe de dépendances acyclique, liens valides
- SLO/SLA et artefacts centralisés
- Reporting et logs sobres, traçabilité complète
- Rollback automatisé en cas d’échec CI

## Critères de succès

- 100% des fichiers générés et validés
- CI documentaire “green”
- Reporting et logs archivés
- Rollback prêt et documenté

## Remarques

Ce workflow est conçu pour être piloté par prompts, compatible CI/CD, et extensible via plugins Roo (PluginInterface, QualityGatePlugin).  
Il garantit la conformité SOTA, la modularité et la robustesse documentaire.
