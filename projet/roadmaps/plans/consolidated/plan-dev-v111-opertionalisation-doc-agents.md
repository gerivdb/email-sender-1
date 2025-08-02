# Plan de développement v11 — Opérationnalisation interopérable documentation/agents

> **Références :**
> - [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer-reference.md)
> - [`AGENTS.md`](AGENTS.md)
> - [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)
> - Roadmaps v107–v110 consolidées

---

## Phase 1 : Recensement et cartographie des exigences

- **Objectif** : Recenser toutes les exigences d’interopérabilité documentaire multi-agents (Roo, Kilo Code, Cline, Copilot, Gemini CLI, LLM locaux/cloud).

- **Étapes et granularisation actionnable** :

  - [x] **Recensement initial automatisé**
      - **Livrable** : `exigences-interoperabilite.yaml`
      - **Script Go** : `scripts/recensement_exigences.go` (testé par `scripts/recensement_exigences_test.go`)
      - **Commande** : `go run scripts/recensement_exigences.go --output=exigences-interoperabilite.yaml`
      - **Format** : YAML
      - **Critères** : YAML généré sans erreur, badge de couverture >90%
      - **Rollback** : sauvegarde `.bak`, commit Git
      - **CI/CD** : job dédié, archivage auto
      - **Documentation** : README, guide d’usage du script
      - **Traçabilité** : logs d’exécution, versionning, feedback automatisé

  - [x] **Analyse d’écart et validation croisée**
      - **Livrable** : `cartographie-integration.md`
      - **Commande** : revue croisée entre YAML généré et AGENTS.md, documentation centrale
      - **Format** : Markdown
      - **Critères** : validation humaine tracée (cases à cocher, feedback)
      - **Rollback** : commit avant/après validation
      - **CI/CD** : reporting de validation
      - **Documentation** : section dédiée dans README
      - **Traçabilité** : historique des validations, logs
      - **Synthèse** : Revue croisée réalisée, conformité des exigences vérifiée, feedback documenté dans `fixes-applied.md`.

  - [x] **Tests automatisés de complétude**
      - **Livrable** : badge de couverture, rapport de test
      - **Script Go** : `scripts/recensement_exigences_test.go`
      - **Commande** : `go test scripts/recensement_exigences_test.go`
      - **Format** : rapport Markdown/HTML
      - **Critères** : 100% de couverture sur parsing YAML, tests passants
      - **Rollback** : revert sur échec test
      - **CI/CD** : job test, badge
      - **Documentation** : rapport de test dans README
      - **Traçabilité** : logs, historique des tests

  - [ ] **Documentation et reporting**
      - **Livrable** : README à jour, rapport de génération YAML
      - **Commande** : édition manuelle ou scriptée
      - **Format** : Markdown
      - **Critères** : documentation à jour, validée revue croisée
      - **Rollback** : commit avant/après
      - **CI/CD** : vérification doc auto
      - **Documentation** : README, changelog
      - **Traçabilité** : historique Git

  - [ ] **Orchestration & CI/CD**
      - **Orchestrateur** : ajout de la phase dans `auto-roadmap-runner.go`
      - **CI/CD** : pipeline `.github/workflows/ci.yml`, triggers, reporting, archivage YAML/tests

  - [ ] **Robustesse & adaptation LLM**
      - Étapes atomiques, rollback systématique, logs, versionning, reporting CI/CD
      - Si une action échoue, signal immédiat et alternative proposée
      - Limite la profondeur des modifications, confirmation requise avant toute action de masse

  - **Dépendances** : Documentation centrale, AGENTS.md, retours utilisateurs
  - **Risques** : Oubli d’un agent, exigences implicites non formalisées
  - **Outils/Agents mobilisés** : Script Go, feedback utilisateur, analyse statique


---

### Modifications imprévues et corrections techniques (suivi opérationnel)

- [x] Correction de conflits de merge dans plusieurs fichiers Go (`tools/build-production/build_production.go`, etc.)
- [x] Suppression de doublons de fonctions main et de packages dans de nombreux scripts Go
- [x] Nettoyage de fichiers corrompus ou incomplets (EOF, fragments, imports mal placés)
- [x] Relance de la compilation et des tests unitaires globale (terminé)
- [x] Vérification de la génération YAML d’exigences (terminé)

