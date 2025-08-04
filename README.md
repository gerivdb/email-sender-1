# Documentation technique — Corrections Go v111

## Objectif

Ce document synthétise la démarche, les scripts, les corrections et la traçabilité de la résolution des erreurs Go dans le cadre du plan v111.

---

## Procédure de feedback utilisateur et amélioration continue (Roo Code v113)

### Objectif

Formaliser la collecte, la traçabilité et l’intégration des retours utilisateurs/personas pour renforcer la robustesse, la pertinence et l’évolutivité documentaire Roo Code.

### Étapes

1. **Collecte structurée des feedbacks**
   - Utiliser des formulaires, issues GitHub ou canaux dédiés pour centraliser les retours (bugs, suggestions, incompréhensions, besoins non couverts).
   - Catégoriser chaque feedback : correction, amélioration, documentation, UX, sécurité, etc.

2. **Traçabilité et historisation**
   - Reporter chaque feedback dans le carnet de bord projet ou dans un fichier dédié (`feedback-utilisateurs.md` ou section dédiée du README).
   - Lier chaque retour à une version, un artefact ou une phase du plan (ex : v113, rapport QA, batch, pipeline).

3. **Analyse et priorisation**
   - Évaluer l’impact et la fréquence des retours.
   - Prioriser les actions correctives ou évolutives lors des revues de roadmap ou de sprint.

4. **Intégration continue**
   - Planifier les corrections/améliorations dans la checklist-actionnable et la roadmap.
   - Documenter chaque action issue d’un feedback dans `fixes-applied.md`, `corrections-report.md` ou le changelog.
   - Mettre à jour la documentation utilisateur et technique après chaque itération.

5. **Boucle d’amélioration continue**
   - Organiser des revues croisées régulières (reviewers, QA, utilisateurs clés).
   - Intégrer les feedbacks dans les prompts, guides, scripts et modèles.
   - Archiver les feedbacks traités et documenter les axes d’amélioration dans la section auto-critique.

### Bonnes pratiques Roo

- Impliquer systématiquement les personas (développeur, contributeur, architecte, QA) dans la validation des livrables.
- Historiser tous les retours et décisions dans la documentation centrale ([AGENTS.md](AGENTS.md), [plan-dev-v113-autmatisation-doc-roo.md](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md), [checklist-actionnable.md](checklist-actionnable.md)).
- Utiliser les managers Roo (DocManager, ErrorManager, MonitoringManager) pour centraliser logs, feedbacks et métriques.
- Synchroniser la documentation après chaque phase de feedback (README, guides, rapports).
- Prévoir une section “Questions ouvertes & axes d’amélioration” dans chaque rapport ou guide.

### Références croisées

