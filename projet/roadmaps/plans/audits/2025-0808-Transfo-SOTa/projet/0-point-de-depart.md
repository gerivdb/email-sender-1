---
source: "0-point-de-depart"
last_update: "2025-08-08T04:28:54+02:00"
owner: "AuditManager"
reviewer: "EnterpriseLead"
managers: ["SecurityManager", "DocManager", "MonitoringManager"]
contracts: ["Registry", "AGENTS", "Implementation Status"]
slo_p95: "95%"
uptime_target: "99.9%"
mttr_target: "2h"
parents: ["Architecture", "Gouvernance/Sécurité", "CI/CD & Qualité", "Observabilité", "Scalabilité/Perf", "Erreurs & Robustesse", "Modularité/Plugins", "Roadmap & KPIs", "Implémentation & Config", "Documentation & DX", "Feedback"]
enfants: ["ADRs", "Policies", "Matrices", "Benchmarks", "Procédures", "Canevas", "Rapports"]
artefacts: ["Managers Registry", "Implementation Status", "AGENTS.md", "Enterprise Docs", "bench_targets.md", "audit-procedure.md", "versionning.md", "rollback/procedure_rollback.md"]
cross_refs: ["catalog-complete.md", "README.md", "bench_targets.md", "AGENTS.md", "audit-procedure.md"]
dispatch_index:
  - Section: "Architecture & Modularité"
    Parent: "Architecture"
    Enfants: ["ADRs", "Benchmarks"]
    Managers: ["Orchestrator", "SecurityManager"]
    Artefacts: ["README_ARCHITECTURE.md", "bench_targets.md"]
    Statut: "En cours"
    SLO/SLA: "p95/uptime/MTTR"
  - Section: "Sécurité"
    Parent: "Gouvernance/Sécurité"
    Enfants: ["Policies"]
    Managers: ["SecurityManager", "API Gateway"]
    Artefacts: ["security-policies.md"]
    Statut: "Validé"
    SLO/SLA: "p95/uptime/MTTR"
  - Section: "CI/CD & Qualité"
    Parent: "CI/CD & Qualité"
    Enfants: ["Matrices", "Tests"]
    Managers: ["PipelineManager"]
    Artefacts: ["specs/dependencies-matrix.md", "tests/README.md"]
    Statut: "En cours"
    SLO/SLA: "p95/uptime/MTTR"
---

# Template de Transformation SOTA — v4 améliorée Roo/Enterprise

Ce template v4 transforme le point de départ en un template opérationnel, traçable et industrialisable, aligné sur le catalogue des managers, les statuts d’implémentation, et les normes Enterprise.  
Il intègre : graphe de dépendances documentaire, sous-prompts modulaires, validations SLO/SLA, rollback documentaire, filiation descendante, et contrôles d’intégrité.

---

## 1. Architecture & Modularité (L1)

- Structuration par piliers SOTA, filiation descendante L1→L2/L3 :
  - Parents L1 : architecture, gouvernance/sécurité, CI/CD & qualité, observabilité, scalabilité/perf, erreurs & robustesse, modularité/plugins, roadmap & KPIs, implémentation & config, documentation & DX, feedback.
  - Enfants L2/L3 : ADRs, policies, matrices, benchmarks, procédures, canevas, rapports.
- Intégration Roo/Enterprise :
  - Rattachement managers : SecurityManager, API Gateway, Tenant, MonitoringManager, DocManager, Orchestrator, LoadBalancer, Replication, Alerting, Metrics, Pipeline, Error, Script, Storage, Roadmap.
  - Références artefacts centraux : Registry, Implementation Status, AGENTS.md, Enterprise Docs, matrices de performances/tests.
- Graphe de dépendances documentaire :  
  - Déclaration parents/enfants/cross-refs (frontmatter), détection cycles/orphelins en CI.

---

## 2. Variables Génériques & Points d’Extension (L1/L2)

- Variables :  
  - {{project_name}}, {{manager_name}}, {{module_list}}, {{dependencies}}, {{artefact_path}}, {{quality_gates}}, {{slo_p95}}, {{uptime_target}}, {{mttr_target}}
- Points d’extension Roo :  
  - PluginInterface (plugins/stratégies/hook managers : validation, reporting, rollback)
  - QualityGatePlugin (gates CI/CD, SLO/SLA, aligné Testing Strategy Enterprise)

---

## 3. Centralisation des Artefacts (L1/L2)

