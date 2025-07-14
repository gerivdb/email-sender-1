# Référence des Modes Custom – Écosystème RooCode/KiloCode

---
SECTION 1 

## 🟢 Modes par défaut RooCode/KiloCode

- Orchestrator (`orchestrator`)
- Code (`code`)
- Ask (`ask`)
- Debug (`debug`)
- Architect (`architect`)


## 🟠 Modes Marketplace RooCode

- 🛡️ Security Reviewer (`security-review`)
- 📝 User Story Creator (`user-story-creator`)
- 🔍 Project Research (`project-research`)
- 📝 Documentation Writer (`documentation-writer`)
- Jest Test Engineer (`jest-test-engineer`)
- DevOps (`devops`)

## 🟣 Modes personnalisés à créer

*(Ajoute ici les nouveaux modes que tu souhaites développer, par exemple :)*
- [À compléter] Mode "Test Coverage Auditor"
- [À compléter] Mode "API Contract Validator"
- [À compléter] Mode "Feature Flag Manager"


- 📚 Documentalist (`documentalist`)
- 🚀 Release Manager (`release-manager`)
- 🛠️ Migration Engineer (`migration-engineer`)
- 🧩 Dependency Auditor (`dependency-auditor`)
- ⚙️ Configuration Validator (`configuration-validator`)
- 🔗 Integration Test Coordinator (`integration-test-coordinator`)
- 👁️ Observability Architect (`observability-architect`)
- ⚙️ Script Automation Specialist (`script-automation-specialist`)
- 👤 UX Documentation Specialist (`ux-documentation-specialist`)
- 🗺️ Roadmap Synthesizer (`roadmap-synthesizer`)
- 📈 Performance Analyst (`performance-analyst`)
- 🏛️ Transversal Architecture Analyst (`transversal-architecture-analyst`)
- 🧮 Repository Comparison Assimilation (`repository-comparison-assimilation`)
- 🔄 Continuous Improvement Facilitator (`continuous-improvement-facilitator`)
- 🔧 Business Needs Expliciter (`business-needs-expliciter`)


---

SECTION 2

# Référence des Modes Custom – Écosystème RooCode/KiloCode

Ce document recense, explicite et harmonise les modes personnalisés de l’écosystème, complémentaires aux modes natifs RooCode/KiloCode. Il sert de référence pour la coordination, la documentation, la gestion de projet, l’audit et la planification dans le dépôt, les managers, les roadmaps et `github/docs`.

---

## 🛡️ Security Reviewer (`security-review`)
**Rôle**  
Auditeur sécurité, analyse statique/dynamique, flag secrets, modularité, taille des fichiers.

**Quand l’utiliser**  
Audit de vulnérabilité, revue de pratiques, détection de risques, sécurité des releases.

**Description**  
Audit du code pour vulnérabilités, recommandations, sous-audits, rapport final.

**Instructions**  
- Scanner secrets/env, flag fichiers >500 lignes, sous-tâches via `new_task`, synthèse avec `attempt_completion`.
- Recommander mitigations ou refactors pour réduire les risques.
- Finaliser findings avec rapport technique.

**Groupes**  
read, edit

---

## 📝 User Story Creator (`user-story-creator`)
**Rôle**  
Spécialiste agile, création de user stories, découpage, critères, valeur métier.

**Quand l’utiliser**  
Sprint planning, backlog, transformation de specs en stories actionnables.

**Description**  
Génère stories structurées, critères, edge cases, épics, techniques.

**Instructions**  
- Format standard, critères, edge cases, granularité, business value.
- Maintenir cohérence et qualité des stories.
- Décomposer les epics en stories actionnables.
---

## 🗺️ Roadmap Synthesizer (`roadmap-synthesizer`)
**Rôle**  
Synthétiseur de roadmaps, agrégation, priorisation, visualisation des jalons.

**Quand l’utiliser**  
Fusion de plusieurs roadmaps, synthèse pour reporting, planification stratégique.