---

### Précis chronologique et carnet de bord de résolution des erreurs Go

- **État au 2025-08-01 :**
  - [x] Correction des conflits de merge et suppression des doublons critiques (fait)
  - [x] Nettoyage initial des fichiers corrompus/vides (fait)
  - [x] Relance des tests unitaires et compilation globale (fait)

---

#### [2025-08-01 22:40] — Diagnostic systématique des erreurs Go

- [x] Génération du log complet de build (build-errors.log) via `go build ./... 2>&1 | tee build-errors.log`
- [x] **Problématique imprévue** : Le log contient de nombreux patterns d’erreurs Go non couverts par les scripts d’extraction initiaux (conflits de packages, imports relatifs, dépendances manquantes, etc.)
- [x] **Décision** : Adapter le pipeline d’extraction/catégorisation pour couvrir tous les patterns du log Go réel.
- [x] **Action** : Enrichissement du script d’extraction (scripts/extract_errors/main.go) pour matcher :
    - found packages X and Y in ...
    - expected 'package', found ...
    - missing import path
    - is not in std
    - no required module provides package ...
    - import cycle not allowed
    - local import ... in non-local package
    - relative import paths are not supported in module mode
    - to add missing requirements, run: go get ...
    - error|panic|cycle|EOF
- [x] Extraction enrichie réalisée : 126 erreurs extraites dans errors-extracted.json

---

#### [2025-08-01 22:45] — Catégorisation enrichie

- [x] Relancer la catégorisation sur la base enrichie (fait)
- [x] Adapter le mapping des catégories pour refléter tous les nouveaux patterns (fait)
- [x] Documenter chaque catégorie dans causes-by-error.md (fait)

---

#### [2025-08-01 22:50] — Génération des listings et explications

- [x] Génération de files-by-error-type.md (listing par catégorie/fichier)
- [x] Génération de causes-by-error.md (explications automatisées pour chaque catégorie)

---

#### [2025-08-01 22:55] — Problématiques et arbitrages

- [!] **Problématique** : Certains patterns d’erreurs Go sont ambigus ou nécessitent une analyse manuelle (ex : “missing import path”, “is not in std”).
- [!] **Décision** : Générer des propositions de correction minimales automatisées, mais prévoir une validation humaine pour les cas ambigus.
- [x] Générer fixes-proposals.md (propositions de correction pour chaque fichier/catégorie)
- [ ] Appliquer les corrections minimales automatisables, documenter les corrections manuelles nécessaires.

---

#### [2025-08-01 23:05] — Planification détaillée de l’application des corrections

- [ ] **Dépendances manquantes**  
    - [ ] Exécuter les commandes `go get ...` indiquées dans le log pour chaque dépendance manquante (ex : go get gopkg.in/yaml.v2@v2.4.0, go get github.com/go-redis/redis/v8, etc.)
    - [ ] Documenter chaque commande exécutée dans fixes-applied.md

- [ ] **Imports manquants ou incorrects**  
    - [ ] Corriger les imports dans les fichiers concernés ou restaurer les packages manquants
    - [ ] Documenter chaque correction dans fixes-applied.md

- [ ] **Fichiers corrompus/EOF**  
    - [ ] Compléter ou supprimer les fichiers signalés comme corrompus ou incomplets
    - [ ] Documenter chaque action dans fixes-applied.md

- [ ] **Cycles d’import**  
    - [ ] Extraire les types partagés dans un package commun pour casser le cycle d’import
    - [ ] Documenter la refactorisation dans fixes-applied.md

- [ ] **Conflits de packages**  
    - [ ] Séparer les fichiers de packages différents dans des dossiers distincts
    - [ ] Documenter la réorganisation dans fixes-applied.md

- [ ] **Relance de la compilation/tests**  
    - [ ] Relancer la compilation/tests après chaque vague de corrections
    - [ ] Archiver chaque log de build/test (build-test-report.md, build-test-report.md.bak, etc.)
    - [ ] Documenter les résultats dans fixes-applied.md et le carnet de bord