- [Guide agents IA, personas & AGILE](.github/docs/guides/agents-ia-personas-agile.md)
- [AGENTS.md](AGENTS.md)
- [plan-dev-v113-autmatisation-doc-roo.md](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
- [checklist-actionnable.md](checklist-actionnable.md)
- [fixes-applied.md](fixes-applied.md)
- [corrections-report.md](corrections-report.md)

---

---

## Scripts et livrables principaux

- **Extraction des erreurs** : `scripts/extract_errors/main.go` → `errors-extracted.json`
- **Catégorisation** : `scripts/categorize_errors/main.go` → `errors-categorized.json`
- **Listing fichiers par erreur** : `scripts/list_files_by_error/main.go` → `files-by-error-type.md`
- **Explication des causes** : `scripts/explain_error_causes/main.go` → `causes-by-error.md`
- **Propositions de corrections** : `scripts/fixes_proposals/main.go` → `fixes-proposals.md`
- **Corrections appliquées** : `fixes-applied.md`
- **Rapport synthétique** : `corrections-report.md`
- **Logs de build/tests** : `build-test-report.md`, `build-test-report.md.bak`

---

## Procédure de correction

1. **Extraction et catégorisation des erreurs**
   - Génération du log de build Go (`build-errors.log`)
   - Extraction enrichie (`errors-extracted.json`)
   - Catégorisation automatisée (`errors-categorized.json`)

2. **Listing, explication, proposition**
   - Listing des fichiers concernés (`files-by-error-type.md`)
   - Explication des causes (`causes-by-error.md`)
   - Propositions de corrections minimales (`fixes-proposals.md`)

3. **Application des corrections**
   - Exécution des commandes go get pour les dépendances manquantes
   - Correction des imports et des fichiers corrompus
   - Refactorisation des cycles d’import et des conflits de packages
   - Documentation de chaque correction dans `fixes-applied.md`

4. **Relance compilation/tests**
   - Compilation/tests relancés après chaque vague de corrections
   - Logs archivés (`build-test-report.md`, `.bak`)

5. **Reporting et traçabilité**
   - Rapport synthétique (`corrections-report.md`)
   - Synchronisation de la checklist (`checklist-actionnable.md`)
   - Mise à jour continue du carnet de bord v111

---

## Traçabilité et robustesse

- Chaque action, correction, arbitrage et incident est consigné dans le carnet de bord v111 et dans les fichiers de reporting.
- Les logs de build/tests sont archivés à chaque étape.
- La démarche est reproductible et alignée sur les standards Roo Code.

---

## Prochaines étapes

- Finaliser la correction des imports et des fichiers corrompus.
- Refactoriser les cycles d’import et les conflits de packages.
- Relancer la compilation/tests à chaque vague de corrections.
- Mettre à jour fixes-applied.md, corrections-report.md, README et la checklist actionnable.

---
## Documentation détaillée phase 3 — Implémentation Roo Patterns

### Actions réalisées et synchronisation
- Refactoring complet du pipeline de synchronisation Go : injection de dépendances, hooks, testabilité avancée.
- Ajout/complétion des scripts pour chaque pattern Roo : session, batch, fallback, synchronisation, cache, audit, monitoring.
- Génération automatisée des rapports (`corrections-report.md`, `fixes-applied.md`), synchronisation de la checklist actionnable.
- Tests unitaires avancés avec mocks pour chaque manager clé.
- Correction des imports, suppression des fichiers corrompus, résolution des cycles d’import et conflits de packages.
- Relance systématique de la compilation/tests après chaque vague de corrections.

### Risques identifiés
- Risque de non-détection d’erreur sur les hooks personnalisés : mitigé par tests unitaires et logs d’audit.
- Risque de dérive documentaire ou de fallback silencieux : monitoring renforcé, alertes automatiques.
- Risque de surcharge mémoire (batch/cache) : limitation de taille, monitoring, rollback rapide.
- Risque de documentation incomplète : validation croisée, feedback utilisateur, revue multi-reviewers.

### Hooks de reprise/rollback du BatchManager

---

### FallbackManager Roo — Pattern manager/agent documentaire

- **Objectif** : Gérer les stratégies de fallback documentaire (repli automatique, gestion d’échec, restauration d’état, extension plugins).
- **Artefacts principaux** :
  - Schéma Roo YAML : [`fallback_schema.yaml`](scripts/automatisation_doc/fallback_schema.yaml)
  - Implémentation Go : [`fallback_manager.go`](scripts/automatisation_doc/fallback_manager.go)
  - Tests unitaires : [`fallback_manager_test.go`](scripts/automatisation_doc/fallback_manager_test.go)
  - Rapport d’audit : [`fallback_manager_report.md`](scripts/automatisation_doc/fallback_manager_report.md)
  - Procédures rollback : [`fallback_manager_rollback.md`](scripts/automatisation_doc/fallback_manager_rollback.md)
- **Fonctionnalités clés** :
  - Modèle manager/agent Roo, extension dynamique via PluginInterface.
  - Gestion centralisée des erreurs (ErrorManager), testabilité avancée (mocks, concurrence).
  - Validation YAML Roo, reporting, rollback automatisé, documentation croisée, CI/CD.
- **Interfaces principales** :
  - `RegisterPlugin(PluginInterface) error`
  - `ApplyFallback(ctx context.Context, docID string, state interface{}) error`
  - `Rollback(ctx context.Context, id string) error`
  - `Report(ctx context.Context, id string) (*FallbackReport, error)`
- **Utilisation** :
  - Déclenchement automatique d’une stratégie de repli en cas d’échec documentaire.
  - Extension dynamique via plugins pour personnaliser les stratégies de fallback.
  - Restauration d’état, audit, rollback, reporting.
- **Entrées/Sorties** :
  - Entrées : fichiers YAML Roo, paramètres d’exécution, plugins, contexte d’exécution.
  - Sorties : statuts, rapports, logs, rollback.
- **Traçabilité & audit** :
  - Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
  - Documentation croisée : [`README.md`](README.md), [`AGENTS.md`](AGENTS.md:FallbackManager), [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - CI/CD : [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
- **Points d’extension** :
  - PluginInterface Roo (ajout dynamique de plugins, hooks, stratégies)
  - Validation YAML Roo, reporting, rollback, audit
  - Intégration avec les autres managers Roo (BatchManager, PipelineManager, etc.)
- **Risques & mitigation** :
  - Risque de fallback silencieux ou non déclenché : tests unitaires exhaustifs, logs d’audit, monitoring.
  - Risque de dérive documentaire : reporting, validation croisée, audit.
- **Références croisées** :
  - [`AGENTS.md`](AGENTS.md:FallbackManager,PluginInterface)
  - [`fallback_schema.yaml`](scripts/automatisation_doc/fallback_schema.yaml)
  - [`fallback_manager_report.md`](scripts/automatisation_doc/fallback_manager_report.md)
  - [`fallback_manager_rollback.md`](scripts/automatisation_doc/fallback_manager_rollback.md)
  - [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - [`README.md`](README.md)
  - [`checklist-actionnable.md`](checklist-actionnable.md)
  - [`rules.md`](.roo/rules/rules.md)
  - [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md)
  - [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)
  - [`plan-dev-v107-rules-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)

### PipelineManager Roo — Pattern manager/agent documentaire

- **Objectif** : Orchestrer les pipelines documentaires complexes (DAG, étapes séquentielles/parallèles, gestion d’erreur, extension plugins).
- **Artefacts principaux** :
  - Schéma Roo YAML : [`pipeline_schema.yaml`](scripts/automatisation_doc/pipeline_schema.yaml)
  - Implémentation Go : [`pipeline_manager.go`](scripts/automatisation_doc/pipeline_manager.go)
  - Tests unitaires : [`pipeline_manager_test.go`](scripts/automatisation_doc/pipeline_manager_test.go)
  - Rapport d’audit : [`pipeline_manager_report.md`](scripts/automatisation_doc/pipeline_manager_report.md)
  - Procédures rollback : [`pipeline_manager_rollback.md`](scripts/automatisation_doc/pipeline_manager_rollback.md)
- **Fonctionnalités clés** :
  - Support du modèle manager/agent Roo, extension dynamique via PluginInterface.
  - Gestion des erreurs centralisée, reporting détaillé, rollback automatisé.
  - Conformité Roo Code : tests, traçabilité, documentation croisée, CI/CD.
- **Risques & mitigation** :
  - Risque de deadlock sur DAG : validation YAML, tests de cycle.
  - Risque d’échec plugin : hooks d’erreur, logs, rollback.
  - Risque de dérive documentaire : reporting, validation croisée.
- **Références croisées** :
  - [`AGENTS.md`](AGENTS.md:PipelineManager)
  - [`pipeline_schema.yaml`](scripts/automatisation_doc/pipeline_schema.yaml)
  - [`pipeline_manager_report.md`](scripts/automatisation_doc/pipeline_manager_report.md)
  - [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - [`README.md`](README.md)
  - [`checklist-actionnable.md`](checklist-actionnable.md)
  - [`rules.md`](.roo/rules/rules.md)
  - [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md)
  - [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)
  - [`plan-dev-v107-rules-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
  - [`batch_manager_report.md`](scripts/automatisation_doc/batch_manager_report.md)
  - [`batch_manager_rollback.md`](scripts/automatisation_doc/batch_manager_rollback.md)
  - [`session_manager.go`](scripts/automatisation_doc/session_manager.go)
  - [`session_schema.yaml`](scripts/automatisation_doc/session_schema.yaml)
  - [`synchronisation_doc.go`](scripts/automatisation_doc/synchronisation_doc.go)
  - [`synchronisation_schema.yaml`](scripts/automatisation_doc/synchronisation_schema.yaml)
  - [`fixes-applied.md`](fixes-applied.md)
  - [`corrections-report.md`](corrections-report.md)
  - [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
  - [`plan-roadmap-actionnable.md`](plan-roadmap-actionnable.md)
  - [`architecture-automatisation-doc.md`](projet/roadmaps/plans/consolidated/architecture-automatisation-doc.md)
  - [`diagramme-automatisation-doc.mmd`](projet/roadmaps/plans/consolidated/diagramme-automatisation-doc.mmd)

---
### 🛡️ Rollback/Versionning Pipeline

#### Présentation

La procédure de rollback/versionning pipeline permet de restaurer un pipeline YAML à partir d’une sauvegarde `.bak` fiable, en cas d’erreur, de corruption ou de modification non désirée. Elle s’appuie sur le script Go [`rollback_pipeline.go`](scripts/automatisation_doc/rollback_pipeline.go), qui automatise la restauration, consigne chaque opération dans un log dédié et garantit la traçabilité Roo.

- **Nécessité** : Toujours disposer d’une sauvegarde `.bak` à jour avant toute modification critique du pipeline.
- **Traçabilité** : Chaque restauration génère un log d’opération détaillé (succès, erreurs, timestamp).

#### Procédure de restauration

1. **Vérifier la présence de la sauvegarde**
   - Le fichier `.bak` doit être généré automatiquement ou manuellement avant modification du pipeline principal.
   - Exemple : `mon_pipeline.yaml.bak` pour `mon_pipeline.yaml`.

2. **Lancer la restauration via le script Go**
   - Go natif :
     ```go
     import "scripts/automatisation_doc/rollback_pipeline.go"

     err := RestorePipeline("mon_pipeline.yaml")
     if err != nil {
         // Gestion d’erreur, consulter le log généré
     }
     ```
   - CLI :
     ```sh
     go run scripts/automatisation_doc/rollback_pipeline.go --pipeline=mon_pipeline.yaml
     ```
   - Le script restaure le pipeline à partir du `.bak`, archive l’ancien fichier, et consigne l’opération dans un log (ex : `logs/rollback-pipeline-<timestamp>.log`).

3. **Vérifier le log d’opération**
   - Consulter le log généré pour valider le succès ou diagnostiquer une erreur.
   - Exemple : `logs/rollback-pipeline-20250803-160000.log`

#### Exemples d’utilisation

- **Restauration standard** :
  ```sh
  go run scripts/automatisation_doc/rollback_pipeline.go --pipeline=mon_pipeline.yaml
  ```
- **Vérification post-restauration** :
  - Contrôler le contenu du pipeline restauré et le log associé.
  - Relancer les tests ou la validation YAML si besoin.

#### Cas limites & gestion des erreurs

- **Absence de sauvegarde `.bak`** :
  Le script échoue explicitement, logue l’erreur et propose une restauration manuelle (voir FAQ).
- **Fichier pipeline verrouillé ou corrompu** :
  L’opération est annulée, l’erreur est loguée, aucune modification destructive n’est appliquée.
- **Erreur d’écriture log** :
  Un message d’alerte est affiché, la restauration reste effective mais la traçabilité peut être partielle.

#### Critères de validation

- La restauration doit :
  - Réécrire le pipeline à l’identique de la sauvegarde `.bak`.
  - Archiver l’ancien fichier (timestamp).
  - Générer un log d’opération détaillé.
  - Remonter toute erreur de restauration ou d’écriture log.
- La procédure est validée si :
  - Le pipeline restauré est conforme au schéma YAML Roo.
  - Le log d’opération est présent et complet.
  - Les tests unitaires associés passent sans erreur.

#### Liens croisés & traçabilité Roo

- Script Go : [`rollback_pipeline.go`](scripts/automatisation_doc/rollback_pipeline.go)
- Manager pipeline : [`pipeline_manager.go`](scripts/automatisation_doc/pipeline_manager.go)
- Procédures rollback : [`pipeline_manager_rollback.md`](scripts/automatisation_doc/pipeline_manager_rollback.md)
- Schéma YAML Roo : [`pipeline_schema.yaml`](scripts/automatisation_doc/pipeline_schema.yaml)
- Rapport d’audit : [`pipeline_manager_report.md`](scripts/automatisation_doc/pipeline_manager_report.md)
- Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
- Documentation centrale : [`AGENTS.md`](AGENTS.md:PipelineManager), [`README.md`](README.md), [`rules-plugins.md`](.roo/rules/rules-plugins.md)

#### FAQ & restauration manuelle

> **Que faire si la sauvegarde `.bak` est absente ou corrompue ?**
>
> - Restaurer manuellement le pipeline à partir d’une version archivée (Git, backup externe).
> - Documenter l’incident dans le log d’opération ou dans [`corrections-report.md`](corrections-report.md).
> - Recréer une sauvegarde `.bak` valide avant toute nouvelle modification.
>
> **Comment diagnostiquer une erreur de restauration ?**
>
> - Consulter le log généré pour le détail de l’erreur.
> - Vérifier les permissions d’écriture sur le répertoire pipeline et logs.
> - En cas d’échec persistant, contacter l’équipe technique ou consulter [`pipeline_manager_rollback.md`](scripts/automatisation_doc/pipeline_manager_rollback.md).
>
> **Bonnes pratiques**
>
> - Toujours valider la présence et l’intégrité de la sauvegarde `.bak` avant toute opération critique.
> - Automatiser la génération des sauvegardes et l’archivage des logs.
> - Synchroniser la documentation et la checklist-actionnable après chaque restauration.

---

### 📦 API BatchManager Roo — Documentation d’usage et artefacts

#### Présentation

Le **BatchManager Roo** orchestre les traitements batch documentaires : exécution séquentielle/parallèle de plugins, gestion centralisée des erreurs via [`ErrorManager`](AGENTS.md:ErrorManager), traçabilité complète, hooks de reporting et rollback, reporting automatisé, extension dynamique via [`PluginInterface`](AGENTS.md:PluginInterface).

- **Objectif** : Automatiser, tracer et fiabiliser les traitements batch documentaires, avec extension dynamique et reporting Roo.
- **Artefacts principaux** :
  - Implémentation Go : [`batch_manager.go`](scripts/automatisation_doc/batch_manager.go)
  - Spécification technique : [`batch_manager_spec.md`](scripts/automatisation_doc/batch_manager_spec.md)
  - Rapport d’audit : [`batch_manager_report.md`](scripts/automatisation_doc/batch_manager_report.md)
  - Procédures rollback : [`batch_manager_rollback.md`](scripts/automatisation_doc/batch_manager_rollback.md)
  - Tests unitaires Roo : [`batch_manager_test.go`](scripts/automatisation_doc/batch_manager_test.go)
- **Conventions de logs** :
  - Format : texte structuré ou JSON
  - Emplacement : `logs/batch-execution-<timestamp>.log`
  - Contenu : statuts, erreurs, plugins, hooks, métriques Roo

#### Interfaces Go principales

- `NewBatchManager(ctx context.Context, config interface{}, errorManager ErrorManagerInterface) *BatchManager`
- `Init() error`
- `Run() error`
- `Stop() error`
- `Status() string`
- `RegisterPlugin(plugin PluginInterface) error`
- **Structs** : `BatchResult`, gestion des logs, hooks, batchResults

#### Hooks, plugins et extensions

- `rollbackHooks []func() error` : hooks de rollback/versionning
- `reportingHooks []func() error` : hooks de reporting automatisé
- Plugins dynamiques via `RegisterPlugin(plugin PluginInterface)`
- **PluginInterface Roo** : extension dynamique, hooks (avant/après, OnError, RollbackHook)
- **Exemples de hooks** :
  - `OnBatchRollback(ctx, batchID, error) error`
  - `OnBatchResume(ctx, batchID, state) error`

#### Exemples d’utilisation

- **Go natif** :
  ```go
  import "scripts/automatisation_doc/batch_manager.go"

  bm := NewBatchManager(ctx, config, errorManager)
  err := bm.Init()
  if err != nil { /* gestion d’erreur */ }
  err = bm.RegisterPlugin(monPlugin)
  if err != nil { /* gestion d’erreur */ }
  err = bm.Run()
  if err != nil { /* gestion d’erreur, rollback automatique */ }
  ```
- **CLI** :
  ```sh
  go run scripts/automatisation_doc/batch_manager.go --run --report=logs/batch-execution-$(date +%Y%m%d-%H%M%S).log
  ```

#### Cas limites & gestion des erreurs

- Plugins dupliqués ou absents
- Rollback échoué ou partiel
- Batch annulé, partiel, plugin en erreur
- Absence d’ErrorManager
- Hooks retournant une erreur (non bloquant)
- Multiples batchResults, logs volumineux

#### Critères de validation

- Couverture complète par tests unitaires Roo ([`batch_manager_test.go`](scripts/automatisation_doc/batch_manager_test.go))
- Validation automatique des métriques batch ([`batch_manager_report.md`](scripts/automatisation_doc/batch_manager_report.md))
- Traçabilité des erreurs, logs, hooks, rollback
- Synchronisation avec la checklist-actionnable

#### Risques & mitigation

- Risque de rollback non déclenché : tests unitaires, logs d’audit
- Risque de dérive documentaire : validation croisée, reporting Roo
- Risque de surcharge mémoire (logs, batchResults) : troncature, monitoring

#### Liens de traçabilité Roo

- Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
- Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
- Rapport d’audit : [`batch_manager_report.md`](scripts/automatisation_doc/batch_manager_report.md)
- Procédures rollback : [`batch_manager_rollback.md`](scripts/automatisation_doc/batch_manager_rollback.md)
- Spécification technique : [`batch_manager_spec.md`](scripts/automatisation_doc/batch_manager_spec.md)
- Tests unitaires : [`batch_manager_test.go`](scripts/automatisation_doc/batch_manager_test.go)
- Documentation croisée : [`AGENTS.md`](AGENTS.md:BatchManager), [`rules-plugins.md`](.roo/rules/rules-plugins.md), [`README.md`](README.md), [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)

---


### 📦 API Pipeline Roo — Documentation d’usage et artefacts

#### Présentation et usage

L’API pipeline Roo permet d’orchestrer des pipelines documentaires complexes (DAG, séquences, parallélisme, gestion d’erreur, plugins dynamiques) via le manager [`PipelineManager`](AGENTS.md:PipelineManager).  
Elle expose des méthodes Go natives et une interface CLI pour charger, valider et exécuter des pipelines définis en YAML Roo.

- **Principales méthodes Go** :
  - `LoadPipeline(yamlPath string) error`
  - `Execute(ctx context.Context, input *PipelineInput) (*PipelineResult, error)`
  - `RegisterPlugin(plugin PluginInterface) error`
  - `Rollback(ctx context.Context, id string) error`
  - `Report(ctx context.Context, id string) (*PipelineReport, error)`

#### Artefacts générés

- **Logs d’exécution** :  
  - Format : JSON structuré  
  - Emplacement : `logs/pipeline-execution-<timestamp>.json`  
  - Contenu : statuts des étapes, erreurs, timings, métadonnées Roo  
- **Rapports Markdown** :  
  - Format : Markdown Roo  
  - Emplacement : [`scripts/automatisation_doc/pipeline_manager_report.md`](scripts/automatisation_doc/pipeline_manager_report.md)  
  - Contenu : synthèse des exécutions, erreurs, hooks, plugins actifs, conformité Roo  
- **Procédures rollback** :  
  - Emplacement : [`scripts/automatisation_doc/pipeline_manager_rollback.md`](scripts/automatisation_doc/pipeline_manager_rollback.md)  
  - Description : étapes de restauration, logs associés, points de reprise  
- **Conventions Roo** :  
  - Nommage : `pipeline-execution-<date>.json`, `pipeline_manager_report.md`  
  - Répertoires : `logs/`, `scripts/automatisation_doc/`  
  - Respect des schémas YAML Roo ([`pipeline_schema.yaml`](scripts/automatisation_doc/pipeline_schema.yaml))

#### Exemples d’appel

- **Go natif** :
  ```go
  import "scripts/automatisation_doc/pipeline_manager.go"

  err := pipelineManager.LoadPipeline("mon_pipeline.yaml")
  if err != nil { /* gestion d’erreur */ }

  result, err := pipelineManager.Execute(ctx, &PipelineInput{...})
  if err != nil { /* gestion d’erreur */ }
  // Analyse du résultat, accès aux logs et rapports
  ```

- **CLI (exemple générique)** :
  ```sh
  go run scripts/automatisation_doc/pipeline_manager.go --pipeline=mon_pipeline.yaml --report=logs/pipeline-execution-$(date +%Y%m%d-%H%M%S).json
  ```

#### Liens de traçabilité Roo

- Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
- Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
- Rapport d’audit : [`scripts/automatisation_doc/pipeline_manager_report.md`](scripts/automatisation_doc/pipeline_manager_report.md)
- Procédures rollback : [`scripts/automatisation_doc/pipeline_manager_rollback.md`](scripts/automatisation_doc/pipeline_manager_rollback.md)
- Schéma YAML Roo : [`scripts/automatisation_doc/pipeline_schema.yaml`](scripts/automatisation_doc/pipeline_schema.yaml)
- Tests unitaires : [`scripts/automatisation_doc/pipeline_manager_test.go`](scripts/automatisation_doc/pipeline_manager_test.go)
- Documentation croisée : [`AGENTS.md`](AGENTS.md:PipelineManager), [`rules-plugins.md`](.roo/rules/rules-plugins.md), [`README.md`](README.md), [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)
---

### Guide d’utilisation détaillé — PipelineManager Roo

#### 1. Chargement et exécution d’un pipeline Roo

- **Définir un pipeline YAML Roo** conforme au schéma [`pipeline_schema.yaml`](scripts/automatisation_doc/pipeline_schema.yaml).
- **Charger le pipeline** :
  - Go : `err := pipelineManager.LoadPipeline("mon_pipeline.yaml")`
  - CLI : `go run scripts/automatisation_doc/pipeline_manager.go --pipeline=mon_pipeline.yaml`
- **Exécuter le pipeline** :
  - Go : `result, err := pipelineManager.Execute(ctx, &PipelineInput{...})`
  - CLI : `go run scripts/automatisation_doc/pipeline_manager.go --pipeline=mon_pipeline.yaml --report=logs/pipeline-execution-$(date +%Y%m%d-%H%M%S).json`
- **Consulter les logs JSON** dans `logs/pipeline-execution-<timestamp>.json` et le rapport Markdown dans [`pipeline_manager_report.md`](scripts/automatisation_doc/pipeline_manager_report.md).

#### 2. Extension dynamique via plugins et hooks

- **Enregistrer un plugin Roo** :  
  Go : `err := pipelineManager.RegisterPlugin(monPlugin)`
- **Hooks supportés** :
  - `BeforeStep` : exécuté avant chaque étape
  - `AfterStep` : exécuté après chaque étape
  - `OnError` : déclenché en cas d’erreur sur une étape
- **Développer un plugin** :  
  Implémenter l’interface PluginInterface Roo (voir [`AGENTS.md`](AGENTS.md:PluginInterface)), puis enregistrer via `RegisterPlugin`.
- **Cas d’usage** : audit, validation, transformation, gestion d’erreur personnalisée.

#### 3. Gestion centralisée des erreurs et rollback

- **Toutes les erreurs** sont remontées à ErrorManager Roo pour traçabilité.
- **Rollback automatique** possible via `Rollback(ctx, id)` ou lors d’une erreur critique.
- **Rapports d’erreur et rollback** : voir [`pipeline_manager_rollback.md`](scripts/automatisation_doc/pipeline_manager_rollback.md).

#### 4. Validation Roo et conventions

- **Validation automatique** du pipeline YAML : unicité des étapes, acyclicité du DAG, conformité au schéma Roo.
- **Respect des conventions Roo Markdown** pour tous les rapports et logs.
- **Traçabilité** : chaque exécution, plugin, hook et rollback est archivé et référencé dans la documentation centrale.

---

### FAQ & Cas limites — PipelineManager Roo

- **Que faire si un plugin échoue ?**  
  L’erreur est capturée par le hook `OnError`, loggée, puis transmise à ErrorManager. Le pipeline peut être rollbacké automatiquement selon la configuration.
- **Comment valider un pipeline YAML Roo ?**  
  Utiliser la méthode `LoadPipeline` : toute erreur de schéma, de cycle ou de duplication est explicitement remontée.
- **Peut-on chaîner plusieurs plugins ou hooks ?**  
  Oui, tous les plugins enregistrés sont appelés dans l’ordre d’enregistrement pour chaque hook.
- **Comment diagnostiquer une étape bloquée ?**  
  Consulter les logs JSON détaillés : chaque étape inclut son statut, son timing, les erreurs et les hooks déclenchés.
- **Comment ajouter un type d’étape personnalisé ?**  
  Étendre PluginInterface Roo et enregistrer le plugin via `RegisterPlugin`.
- **Que se passe-t-il si le rollback échoue ?**  
  L’erreur de rollback est loggée, transmise à ErrorManager, et un rapport détaillé est généré dans [`pipeline_manager_rollback.md`](scripts/automatisation_doc/pipeline_manager_rollback.md).
- **Comment assurer la conformité Roo ?**  
  Vérifier la présence des artefacts : logs JSON, rapports Markdown, synchronisation checklist, validation YAML, documentation croisée.

---

### Changelog PipelineManager Roo

- **v1.3 (2025-08-03)**
  - Intégration complète des hooks plugins : `BeforeStep`, `AfterStep`, `OnError`
  - Gestion centralisée des erreurs via ErrorManager Roo
  - Archivage automatique des logs JSON et rapports Markdown Roo
  - Extension dynamique via PluginInterface Roo (support plugins personnalisés)
  - Validation stricte du schéma YAML Roo (unicité, acyclicité, conformité)
  - Ajout des stubs rollback/report, synchronisation checklist-actionnable
  - Couverture complète par tests d’intégration avancés

- **v1.2**
  - Support du parallélisme d’étapes, reporting détaillé, logs structurés
  - Documentation croisée, intégration CI/CD Roo

- **v1.1**
  - Première version stable, support DAG, artefacts Roo de base

---


---
### ErrorManager Roo — Pattern manager/agent documentaire

- **Objectif** : Centraliser la gestion, la validation et la journalisation structurée des erreurs dans l’écosystème Roo (dépendances, modules, CI/CD).
- **Artefacts principaux** :
  - Schéma Roo YAML : [`error_manager_schema.yaml`](scripts/automatisation_doc/error_manager_schema.yaml)
  - Spécification technique : [`error_manager_spec.md`](scripts/automatisation_doc/error_manager_spec.md)
  - Plan de tests unitaires : [`error_manager_test.md`](scripts/automatisation_doc/error_manager_test.md)
  - Rapport d’audit : [`error_manager_report.md`](scripts/automatisation_doc/error_manager_report.md)
  - Procédures rollback : [`error_manager_rollback.md`](scripts/automatisation_doc/error_manager_rollback.md)
- **Fonctionnalités clés** :
  - Modèle manager/agent Roo, extension dynamique via PluginInterface.
  - Gestion centralisée des erreurs, validation structurée, hooks, reporting, rollback, CI/CD.
  - Documentation croisée, traçabilité Roo, testabilité avancée (mocks, scénarios d’échec).
- **Interfaces principales** :
  - `ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error`
  - `CatalogError(entry ErrorEntry) error`
  - `ValidateErrorEntry(entry ErrorEntry) error`
- **Utilisation** :
  - Injection dans GoModManager, ConfigManager, etc. pour uniformiser le traitement des erreurs et assurer la traçabilité.
  - Centralisation des logs, reporting, rollback, audit.
- **Entrées/Sorties** :
  - Entrées : erreurs Go, entrées structurées (ErrorEntry), contexte d’exécution.
  - Sorties : erreurs Go standard (validation, journalisation, etc.), rapports, logs, rollback.
- **Traçabilité & audit** :
  - Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
  - Documentation croisée : [`README.md`](README.md), [`AGENTS.md`](AGENTS.md:ErrorManager), [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - CI/CD : [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
- **Points d’extension** :
  - PluginInterface Roo (ajout dynamique de hooks, stratégies de validation, reporting)
  - Validation YAML Roo, reporting, rollback, audit
  - Intégration avec les autres managers Roo (BatchManager, PipelineManager, MonitoringManager, etc.)
- **Risques & mitigation** :
  - Risque de non-détection ou de mauvaise catégorisation d’erreur : tests unitaires exhaustifs, logs d’audit, validation croisée.
  - Risque de dérive documentaire ou de reporting incomplet : reporting, audit, feedback utilisateur.
- **Références croisées** :
  - [`AGENTS.md`](AGENTS.md:ErrorManager,PluginInterface)
  - [`error_manager_schema.yaml`](scripts/automatisation_doc/error_manager_schema.yaml)
  - [`error_manager_spec.md`](scripts/automatisation_doc/error_manager_spec.md)
  - [`error_manager_test.md`](scripts/automatisation_doc/error_manager_test.md)
  - [`error_manager_report.md`](scripts/automatisation_doc/error_manager_report.md)
  - [`error_manager_rollback.md`](scripts/automatisation_doc/error_manager_rollback.md)
  - [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - [`README.md`](README.md)
  - [`checklist-actionnable.md`](checklist-actionnable.md)
  - [`rules.md`](.roo/rules/rules.md)
  - [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md)
  - [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)
  - [`plan-dev-v107-rules-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
### MonitoringManager Roo — Pattern manager/agent documentaire

- **Objectif** : Superviser et monitorer l’écosystème documentaire, collecter les métriques système/applicatives, générer des rapports et gérer les alertes.
- **Artefacts principaux** :
  - Schéma Roo YAML : [`monitoring_schema.yaml`](scripts/automatisation_doc/monitoring_schema.yaml)
  - Spécification technique : [`monitoring_manager_spec.md`](scripts/automatisation_doc/monitoring_manager_spec.md)
  - Rapport d’audit : [`monitoring_manager_report.md`](scripts/automatisation_doc/monitoring_manager_report.md)
  - Procédures rollback : [`monitoring_manager_rollback.md`](scripts/automatisation_doc/monitoring_manager_rollback.md)
- **Fonctionnalités clés** :
  - Modèle manager/agent Roo, extension dynamique via PluginInterface.
  - Collecte de métriques, surveillance continue, alertes, reporting, rollback automatisé.
  - Gestion centralisée des erreurs (ErrorManager), testabilité avancée (mocks, scénarios d’échec).
  - Validation YAML Roo, documentation croisée, CI/CD, traçabilité checklist.
- **Interfaces principales** :
  - `Initialize(ctx context.Context) error`
  - `StartMonitoring(ctx context.Context) error`
  - `StopMonitoring(ctx context.Context) error`
  - `CollectMetrics(ctx context.Context) (*SystemMetrics, error)`
  - `CheckSystemHealth(ctx context.Context) (*HealthStatus, error)`
  - `ConfigureAlerts(ctx context.Context, config *AlertConfig) error`
  - `GenerateReport(ctx context.Context, duration time.Duration) (*PerformanceReport, error)`
  - `StartOperationMonitoring(ctx context.Context, operation string) (*OperationMetrics, error)`
  - `StopOperationMonitoring(ctx context.Context, metrics *OperationMetrics) error`
  - `GetMetricsHistory(ctx context.Context, duration time.Duration) ([]*SystemMetrics, error)`
  - `HealthCheck(ctx context.Context) error`
  - `Cleanup() error`
- **Utilisation** :
  - Collecte et agrégation de métriques, génération de rapports, gestion d’alertes, suivi d’opérations critiques.
  - Extension dynamique via plugins pour enrichir la supervision.
  - Intégration CI/CD, reporting automatisé, rollback documentaire.
- **Entrées/Sorties** :
  - Entrées : contextes d’exécution, configurations d’alertes, opérations à monitorer.
  - Sorties : métriques, rapports, statuts de santé, alertes, logs.
- **Traçabilité & audit** :
  - Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
  - Documentation croisée : [`README.md`](README.md), [`AGENTS.md`](AGENTS.md:MonitoringManager), [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - CI/CD : [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
- **Points d’extension** :
  - PluginInterface Roo (ajout dynamique de plugins, hooks, stratégies)
  - Validation YAML Roo, reporting, rollback, audit
  - Intégration avec les autres managers Roo (BatchManager, PipelineManager, etc.)
- **Risques & mitigation** :
  - Risque de métriques incomplètes ou non collectées : tests unitaires exhaustifs, logs d’audit, monitoring.
  - Risque de dérive documentaire ou d’alertes non déclenchées : reporting, validation croisée, audit.
- **Références croisées** :
  - [`AGENTS.md`](AGENTS.md:MonitoringManager,PluginInterface)
  - [`monitoring_schema.yaml`](scripts/automatisation_doc/monitoring_schema.yaml)
  - [`monitoring_manager_spec.md`](scripts/automatisation_doc/monitoring_manager_spec.md)
  - [`monitoring_manager_report.md`](scripts/automatisation_doc/monitoring_manager_report.md)
  - [`monitoring_manager_rollback.md`](scripts/automatisation_doc/monitoring_manager_rollback.md)
  - [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - [`README.md`](README.md)
  - [`checklist-actionnable.md`](checklist-actionnable.md)
  - [`rules.md`](.roo/rules/rules.md)
  - [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md)
  - [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)
  - [`plan-dev-v107-rules-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
  - [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
  - [`architecture-automatisation-doc.md`](projet/roadmaps/plans/consolidated/architecture-automatisation-doc.md)
  - [`diagramme-automatisation-doc.mmd`](projet/roadmaps/plans/consolidated/diagramme-automatisation-doc.mmd)
  - [`fixes-applied.md`](fixes-applied.md)
  - [`corrections-report.md`](corrections-report.md)
  - [`plan-roadmap-actionnable.md`](plan-roadmap-actionnable.md)
- **Interfaces attendues** :
  - `RegisterPlugin(PluginInterface) error` : permet d’enregistrer dynamiquement un plugin de gestion de reprise ou de rollback.
  - Les plugins doivent implémenter les méthodes : `OnBatchResume(ctx, batchID, state) error`, `OnBatchRollback(ctx, batchID, error) error`.
- **Scénarios d’appel** :
  - Lorsqu’un batch échoue, le BatchManager déclenche le hook `OnBatchRollback` pour permettre une restauration ou une action personnalisée.
  - Lors d’une reprise après interruption, le hook `OnBatchResume` est appelé pour restaurer l’état du batch.
- **Critères de validation** :
  - Les plugins doivent être testés avec des scénarios d’échec simulés (voir batch_manager_test.go).
  - Les logs de chaque hook doivent être archivés dans le rapport batch (`batch_manager_report.md`).
  - Toute erreur non gérée doit être remontée à ErrorManager pour traçabilité.
- **Traçabilité & audit** :
  - Chaque appel de hook est tracé dans les logs d’audit (voir AuditManager).
  - Les plugins actifs et leur statut sont listés dans la documentation batch.
- **Risques & mitigation** :
  - Risque de non-déclenchement du rollback : tests unitaires obligatoires, monitoring renforcé.
  - Risque de dérive documentaire : validation croisée, feedback utilisateur.
- **Références croisées** :
  - [`AGENTS.md`](AGENTS.md:BatchManager,PluginInterface)
  - [`rules-plugins.md`](.roo/rules/rules-plugins.md)
  - [`batch_manager_spec.md`](scripts/automatisation_doc/batch_manager_spec.md)
  - [`batch_manager_report.md`](scripts/automatisation_doc/batch_manager_report.md)
  - [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
### Rollback & restauration
- Sauvegarde automatique des états intermédiaires (scripts, configs, rapports).
- Script de restauration documentaire (`gen_rollback_report.go`), points de restauration intermédiaires.
- Commit Git avant toute modification critique.

### Axes d’amélioration & auto-critique
- Automatiser la revue croisée via agent LLM, ajouter dashboards de suivi.
- Factoriser les patterns communs pour limiter la complexité de maintenance.
- Ajouter des tests de résilience sur les scénarios d’échec backend/cache.
- Intégrer un retour utilisateur sur la lisibilité des guides et la pertinence des checklists.

### Questions ouvertes & ambiguïtés
- Faut-il supporter le cache distribué dès la V1 ?
- Les plugins d’extension doivent-ils pouvoir invalider globalement ?
- Les artefacts archivés doivent-ils inclure les logs bruts ou uniquement les rapports synthétiques ?
- Faut-il prévoir une validation automatisée LLM pour la documentation ?

*Voir la roadmap détaillée et la checklist QA dans [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md:81)*

---

## 📦 API SessionManager Roo — Documentation d’usage et artefacts

### Présentation

Le **SessionManager Roo** orchestre la gestion des sessions d’automatisation documentaire : initialisation, cycle de vie, hooks d’extension, persistance typée, traçabilité stricte et extension dynamique via PluginInterface Roo. Il s’intègre nativement avec les autres managers Roo (ErrorManager, PipelineManager, etc.) et respecte les standards Roo Code (testabilité, audit, CI/CD).

- **Objectif** : Centraliser la gestion du cycle de vie des sessions, permettre l’injection de hooks et plugins de persistance, garantir la traçabilité et la testabilité.
- **Artefacts principaux** :
  - Implémentation Go : [`session_manager.go`](scripts/automatisation_doc/session_manager.go)
  - Schéma YAML Roo : [`session_schema.yaml`](scripts/automatisation_doc/session_schema.yaml)
  - Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
  - Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
  - Documentation croisée : [`AGENTS.md`](AGENTS.md:SessionManager), [`rules-plugins.md`](.roo/rules/rules-plugins.md)

### Interfaces principales

- `SessionManagerInterface` :  
  - `Init(ctx context.Context, config SessionConfig) error`
  - `Start(ctx context.Context) error`
  - `End(ctx context.Context) error`
  - `RegisterHook(hook SessionHook)`
- `SessionManager` :  
  - `RegisterPersistenceHook(hookType PersistenceHookType, hook SessionHook)`
  - `RegisterPersistencePlugin(plugin SessionPersistencePlugin)`
  - `UnregisterPersistencePlugin(name string) bool`
  - `ListPersistencePlugins() []SessionPersistencePlugin`

#### Structures et types

- `SessionConfig` : configuration de session (ID, métadonnées…)
- `SessionHook` : fonction Go appelée sur événement session
- `SessionEvent` : événement typé ("start", "end", "before_persist", etc.)
- `PersistenceEngine` : interface d’abstraction de la persistance (mockable)
- `SessionPersistencePlugin` : plugin Roo typé pour hooks de persistance

### Exemples d’utilisation Go

```go
import "scripts/automatisation_doc/session_manager.go"

config := SessionConfig{SessionID: "sess-001"}
sm := NewSessionManager(config, myPersistenceEngine)

// Ajout d’un hook d’extension
sm.RegisterHook(func(event SessionEvent) error {
    if event.Type == "start" { /* ... */ }
    return nil
})

// Ajout d’un plugin de persistance Roo
sm.RegisterPersistencePlugin(myPersistencePlugin)

// Démarrage du cycle de vie
_ = sm.Init(ctx, config)
_ = sm.Start(ctx)
_ = sm.End(ctx)
```

### Schéma YAML Roo (exemple simplifié)

```yaml
session:
  id: "sess-001"
  metadata:
    user: "alice"
    started_at: "2025-08-03T15:00:00Z"
  options:
    persist: true
    plugins:
      - name: "audit-persist"
        type: "BeforePersistHook"
        config:
          level: "full"
```

### Conventions d’extension PluginInterface

- **Hooks typés** :  
  - `BeforePersistHook`, `AfterPersistHook`, `OnPersistErrorHook` (voir [`PersistenceHookType`](scripts/automatisation_doc/session_manager.go:61))
- **Plugins dynamiques** :  
  - Implémentent [`SessionPersistencePlugin`](scripts/automatisation_doc/session_manager.go:90)
  - Enregistrement via `RegisterPersistencePlugin`
  - Audit et retrait dynamique via `UnregisterPersistencePlugin`, `ListPersistencePlugins`
- **Testabilité** :  
  - Injection d’un mock [`PersistenceEngine`](scripts/automatisation_doc/session_manager.go:76) pour simuler succès/erreur et déclencher tous les hooks

### Usages typiques

- Orchestration de sessions documentaires avec hooks personnalisés (audit, reporting, rollback…)
- Extension dynamique via plugins Roo pour la persistance, la traçabilité ou l’intégration tierce
- Simulation de scénarios d’erreur et validation des hooks via injection de mocks
- Intégration avec ErrorManager pour la gestion centralisée des erreurs

### Cas limites couverts

- Plugins de persistance dupliqués ou absents
- Hooks Before/After/Error déclenchés selon le résultat de la persistance
- Persistance simulée si aucun moteur injecté
- Audit dynamique des plugins actifs

### Critères de validation

- Couverture complète par tests unitaires Roo (injection de mocks)
- Validation automatique des hooks et plugins (audit, logs)
- Synchronisation avec la checklist-actionnable et la documentation centrale

### Liens de traçabilité Roo

- Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
- Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
- Documentation croisée : [`AGENTS.md`](AGENTS.md:SessionManager), [`rules-plugins.md`](.roo/rules/rules-plugins.md), [`README.md`](README.md), [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)

> **Pour toute extension, se référer à la convention PluginInterface Roo et à la documentation centrale.**
*Dernière mise à jour : 2025-08-02 00:47*