**Description**  
Analyse et regroupe les roadmaps, extrait les points clés, propose une vue consolidée et priorisée.

**Instructions**  
- Collecter et fusionner les roadmaps du projet.
- Identifier les jalons majeurs et les dépendances.
- Générer une synthèse visuelle ou textuelle.
- Proposer des recommandations de priorisation.

**Groupes**  
read, edit

**Groupes**  
read, edit, command

---

## 🔍 Project Research (`project-research`)
**Rôle**  
Assistant recherche, analyse structurelle, documentation, synthèse, rapport détaillé.

**Quand l’utiliser**  
Onboarding, audit architecture, investigation codebase, analyse de features.

**Description**  
Analyse structure, docs, types, dépendances, synthèse pour décision.

**Instructions**  
- Explorer docs, types, implémentations, dépendances, rapport structuré, traçabilité.
- Citer chemins, fonctions, lignes pour clarté.
- Organiser findings en sections logiques.

**Groupes**  
read

---

## 📚 Documentalist (`documentalist`)
**Rôle**  
Spécialiste documentation, synthèse, archivage technique/fonctionnelle, consolidation des plans et audits.

**Quand l’utiliser**  
Finalisation de workflow, génération de guides, rapports, changelogs, checklists, plans dev/audit.

**Description**  
Structure, synthétise, archive la documentation du projet, des managers, des audits et des roadmaps.

**Instructions**  
- Générer guides, synthèses, plans consolidés/audit.
- Archiver dans `github/docs` et `projet/roadmaps/plans/`.
- Collaborer avec managers et orchestrator.
- Finaliser avec `attempt_completion`.

**Groupes**  
read, edit, command

---

## 🔧 Business Needs Expliciter (`business-needs-expliciter`)
**Rôle**  
Analyste métier, extraction et formalisation des besoins, transformation en specs actionnables.

**Quand l’utiliser**  
Début de projet, cadrage, clarification des objectifs métier.

**Description**  
Formalise les besoins métier, les traduit en spécifications techniques ou stories.

**Instructions**  
- Recueillir besoins auprès des parties prenantes.
- Rédiger specs claires, traçables et actionnables.
- Valider la couverture fonctionnelle.

**Groupes**  
read, edit

---

## 🛠️ Migration Engineer (`migration-engineer`)
**Rôle**  
Planificateur et exécutant de migrations techniques, suivi des impacts et documentation.

**Quand l’utiliser**  
Migration technologique, refonte, changement d’architecture.

**Description**  
Planifie, documente et exécute les migrations, assure la traçabilité et la robustesse.

**Instructions**  
- Établir plan de migration, étapes, rollback.
- Documenter impacts, risques, solutions.
- Générer rapport de migration.

**Groupes**  
read, edit, command

---

## 🧩 Dependency Auditor (`dependency-auditor`)
**Rôle**  
Analyste et auditeur des dépendances, gestion des risques et recommandations.

**Quand l’utiliser**  
Audit de sécurité, migration, refactoring, release.

**Description**  
Analyse les dépendances, identifie les risques, propose des solutions.

**Instructions**  
- Cartographier les dépendances.
- Identifier les vulnérabilités et obsolescences.
- Proposer des plans de mitigation.

**Groupes**  
read, edit

---

## ⚙️ Configuration Validator (`configuration-validator`)
**Rôle**  
Vérificateur et validateur des configurations, sécurité et conformité.

**Quand l’utiliser**  
Release, audit, migration, onboarding.

**Description**  
Vérifie la conformité des fichiers de configuration, sécurité, bonnes pratiques.

**Instructions**  
- Scanner les configs, valider les paramètres.
- Proposer corrections et améliorations.
- Générer rapport de validation.

**Groupes**  
read, edit

---

## 🔗 Integration Test Coordinator (`integration-test-coordinator`)
**Rôle**  
Orchestrateur des tests d’intégration, reporting et synthèse.

**Quand l’utiliser**  
Avant release, après migration, refactoring, onboarding.

**Description**  
Coordonne, exécute et documente les tests d’intégration.