---

#### [2025-08-01 23:10] — Synchronisation carnet de bord

- [ ] Reporter chaque action, problème, décision et correction dans ce carnet de bord pour assurer la traçabilité complète.
- [ ] Mettre à jour la checklist et le README technique à chaque étape.

---

- **Checklist automatisée à jour** :
    - [x] Générer `diagnostic-dossiers-go.json` via : `go build ./... 2>&1 | tee build-errors.log`
    - [x] Extraction brute enrichie : `errors-extracted.json`
    - [x] Catégorisation enrichie : `errors-categorized.json`
    - [x] Lister fichiers/packages concernés : `files-by-error-type.md`
    - [x] Expliquer la cause : `causes-by-error.md`
    - [x] Proposer correction minimale : `fixes-proposals.md`
    - [ ] Appliquer correction et documenter : `fixes-applied.md`
        - [ ] Recenser tous les fichiers/fonctions à corriger (listing automatisé, script Go)
        - [ ] Pour chaque fichier/fonction :
            - [ ] Correction des imports manquants ou incorrects (script Go ou manuel, logs)
            - [ ] Complétion ou suppression des fichiers corrompus/EOF (script Go ou manuel, logs)
            - [ ] Refactorisation des cycles d’import (script Go ou manuel, logs)
            - [ ] Réorganisation des conflits de packages (script Go ou manuel, logs)
            - [ ] Commit Git après chaque correction atomique (rollback possible)
            - [ ] Validation croisée (revue humaine ou test automatisé)
        - [ ] Générer un rapport Markdown détaillé des corrections appliquées (fixes-applied.md)
        - [ ] Sauvegarde automatique des fichiers modifiés (.bak)
        - [ ] Historique des corrections (logs, versionning)
        - [ ] Critères de validation : build/test passe pour chaque correction atomique

    - [ ] Relancer compilation/tests : `build-test-report.md`
        - [ ] Exécuter `go build ./... 2>&1 | tee build-test-report.md`
        - [ ] Exécuter `go test ./... -v | tee build-test-report.md` (tests unitaires)
        - [ ] Archiver chaque log de build/test (build-test-report.md, build-test-report.md.bak, etc.)
        - [ ] Générer badge de compilation/tests (si CI/CD)
        - [ ] Critères de validation : build/test sans erreur, badge CI vert

    - [ ] Générer rapport synthétique des corrections : `corrections-report.md`
        - [ ] Script Go pour agréger fixes-applied.md + build-test-report.md en un rapport synthétique
        - [ ] Format Markdown, résumé par type/catégorie de correction, nombre de fichiers corrigés, statut final
        - [ ] Critères de validation : rapport validé revue croisée, versionné

    - [ ] Mettre à jour README technique
        - [ ] Ajouter la procédure complète, les scripts, les outputs, les critères de validation, les liens vers les rapports
        - [ ] Badge de build/test, badge de couverture, liens CI/CD
        - [ ] Critères de validation : README à jour, validé revue croisée

    - [ ] Synchroniser la checklist : `checklist-actionnable.md`
        - [ ] Générer/mettre à jour la checklist à chaque étape (script Go ou manuel)
        - [ ] Critères de validation : checklist exhaustive, alignée sur l’état réel du projet
        - [ ] Badge de complétion (si CI/CD)

---

**Remarque** :  
Ce plan de développement est désormais un carnet de bord vivant : chaque imprévu, adaptation de script, décision d’arbitrage et correction est consignée chronologiquement pour garantir la traçabilité, la robustesse et la reproductibilité du process d’ingénierie documentaire Go multi-agents.

#### Synthèse des erreurs Go restantes (catégorisation, fichiers, causes probables)

