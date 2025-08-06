# Index centralisé des points d’extension & overrides Roo-Code

> Ce fichier recense tous les points d’extension (interfaces, plugins, hooks, stratégies, quality gates, overrides par mode) du projet Roo-Code.  
> Il garantit la traçabilité, la gouvernance et l’évolutivité documentaire.  
> **À maintenir à jour à chaque ajout ou modification.**

---

## 1. Points d’extension principaux

| Point d’extension | Type | Description | Liens cliquables |
|-------------------|------|-------------|------------------|
| PluginInterface | Interface | Ajout dynamique de plugins, stratégies, managers | [AGENTS.md](AGENTS.md:PluginInterface), [rules-plugins.md](.roo/rules/rules-plugins.md:1) |
| QualityGatePlugin | Interface | Extension des quality gates CI/CD | [rules-plugins.md](.roo/rules/rules-plugins.md:1), [tools-registry.md](.roo/rules/tools-registry.md:1) |
| CacheStrategy | Stratégie | Personnalisation du cache documentaire | [AGENTS.md](AGENTS.md:CacheStrategy) |
| VectorizationStrategy | Stratégie | Personnalisation de la vectorisation documentaire | [AGENTS.md](AGENTS.md:VectorizationStrategy) |
| Hooks (génériques) | Hook | Points d’injection pour validation, reporting, audit, rollback | [rules-plugins.md](.roo/rules/rules-plugins.md:1), [AGENTS.md](AGENTS.md:Hooks) |
| TestGeneratorPlugin | Plugin | Générateurs de tests personnalisés | [rules-plandev-engineer/4_testing_frameworks.xml](.roo/rules-plandev-engineer/4_testing_frameworks.xml:extension_points) |
| MockBehaviorPlugin | Plugin | Comportements de mocks personnalisés | [rules-plandev-engineer/4_testing_frameworks.xml](.roo/rules-plandev-engineer/4_testing_frameworks.xml:extension_points) |
| DataGeneratorPlugin | Plugin | Générateurs de données de test personnalisés | [rules-plandev-engineer/4_testing_frameworks.xml](.roo/rules-plandev-engineer/4_testing_frameworks.xml:extension_points) |
| RegressionDetectorPlugin | Plugin | Détecteurs de régression spécialisés | [rules-plandev-engineer/4_testing_frameworks.xml](.roo/rules-plandev-engineer/4_testing_frameworks.xml:extension_points) |
| DeploymentStrategyPlugin | Plugin | Stratégies de déploiement personnalisées | [rules-plandev-engineer/5_cicd_pipelines.xml](.roo/rules-plandev-engineer/5_cicd_pipelines.xml:extension_points) |
| MonitoringPlugin | Plugin | Intégrations de monitoring personnalisées | [rules-plandev-engineer/5_cicd_pipelines.xml](.roo/rules-plandev-engineer/5_cicd_pipelines.xml:extension_points) |
| NotificationPlugin | Plugin | Canaux de notification personnalisés | [rules-plandev-engineer/5_cicd_pipelines.xml](.roo/rules-plandev-engineer/5_cicd_pipelines.xml:extension_points) |

---

## 2. Overrides par mode Roo-Code

| Mode | Override(s) | Référence |
|------|-------------|-----------|
| PlanDev Engineer | Peut créer, lire, éditer, déplacer, supprimer tout type de fichier/dossier, sans restriction d’extension/format. Génère toujours un plan séquencé, actionnable et validé. | [rules.md](.roo/rules/rules.md:fiche-mode-plandev-engineer) |
| DevOps | Peut éditer fichiers CI/CD, scripts d’automatisation, manifestes infra. Doit documenter les procédures critiques. | [rules.md](.roo/rules/rules.md:fiche-mode-devops) |
| Architect | Peut uniquement éditer fichiers Markdown (.md). Doit proposer une todo list séquencée. | [rules.md](.roo/rules/rules.md:fiche-mode-architect) |
| Debug | Accès restreint à certains managers, centralisation via ErrorManager. | [rules.md](.roo/rules/rules.md:fiche-mode-debug) |
| Orchestrator | Coordination multi-modes, délégation via `new_task`, instructions priment sur consignes générales. | [rules-orchestration.md](.roo/rules/rules-orchestration.md:1) |

---

## 3. Points d’extension par manager (extraits AGENTS.md)

- **DocManager** : `RegisterPlugin(PluginInterface) error`
- **ExtensibleManagerType** : `RegisterPlugin`, `UnregisterPlugin`, `ListPlugins`, `GetPlugin`
- **FallbackManager, PipelineManager, MonitoringManager, ErrorManager** : Ajout dynamique de plugins, hooks, stratégies ([AGENTS.md](AGENTS.md:FallbackManager), [AGENTS.md](AGENTS.md:PipelineManager), [AGENTS.md](AGENTS.md:MonitoringManager), [AGENTS.md](AGENTS.md:ErrorManager))
- **ModeManager** : `AddEventHandler`, `TriggerEvent` (points d’extension UI/événements)
- **CleanupManager, MigrationManager** : Extension via stratégies ou plugins ([AGENTS.md](AGENTS.md:CleanupManager), [AGENTS.md](AGENTS.md:MigrationManager))

---

## 4. Utilité et gouvernance des points d’extension & overrides

Les points d’extension Roo-Code permettent :
- D’ajouter dynamiquement des fonctionnalités, plugins, stratégies ou hooks à l’écosystème documentaire.
- De personnaliser la logique métier, la validation, le reporting, la sécurité, le monitoring, le CI/CD, etc.
- De garantir l’évolutivité, la modularité et la traçabilité du projet.

La gouvernance impose :
- Validation systématique des plugins/extensions (compatibilité, sécurité, performance).
- Documentation des méthodes, impacts et procédures dans la documentation centrale.
- Mise à jour de cet index à chaque évolution.
- Respect strict des overrides par mode : chaque mode peut restreindre ou élargir les droits et points d’extension selon ses besoins, toujours documentés ici.

---

## 5. Références croisées

- [AGENTS.md](AGENTS.md:1)
- [rules-plugins.md](.roo/rules/rules-plugins.md:1)
- [rules-code.md](.roo/rules/rules-code.md:1)
- [rules-orchestration.md](.roo/rules/rules-orchestration.md:1)
- [tools-registry.md](.roo/rules/tools-registry.md:1)
- [rules.md](.roo/rules/rules.md:1)
- [workflows-matrix.md](.roo/rules/workflows-matrix.md:1)
- [rules-plandev-engineer/4_testing_frameworks.xml](.roo/rules-plandev-engineer/4_testing_frameworks.xml:extension_points)
- [rules-plandev-engineer/5_cicd_pipelines.xml](.roo/rules-plandev-engineer/5_cicd_pipelines.xml:extension_points)

---

> **Ce fichier est le pivot documentaire pour toute extension, override ou évolution de l’architecture Roo-Code.**