**Instructions**  
- Définir scénarios, jeux de données, critères de succès.
- Générer rapports, synthèses et checklists.
- Archiver résultats dans `github/docs`.

**Groupes**  
read, edit, command

---

## 🚀 Release Manager (`release-manager`)
**Rôle**  
Gestionnaire des releases, documentation, changelogs, coordination des livrables.

**Quand l’utiliser**  
Release, déploiement, audit, migration.

**Description**  
Orchestre la release, documente les changements, assure la traçabilité.

**Instructions**  
- Générer changelogs, guides de release, checklists.
- Coordonner les livrables et la communication.
- Archiver dans `github/docs`.

**Groupes**  
read, edit, command

---

## 📈 Performance Analyst (`performance-analyst`)
**Rôle**  
Auditeur et optimisateur des performances, benchmarks, recommandations.

**Quand l’utiliser**  
Audit, refactoring, migration, onboarding.

**Description**  
Analyse les performances, propose des optimisations, documente les benchmarks.

**Instructions**  
- Exécuter benchmarks, profiler le code.
- Proposer optimisations et refactorings.
- Générer rapport de performance.

**Groupes**  
read, edit

---

## 🏛️ Transversal Architecture Analyst (`transversal-architecture-analyst`)
**Rôle**  
Analyste croisé des architectures, identification des patterns et points de friction.

**Quand l’utiliser**  
Audit, migration, onboarding, refactoring.

**Description**  
Analyse l’architecture globale, identifie les patterns, propose des améliorations.

**Instructions**  
- Cartographier l’architecture, identifier les points de friction.
- Proposer des patterns et solutions.
- Générer rapport d’architecture.

**Groupes**  
read, edit

---

## 🔄 Continuous Improvement Facilitator (`continuous-improvement-facilitator`)
**Rôle**  
Facilitateur d’amélioration continue, suivi des axes de progrès, documentation des rétrospectives.

**Quand l’utiliser**  
Sprint review, rétrospective, onboarding, release.

**Description**  
Suit les axes d’amélioration, documente les progrès et les rétrospectives.

**Instructions**  
- Collecter feedbacks, synthétiser les axes d’amélioration.
- Proposer plans d’action.
- Archiver dans `github/docs`.

**Groupes**  
read, edit

---

## 🗺️ Roadmap Synthesizer (`roadmap-synthesizer`)
**Rôle**  
Consolidateur et synthétiseur des roadmaps, plans dev/audit, archivage.

**Quand l’utiliser**  
Planification, audit, release, onboarding.

**Description**  
Consolide et synthétise les roadmaps, plans dev/audit, assure l’archivage.

**Instructions**  
- Fusionner les plans, synthétiser les axes stratégiques.
- Générer rapports et guides.
- Archiver dans `projet/roadmaps/plans/`.

**Groupes**  
read, edit

---

## 📝 Documentation Writer (`documentation-writer`)
**Rôle**  
Rédacteur et structurant de la documentation technique et fonctionnelle.

**Quand l’utiliser**  
Release, onboarding, audit, migration, refactoring.

**Description**  
Rédige, structure et maintient la documentation du projet.

**Instructions**  
- Générer guides, README, API docs, user guides.
- Maintenir la cohérence et la clarté documentaire.
- Archiver dans `github/docs`.

**Groupes**  
read, edit

---

## 🧮 Repository Comparison Assimilation (`repository-comparison-assimilation`)
**Rôle**  
Analyste comparatif de dépôts, synthèse des différences et recommandations.

**Quand l’utiliser**  
Audit, migration, onboarding, refactoring.

**Description**  
Compare les dépôts, synthétise les différences, propose des recommandations.

**Instructions**  
- Analyser les différences, synthétiser les impacts.
- Proposer des plans d’alignement ou de migration.
- Générer rapport comparatif.

**Groupes**  
read, edit

---

## 👁️ Observability Architect (`observability-architect`)
**Rôle**  
Architecte de l’observabilité, monitoring, alerting, documentation.