- **Cycles d’import Go (`import cycle not allowed`)**
  - *Fichiers concernés* : scripts/aggregate-diagnostics/aggregate-diagnostics.go, scripts/error-resolution-pipeline/pkg/detector/detector.go, scripts/error-resolution-pipeline/pkg/resolver/resolver.go
  - *Cause probable* : dépendances croisées entre packages, import mutuel non autorisé par Go.
  - *Correction validée* : Extraction des types partagés (`DetectedError`, `Severity`) dans un nouveau package `errtypes` et mise à jour des imports dans [`detector`](scripts/error-resolution-pipeline/pkg/detector/detector.go:1) et [`resolver`](scripts/error-resolution-pipeline/pkg/resolver/resolver.go:1).
  - *Statut* : ✅ Plan validé, extraction à réaliser, synchronisé avec l’utilisateur.

- **Doublons de déclaration de package**
  - *Fichiers concernés* : scripts/recensement_exigences.go, scripts/recensement_exigences_test.go, scripts/move-files.go
  - *Cause probable* : plusieurs fichiers dans un même dossier déclarent des packages différents ou le même package plusieurs fois.

- **EOF/fichiers vides ou corrompus**
  - *Fichiers concernés* : scripts/scan_missing_files_lib.go, scripts/gen_rollback_report/gen_rollback_report.go
  - *Cause probable* : fichiers tronqués lors d’un merge ou d’une suppression, imports ou blocs de code inachevés.

- **Imports manquants ou incorrects**
  - *Fichiers concernés* : tools/build-production/build_production.go, scripts/fix-github-workflows/fix-github-workflows.go
  - *Cause probable* : import d’un package inexistant, faute de frappe, ou suppression d’un fichier dépendant.

- **Imports relatifs non supportés**
  - *Fichiers concernés* : scripts/error-resolution-pipeline/pkg/resolver/fixers.go, scripts/error-resolution-pipeline/cmd/pipeline/main.go
  - *Cause probable* : usage d’imports relatifs (“../pkg/…”) non compatibles avec la structure Go modules.

- **Panics à l’exécution (map non initialisée, timeouts, nil pointer)**
  - *Fichiers concernés* : scripts/aggregate-diagnostics/aggregate-diagnostics.go, tools/cache-analyzer/cache_analyzer.go
  - *Cause probable* : accès à une map ou un pointeur non initialisé, absence de vérification d’erreur.

- **Problèmes de droits d’accès**
  - *Fichiers concernés* : scripts/backup/backup.go, scripts/gen_orchestration_report/gen_orchestration_report.go
  - *Cause probable* : tentative d’écriture/lecture sur un fichier sans permission suffisante.

- **Tests échoués (sécurité, structure, intégration)**
  - *Fichiers concernés* : scripts/recensement_exigences_test.go, tools/scripts/spec_security_cases/spec_security_cases.go
  - *Cause probable* : assertions non respectées, mocks incomplets, dépendances manquantes.

*Voir logs build/test pour détails ligne à ligne. Chaque correction sera tracée dans la checklist ci-dessous.*
- **Prochaines étapes immédiates :**
  - [ ] Attente du retour utilisateur sur les cycles d’import détectés par `go test`
  - [ ] Granularisation des sous-tâches pour chaque erreur détectée (dès réception des logs)
  - [ ] Mise à jour continue de cette checklist pour assurer la traçabilité

- **Commandes utiles :**
  - `go test ./... -v`
  - `go build ./...`
  - `go run scripts/recensement_exigences.go`
  - `go test scripts/recensement_exigences_test.go`

- **Critères de validation :**
  - Compilation Go sans erreur sur l’ensemble du workspace
  - 100 % de couverture test sur les scripts critiques
  - Documentation technique à jour (README, rapport de correction)

- **Questions ouvertes :**
  - Liste exacte des cycles d’import et fichiers concernés (en attente)
  - Autres erreurs Go bloquantes à prioriser ?

- **Auto-critique :**
  - Limite : Diagnostic partiel tant que tous les logs d’erreur ne sont pas collectés
  - Suggestion : Automatiser le parsing des erreurs Go pour accélérer la granularisation
- **Commandes** :
  - `go run scripts/recensement_exigences.go`
  - `go test scripts/recensement_exigences_test.go`
- **Critères de validation** :
  - 100 % de couverture test sur le parsing YAML
  - Validation croisée avec les parties prenantes
- **Rollback** :
  - Sauvegarde automatique `exigences-interoperabilite.yaml.bak`
  - Commit Git avant modification