- Dossiers/artefacts standardisés :  
  - docs/diagrams/*.mmd, specs/*-matrix.md, docs/audit-procedure.md, docs/versionning.md, scripts/*, dev/benchmarks/bench_targets.md, dev/tests/README.md, dev/exceptions/exemple_exception.md, dev/rollback/procedure_rollback.md
- Cross-références obligatoires : Registry, Implementation Status, AGENTS.md, dashboards/benchmarks/SLAs

---

## 4. Checklist Actionnable SOTA (L1/L2)

- [ ] Recensement modules/dépendances/versions + carte managers Enterprise
- [ ] Analyse d’écart vs standards/capacités v64/v65 (perf, sécurité, couverture, CICD)
- [ ] Spécifications YAML/Go/Bash + schémas Roo (pipelines, errors, monitoring)
- [ ] Développement modulaire par pilier + points d’extension (plugins/hook)
- [ ] Tests unitaires/intégration/perf/sécurité/chaos avec seuils Enterprise (90%/80%…)
- [ ] Reporting automatisé (benchmarks, écarts SLO/SLA, couverture), métriques pipeline
- [ ] Validation croisée et feedback multi-personas (owners/reviewers), boucle continue
- [ ] Procédures rollback/versionning (snapshots, .bak, logs d’opération)
- [ ] Automatisation actualisation/feedback (collecte/sync docs, prompts-guidés)
- [ ] Documentation croisée/traçabilité (frontmatter, liens relatifs, index de dispatch)
- [ ] Gestion exceptions/cas limites (taxonomie, mapping HTTP, hooks ErrorManager)
- [ ] Adaptation LLM/robustesse prompt (concision, modularité, continuation/cache)

---

## 5. Procédure de Validation & Feedback (L1/L2)

- Validation collaborative par pilier + confirmation explicite owners/reviewers, notifications/artefacts de rapport
- Feedback continu centralisé (feedback/auto-feedback.csv) + intégration sprints/avancement
- Documentation objections/alternatives, traçabilité décisions (fixes-applied.md, corrections-report.md)
- Mise à jour synchronisée du template selon retours et évolutions SOTA/Registry

---

## 6. Cas Limites & Exceptions (L1/L2)

- Contexte insuffisant : demander précision, créer “questions ouvertes” + blocage Quality Gate
- Conflit de validation : documenter, alerter owners, pause transactionnelle avant commit
- Export impossible : fournir formats alternatifs (Markdown/JSON/PDF) et gabarits compatibles
- Évolutions managers : liens Registry/AGENTS, compat_matrix, notes d’upgrade/migration

---

## 7. Liens Utiles & Références (L1/L2)

- [Managers Registry](../../../../../catalog-complete.md)
- [Implementation Status](../../../../../implementation-status.md)
- [AGENTS.md](../../../../../AGENTS.md)
- [Enterprise Docs (README.md)](../../../../../README.md)
- [bench_targets.md](../../../../../bench_targets.md)
- [audit-procedure.md](../../../../../docs/audit-procedure.md)
- [versionning.md](../../../../../docs/versionning.md)
- [rollback/procedure_rollback.md](../../../../../dev/rollback/procedure_rollback.md)

---

## 8. Contrôles d’Intégrité et Qualité (L1/L2)

- En-têtes standard dans chaque fichier : source, dernière maj, owner/reviewer, managers, contrats/API, SLO/SLA
- Graphe de dépendances : détection cycles, liens brisés, orphelins; blocage CI si critique; rapport d’écarts
- SLO/SLA + non-régression documentaire : conformité p95/uptime/MTTR par composant; diffs sémantiques et revalidation ciblée
- Journaux sobres : 1 ligne/fichier + rollup par phase; artefact de rapport unique par phase; rotation/compaction

---

## 9. Sous-prompts modulaires (L2/L3, bibliothèque prête à l’emploi)

- **ADR (Architecture)** :  
  “Analyser la section Architecture; générer adr-XXX: Contexte/Options/Décision/Conséquences; lier Orchestrator/Security; insérer SLO/SLA; cohérence Registry/AGENTS; log court.”
- **Security Policies** :  
  “Compléter security-policies.md: OAuth2/JWT via API Gateway/Tenant, RBAC, rotation clés, AES-256-GCM, audit; conformité (GDPR/SOC2/ISO); liens Status; log.”
- **Benchmarks** :  
  “Mettre à jour bench_targets.md: cibles p95/throughput/MTTR/MTBF; scénarios k6/JMeter; profiling CPU/Mem; corrélation Tracing/Monitoring; log.”
- **Tests & Qualité** :  
  “Compléter tests/README.md: matrices unit/int/perf/séc/chaos; coverage gates; mutation testing; upgrade/backward; aligner Testing Strategy; log.”
- **Erreurs & Rollback** :  
  “Remplir exceptions/ et rollback/: taxonomie, mapping HTTP, hooks ErrorManager; snapshots/compensations; rapports; log.”

Orchestration : séquencer L1→L2→L3, paralléliser où possible, cache/continuation pour gros contenus, arrêts transactionnels en cas d’incohérences.

---

## 10. Pipeline de validation documentaire (CI/CD logique)

- Gates CI : liens relatifs valides, en-têtes complets, cross-refs managers/artefacts, graphe acyclique, SLO/SLA présents, non-duplication artefacts centraux
- Rapports : tableau d’écarts/remédiations, état de complétude par pilier, alertes via Notification/Alerting
- Rollback documentaire : snapshot avant phase, commit si green, sinon restauration + rapport d’incident

---

## 11. Index de dispatch & filiation descendante (obligatoires)

- Tableau “Dispatch Index” en tête (voir frontmatter)
- Chaque fichier cible : frontmatter source/owners/managers/contracts/SLO; “parents” et “enfants” déclarés; liens relatifs

---

## 12. Valeur ajoutée vs outils existants (positionnement)

- Différenciation : génération granulaire end-to-end depuis un seul point de départ, intégrée managers Enterprise, validation SLO/SLA, graphe de dépendances, rollback transactionnel
- Pilotage : workflows/prompts modulaires, reporting d’état, traçabilité documentaire standardisée Enterprise

---

## 13. Checklists d’acceptation (par phase)

- **Phase 1** : 100% en-têtes, index complet, graphe acyclique, bidirectionnalité vérifiée
- **Phase 2** : rattachements managers/API/SLO; matrices tests/bench/compliance remplies; zéro duplication artefacts centraux
- **Phase 3** : CI “green” liens/en-têtes/cross-refs/SLO/graphe; alertes actives; rollback prêt
- **Phase 4** : auto-critique par parent, backlog d’amélioration relié aux sprints, feedback tracé

---

**Ce template v4 est parfaitement aligné avec le registre des managers, les statuts d’implémentation et les standards Enterprise, assurant cohérence, actionnabilité à 95% et conformité SOTA à chaque étape du dispatch et de l’industrialisation documentaire.**