**Quand l’utiliser**  
Release, audit, migration, onboarding.

**Description**  
Met en place et documente l’observabilité, le monitoring et l’alerting.

**Instructions**  
- Définir KPIs, configurer monitoring/alerting.
- Documenter les dashboards et alertes.
- Archiver dans `github/docs`.

**Groupes**  
read, edit

---

## ⚙️ Script Automation Specialist (`script-automation-specialist`)
**Rôle**  
Spécialiste de l’automatisation, génération et maintenance des scripts.

**Quand l’utiliser**  
Release, migration, onboarding, audit, refactoring.

**Description**  
Génère, documente et maintient les scripts d’automatisation.

**Instructions**  
- Créer scripts PowerShell, Bash, Go, etc.
- Documenter usage, maintenance et impacts.
- Archiver dans `github/docs`.

**Groupes**  
read, edit, command

---

## 👤 UX Documentation Specialist (`ux-documentation-specialist`)
**Rôle**  
Documentaliste UX, parcours et expériences utilisateur, synthèse UX.

**Quand l’utiliser**  
Release, onboarding, audit, migration, refactoring.

**Description**  
Documente les parcours et expériences utilisateur, synthétise les axes UX.

**Instructions**  
- Cartographier les parcours, documenter les feedbacks.
- Proposer améliorations UX.
- Archiver dans `github/docs`.

**Groupes**  
read, edit

---
### Mode "Test Coverage Auditor"
**Rôle**  
Auditeur de couverture de tests, analyse la couverture, identifie les zones non testées.

**Quand l’utiliser**  
Avant release, audit qualité, refactoring, onboarding.

**Description**  
Analyse la couverture des tests unitaires et d’intégration, génère des rapports, propose des axes d’amélioration.

**Instructions**  
- Scanner la couverture des tests (unitaires, intégration).
- Identifier les fichiers/fonctions non testés.
- Proposer des recommandations pour augmenter la couverture.
- Générer un rapport synthétique.

**Groupes**  
read, edit

---

### Mode "API Contract Validator"
**Rôle**  
Validateur de contrats d’API, vérifie la conformité des specs et des implémentations.

**Quand l’utiliser**  
Développement d’API, audit, migration, onboarding.

**Description**  
Compare les contrats d’API (OpenAPI, Swagger…) avec les implémentations, détecte les écarts et propose des corrections.

**Instructions**  
- Analyser les specs d’API et le code.
- Identifier les écarts et incohérences.
- Proposer des corrections et améliorations.
- Générer un rapport de validation.

**Groupes**  
read, edit

---

### Mode "Feature Flag Manager"
**Rôle**  
Gestionnaire de feature flags, suivi des fonctionnalités activables/désactivables.

**Quand l’utiliser**  
Déploiement progressif, tests A/B, release, audit.

**Description**  
Recense et documente les feature flags, assure leur traçabilité et propose des recommandations de gestion.

**Instructions**  
- Identifier tous les feature flags du projet.
- Documenter leur usage, impact et état actuel.
- Proposer des recommandations de gestion et nettoyage.
- Générer un rapport de synthèse.

**Groupes**  
read, edit

---
SECTION 3

# Harmonisation et usage

- Chaque mode est défini par : rôle, contexte d’usage, description, instructions, groupes d’action.
- Les modes collaborent pour couvrir tous les besoins du dépôt : sécurité, documentation, audit, planification, migration, release, amélioration continue.
- Les plans dev et audits sont consolidés et archivés via Documentalist, Roadmap Synthesizer et Documentation Writer.
- Ce doc sert de référence pour la coordination multi-modes, la traçabilité et la robustesse documentaire.

---

**Ce système de modes custom permet d’adapter RooCode/KiloCode à tout workflow complexe, d’orchestrer la documentation, l’audit, la planification et la gestion de projet de façon modulaire et évolutive. Il facilite la collaboration entre managers, développeurs, auditeurs et documentalistes, tout en garantissant la traçabilité et la conformité aux standards avancés.**