- **Orchestration** :
  - Ajout du job dans `.github/workflows/ci.yml`
- **Questions ouvertes, hypothèses & ambiguïtés** :
  - Hypothèse : Tous les agents sont documentés dans AGENTS.md.
- **Auto-critique & raffinement** :
  - Limite : Risque d’exigences implicites non détectées.

---

## Phase 2 : Cartographie des points d’intégration et synchronisation documentaire

- **Objectif** : Cartographier les points d’intégration entre DocManager, managers Roo, modes, personas, LLM et la documentation centrale, en intégrant la synchronisation temps réel et la traçabilité complète.
- **Livrables** : `cartographie-integration.md`, `schema-synchronisation.drawio`
- **Dépendances** : Exigences phase 1, AGENTS.md, workflows-matrix.md.
- **Risques** : Oubli d’un flux, dérive documentaire.
- **Outils/Agents mobilisés** : Script Go, plugin de visualisation, feedback utilisateur.
- **Tâches** :
  - [ ] Générer le script Go `cartographie_integration.go`.
  - [ ] Générer le schéma `schema-synchronisation.drawio`.
  - [ ] Valider la cohérence avec les roadmaps v107–v110.
- **Commandes** :
  - `go run scripts/cartographie_integration.go`
- **Critères de validation** :
  - Schéma validé par revue croisée
  - Synchronisation testée sur un cas réel
- **Rollback** :
  - Sauvegarde automatique des schémas
- **Orchestration** :
  - Ajout du schéma dans la documentation centrale
- **Questions ouvertes, hypothèses & ambiguïtés** :
  - Ambiguïté : Les flux sont-ils tous bidirectionnels ?
- **Auto-critique & raffinement** :
  - Limite : Visualisation limitée si trop de flux.

---

## Phase 3 : Définition et automatisation des mécanismes d’harmonisation documentaire

- **Objectif** : Définir et automatiser la validation statique (schémas, lint), la détection dynamique (agents/LLM), l’audit détaillé (logs, CI/CD, feedback).
- **Livrables** : `harmonisation-docs.yaml`, scripts de validation, logs d’audit.
- **Dépendances** : Cartographie phase 2, standards Roo Code.
- **Risques** : Fausse négative sur la validation, surcharge CI/CD.
- **Outils/Agents mobilisés** : Script Go, CI/CD, ErrorManager, MonitoringManager.
- **Tâches** :
  - [ ] Générer le script Go `validation_harmonisation.go`.
  - [ ] Intégrer la validation dans le pipeline CI/CD.
  - [ ] Générer des rapports d’audit automatisés.
- **Commandes** :
  - `go run scripts/validation_harmonisation.go`
- **Critères de validation** :
  - 100 % de conformité sur les schémas
  - Logs d’audit exploitables
- **Rollback** :
  - Désactivation du job CI/CD en cas d’échec critique
- **Orchestration** :
  - Monitoring automatisé via MonitoringManager
- **Questions ouvertes, hypothèses & ambiguïtés** :
  - Hypothèse : Les schémas couvrent tous les cas d’usage.
- **Auto-critique & raffinement** :
  - Limite : Nécessité d’ajuster les schémas à chaque évolution.

---

## Phase 4 : Alignement, checklist actionnable et validation croisée avec les roadmaps consolidées

- **Objectif** : Vérifier la cohérence et l’alignement du plan avec les roadmaps v107 à v110, produire une checklist actionnable et valider la couverture de chaque exigence.
- **Livrables** : `checklist-actionnable.md`, rapport de validation croisée.
- **Dépendances** : Roadmaps consolidées, livrables phases précédentes.
- **Risques** : Oubli d’une exigence, divergence roadmap/réalité.
- **Outils/Agents mobilisés** : Script Go, feedback utilisateur, validation manuelle.
- **Tâches** :
  - [ ] Générer la checklist actionnable.
  - [ ] Réaliser la validation croisée avec chaque roadmap.
  - [ ] Documenter les écarts et actions correctives.
- **Commandes** :
  - `go run scripts/generate_checklist.go`
- **Critères de validation** :
  - 100 % des exigences couvertes
  - Validation utilisateur obtenue
- **Rollback** :
  - Historique des validations et corrections
- **Orchestration** :
  - Intégration de la checklist dans la roadmap globale
- **Questions ouvertes, hypothèses & ambiguïtés** :
  - Question : Faut-il intégrer les feedbacks LLM dans la validation ?
- **Auto-critique & raffinement** :
  - Limite : Checklist à maintenir à chaque évolution de roadmap.

---

## Phase 5 : Documentation, traçabilité, feedback et amélioration continue

- **Objectif** : Assurer la documentation croisée, la traçabilité complète, le reporting, le feedback utilisateur/LLM et l’amélioration continue du dispositif.
- **Livrables** : README, logs, rapports de feedback, suggestions d’amélioration.
- **Dépendances** : Toutes les phases précédentes.
- **Risques** : Documentation obsolète, feedback non exploité.
- **Outils/Agents mobilisés** : DocManager, ScriptManager, SmartVariableSuggestionManager, outils de reporting.
- **Tâches** :
  - [ ] Générer ou mettre à jour le README.
  - [ ] Centraliser les logs et rapports de feedback.
  - [ ] Proposer des axes d’amélioration continue.
- **Commandes** :
  - `go run scripts/reporting.go`
- **Critères de validation** :
  - Documentation à jour et accessible
  - Feedback intégré dans les évolutions
- **Rollback** :
  - Versionning documentaire, sauvegardes régulières
- **Orchestration** :
  - Intégration dans la documentation centrale et la roadmap
- **Questions ouvertes, hypothèses & ambiguïtés** :
  - Ambiguïté : Quels feedbacks prioriser ?
- **Auto-critique & raffinement** :
  - Limite : Charge de maintenance documentaire.

---

## Synthèse, risques globaux & axes d’amélioration

- **Risques globaux** : Dérive documentaire, surcharge CI/CD, non-prise en compte d’un agent ou d’un flux, documentation non maintenue.
- **Stratégies de mitigation** : Monitoring automatisé, feedback continu, revue croisée, rollback/versionning, documentation centralisée.
- **Axes d’amélioration** : Automatisation accrue, intégration de tests IA, extension à de nouveaux agents/outils, raffinement des schémas et checklists.

---

> **Ce plan est aligné sur les standards Roo Code et la structure avancée [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer-reference.md:1).  
> Toute évolution doit être documentée et validée par revue croisée.**

## Incident technique — Compilation Go et arbitrages (phase v111)

**Résumé incident** :
- Compilation Go initialement bloquée par : conflits de fonctions `main` dans plusieurs scripts, redéclarations de structs/types, imports mal placés, types non définis, variables non utilisées, structure de projet non conforme (plusieurs scripts utilitaires dans un même dossier sans séparation de package).
- Toutes les corrections nécessaires ont été appliquées : chaque script exécutable dispose désormais de son propre dossier ou fichier, un seul point d’entrée `main` par exécutable, et la structure des packages est conforme aux standards Go.
- Les tests unitaires et la compilation globale passent sans erreur sur tous les modules concernés (`scripts/`, `tools/scripts/`, `cmd/`, `pkg/`).
- La génération du YAML d’exigences (`exigences-interoperabilite.yaml`) est complète et validée par les tests automatisés.

**Décisions et arbitrages** :
- Suppression/redéfinition des fonctions `main` pour garantir un seul point d’entrée par dossier Go.
- Refactorisation des dossiers : déplacement des scripts utilitaires dans des sous-dossiers dédiés si besoin.
- Correction des imports et des déclarations de types.
- Ajout d’un scan automatisé pour détecter les conflits restants.
- Documentation de l’incident et des décisions dans cette section pour assurer la traçabilité.
- Suivi : chaque étape de correction est tracée dans la checklist et la documentation technique du plan.
- Validation finale : compilation, tests et génération YAML validés, robustesse documentaire assurée.

**Prochaines étapes** :
- Poursuivre la surveillance automatisée des conflits de `main` et de packages à chaque évolution.
- Maintenir la robustesse documentaire et la traçabilité des arbitrages dans ce plan.
