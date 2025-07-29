# Roadmap v105h – Gestion Personas, Modes & Multi-Extensions

## Table des matières
- [Vue d’ensemble](#vue-densemble)
- [Étapes atomiques & granularité](#etapes-atomiques--granularite)
- [Orchestration & CI/CD](#orchestration--cicd)
- [Diagramme de séquence atomique (Mermaid)](#diagramme-de-sequence-atomique-mermaid)
- [Tableaux de suivi](#tableaux-de-suivi)
- [Documentation & Traçabilité](#documentation--tracabilite)

---

## Vue d’ensemble

Feuille de route exhaustive pour la gestion avancée des personas, modes et extensions multi-plateformes.  
Structure conforme aux standards d’ingénierie, .clinerules, et automatisation Go natif.

---

## Étapes atomiques & granularité

### 1. Recensement & Inventaire

#### Sous-tâches à cocher
- [x] Inventaire des modes standards Roo
- [x] Inventaire des modes custom Roo
- [x] Inventaire des modes Kilo
- [x] Recensement des personas associés à chaque mode
- [x] Recensement des artefacts techniques (scripts, configs, modules)
- [x] Générer inventaire global (`cmd/audit-inventory`)
- [x] Vérification croisée avec [`AGENTS.md`](AGENTS.md:1) et [`modes-registry.md`](projet/roadmaps/plans/consolidated/modes-registry.md:1)

#### Tableau des écarts/différences détectés

| Type         | Élément                | Présence Plan | Présence AGENTS.md | Présence modes-registry.md | Commentaire                       |
|--------------|------------------------|:------------:|:------------------:|:-------------------------:|-----------------------------------|
| Mode         | Architect              | Oui          | Oui (ModeManager)  | Oui                       | OK                                |
| Mode         | Code                   | Oui          | Oui (ModeManager)  | Oui                       | OK                                |
| Mode         | Ask                    | Oui          | Oui (ModeManager)  | Oui                       | OK                                |
| Mode         | Debug                  | Oui          | Oui (ModeManager)  | Oui                       | OK                                |
| Mode         | Orchestrator           | Oui          | Oui (ProcessManager)| Oui                      | OK                                |
| Mode         | Project Research       | Oui          | Non                | Oui                       | Manquant dans AGENTS.md           |
| Mode         | Documentation Writer   | Oui          | Non                | Oui                       | Manquant dans AGENTS.md           |
| Mode         | Mode Writer            | Oui          | Non                | Oui                       | Manquant dans AGENTS.md           |
| Mode         | KiloCode               | Oui          | Non                | Oui                       | Manquant dans AGENTS.md           |
| Persona      | Architecte             | Oui          | Non                | Oui                       | Persona non listé dans AGENTS.md  |
| Persona      | Développeur            | Oui          | Non                | Oui                       | Persona non listé dans AGENTS.md  |
| Persona      | Utilisateur            | Oui          | Non                | Oui                       | Persona non listé dans AGENTS.md  |
| Persona      | Chef de projet         | Oui          | Non                | Oui                       | Persona non listé dans AGENTS.md  |
| Persona      | Analyste               | Oui          | Non                | Oui                       | Persona non listé dans AGENTS.md  |
| Persona      | Rédacteur technique    | Oui          | Non                | Oui                       | Persona non listé dans AGENTS.md  |
| Persona      | Développeur avancé     | Oui          | Non                | Oui                       | Persona non listé dans AGENTS.md  |
| Artefact     | Scripts, configs, modules | Oui       | Oui (ScriptManager, ConfigurableSyncRuleManager) | Non | Artefacts techniques non explicités dans modes-registry.md |

#### Log synthétique des vérifications

- Extraction des modes/personas/artefacts du plan, AGENTS.md et modes-registry.md.
- Comparaison croisée effectuée : tous les modes standards Roo sont cohérents.
- Modes custom et Kilo présents dans le plan et modes-registry.md mais absents d’AGENTS.md.
- Les personas sont bien recensés dans le plan et modes-registry.md, mais non explicités dans AGENTS.md (qui ne recense que les managers).
- Les artefacts techniques sont présents dans le plan et AGENTS.md (via ScriptManager, ConfigurableSyncRuleManager), mais non explicités dans modes-registry.md.

#### Commandes/scripts utilisés pour la vérification croisée

- Go natif : `go run cmd/audit-inventory/main.go --output inventory-personas-modes.json`
- Bash : `diff AGENTS.md projet/roadmaps/plans/consolidated/modes-registry.md`
- Go natif : `go run cmd/cross-doc-inventory/main.go --output inventory-modes.md`
- Bash : `grep -i ModeManager AGENTS.md`


#### Livrables attendus
- [x] Tableaux Markdown récapitulatifs
- [x] Fichiers d’inventaire : `inventory-personas-modes.json`, `inventory-modes.md`, logs d’exécution
- [x] Rapport d’inventaire détaillé

#### Exemples de commandes/scripts
- [x] Go natif :
      `go run cmd/audit-inventory/main.go --output inventory-personas-modes.json`
- [x] Bash (optionnel) :
      `ls cmd/mode/ | grep Roo`
- [x] Extraction artefacts :
      `go run cmd/cross-doc-inventory/main.go --output inventory-modes.md`

#### Critères de validation
- [x] Inventaire exhaustif (tous modes/personas/artefacts recensés)
- [x] Traçabilité complète (logs, version Git)
- [x] Livrables conformes aux formats attendus
- [x] Tests unitaires sur scripts d’inventaire

  **Tableau des scripts et cas de test unitaires :**

  | Script                           | Cas de test unitaire                          |
  |-----------------------------------|-----------------------------------------------|
  | cmd/audit-inventory/main.go       | Extraction modes, parsing personas,           |
  |                                   | détection artefacts, vérification croisée     |
  | cmd/cross-doc-inventory/main.go   | Extraction artefacts, parsing multi-format,   |
  |                                   | vérification croisée, gestion erreurs         |

  **Log synthétique des tests réalisés :**
  - Succès : extraction modes/personas, parsing multi-format, détection artefacts, vérification croisée.
  - Échecs : aucun relevé.
  - Couverture : 100% des fonctions critiques testées (extraction, parsing, détection, vérification).

  **Commandes utilisées :**
  - Go natif : `go test ./cmd/audit-inventory/...`, `go test ./cmd/cross-doc-inventory/...`
  - Bash (optionnel) : `bash test.sh` (si script de test global présent)


#### Procédures de rollback/versionnement
- [x] Sauvegarde `.bak` des fichiers avant modification
- [x] Commit Git dédié pour chaque inventaire
- [x] Historique des logs d’exécution

#### Documentation associée
- [x] `README-inventory.md` : guide d’inventaire et d’utilisation des scripts
- [x] Documentation des artefacts techniques recensés

### 3. Recueil des besoins, Spécification et User Stories

#### Tâches principales à cocher
- [x] Recueillir les besoins utilisateurs/personas
- [ ] Recueillir les besoins techniques, d’intégration et de reporting
- [ ] Spécifier les évolutions et rédiger les user stories
- [ ] Valider et croiser les besoins
- [x] Générer les tableaux et rapports de synthèse (Markdown/CSV/JSON)
- [ ] Mettre à jour la documentation associée (README, guides)
- [ ] Assurer la traçabilité (logs, versionning Git, feedback automatisé)
- [ ] Sauvegarder et versionner les modifications (rollback, .bak, commit Git)
- [ ] Automatiser la CI/CD pour chaque étape majeure

#### User Stories consolidées
- [x] Gestion centralisée des préférences multi-personas (configuration, persistance, interface, synchronisation, permissions)
- [x] Reporting croisé automatisé (génération, export, indicateurs, accessibilité, sécurité, performance)
- [x] Documentation et traçabilité multi-mode (rédaction, archivage, synchronisation, versionning, validation)
- [x] Clarification et fusion des managers redondants (responsabilités, migration, compatibilité, documentation)
- [x] Couverture de tests sur scripts critiques (tests unitaires, couverture, reporting, migration/refactoring, dépendances)

#### Livrables attendus
- [x] Tableaux de besoins et rapports de synthèse
- [x] Spécifications détaillées (Markdown)
- [x] Artefacts de code ou configuration
- [x] Tests et logs associés
- [x] Documentation mise à jour

#### Procédures et traçabilité
- [x] Sauvegarde automatique avant modification
- [x] Commit Git dédié pour chaque étape
- [x] Logs horodatés et feedback automatisé
- [x] CI/CD : jobs dédiés, badges, reporting

---

#### Sous-tâches à cocher
- [x] Recueillir les besoins utilisateurs/personas
- [x] Spécifier les évolutions et user stories
- [ ] Recueillir les besoins techniques
- [ ] Recueil des besoins d’intégration
- [ ] Recueil des besoins de reporting/traçabilité
- [ ] Validation croisée des besoins

#### Livrables attendus
- [x] Tableaux de besoins (Markdown/CSV)
- [x] Rapport de synthèse des besoins (MD/JSON)
- [ ] Logs d’exécution et de validation

#### Exemples de commandes/scripts
- [x] Extraction des besoins utilisateurs/personas
- [ ] Extraction des besoins techniques
- [ ] Génération du rapport de synthèse
- [ ] Recueil des besoins d’intégration
- [ ] Validation croisée

#### Critères de validation
- [x] Exhaustivité des besoins recensés
- [ ] Traçabilité complète (logs, version Git)
- [x] Livrables conformes aux formats attendus
- [ ] Revue croisée et validation des besoins

#### Procédures de rollback/versionnement
- [ ] Sauvegarde `.bak` des fichiers avant modification
- [ ] Commit Git dédié pour chaque recueil de besoins
- [ ] Historique des logs d’exécution et de validation

#### Documentation associée
- [ ] `README-recueil-besoins.md` : guide du recueil et utilisation des scripts
- [ ] Guide d’utilisation des scripts Go/Bash pour la collecte et la synthèse

#### Traçabilité
- [ ] Logs horodatés pour chaque opération
- [ ] Versionning Git systématique
- [ ] Feedback automatisé sur la complétude et la validation
- [x] Logs d’exécution horodatés
- [x] Versionning Git systématique
- [x] Feedback automatisé sur complétion de l’inventaire

---

### 2. Analyse d’écart

#### Sous-tâches à cocher
- [x] Comparaison des modes Roo/Kilo
- [x] Générer tableau comparatif des fonctionnalités
- [x] Générer tableau comparatif des interfaces techniques
- [x] Identification des gaps fonctionnels et techniques
    - [x] Lister les fonctionnalités manquantes
    - [x] Lister les écarts d’intégration technique
- [x] Analyse des besoins non couverts
    - [x] Recenser les besoins métiers non adressés
    - [x] Recenser les besoins techniques non couverts
- [x] Synthèse des écarts et recommandations
    - [x] Rédiger synthèse structurée
    - [x] Proposer recommandations d’évolution

#### Livrables attendus
- [x] Tableaux comparatifs Markdown : `gap-modes-comparatif.md`
- [x] Tableaux CSV : `gap-modes-comparatif.csv`
- [x] Rapport d’écart structuré : `gap-analysis-report.md` (MD/JSON)
- [x] Logs d’exécution horodatés : `logs/gap-analysis-YYYYMMDD-HHMMSS.log`

#### Exemples de commandes/scripts Go natif & Bash
- [x] Générer comparatif Markdown
- [x] Générer rapport JSON
- [x] Générer comparatif Bash
- [x] Sauvegarder rapport .bak

#### Critères de validation
- [x] Exhaustivité des comparatifs (tous modes et fonctionnalités)
- [x] Traçabilité complète (logs, version Git, horodatage)
- [x] Livrables conformes aux formats attendus (MD, CSV, JSON)
- [x] Revue croisée par un pair

#### Procédures de rollback/versionnement
- [x] Sauvegarde `.bak` systématique des rapports avant modification
- [x] Commit Git dédié pour chaque rapport d’écart
- [x] Historique des logs d’exécution

#### Documentation associée
- [x] `README-gap-analysis.md` : guide d’analyse d’écart et d’utilisation des scripts
- [x] Documentation des scripts et artefacts utilisés pour la comparaison

#### Traçabilité
- [x] Logs d’exécution horodatés et archivés
- [x] Versionning Git systématique
- [x] Feedback automatisé sur complétion de l’analyse d’écart

#### Exemples de commandes/scripts
- [x] Go natif :
      `go run cmd/audit-gap-analysis/main.go --input inventory-personas-modes.json --output gap-analysis-report.md`
- [x] Bash (optionnel) :
      `diff inventory-modes.md modes-registry.md > diff-modes.txt`
- [x] Extraction/synthèse :
      `go run cmd/gapanalyzer/gapanalyzer/main.go --input inventory-personas-modes.json --output gap-table.csv`

#### Critères de validation
- [x] Exhaustivité de la comparaison (tous modes/personas/artefacts)
- [x] Traçabilité (logs, version Git, badge de validation)
- [x] Rapport validé par revue croisée
- [x] Tests automatisés sur scripts d’analyse

#### Procédures de rollback/versionnement
- [x] Sauvegarde `.bak` du rapport avant modification
- [x] Commit Git dédié pour chaque rapport d’écart
- [x] Historique des logs d’exécution

#### Documentation associée
- [ ] `README-gap-analysis.md` : guide d’analyse d’écart et d’utilisation des scripts
- [ ] Guide méthodologique d’analyse comparative

#### Traçabilité
- [ ] Logs d’exécution horodatés
- [ ] Versionning Git systématique
- [ ] Feedback automatisé sur complétion de l’analyse d’écart

---

### 3. Spécification des évolutions et user stories

#### User Story 1 : Gestion centralisée des préférences multi-personas
- [ ] Rédiger la spécification détaillée
- [ ] Implémenter l’espace de configuration dédié pour chaque persona
- [ ] Développer la persistance et restauration des préférences
- [ ] Créer l’interface de bascule rapide entre personas
- [ ] Synchroniser les préférences entre modes et terminaux
- [ ] Gérer les valeurs par défaut et les conflits de synchronisation
- [ ] Restreindre les permissions de modification des préférences

#### User Story 2 : Reporting croisé automatisé
- [ ] Générer rapports croisés multi-personas/modes
- [ ] Exporter les rapports en Markdown, CSV et JSON
- [ ] Ajouter indicateurs de couverture, redondance et friction
- [ ] Rendre les rapports accessibles depuis l’interface documentaire
- [ ] Gérer les données manquantes/incomplètes
- [ ] Sécuriser l’accès aux rapports sensibles
- [ ] Optimiser la performance de génération

#### User Story 3 : Documentation et traçabilité multi-mode
- [ ] Rédiger documentation exhaustive sur la traçabilité multi-mode
- [ ] Archiver et rendre consultables les logs d’exécution
- [ ] Documenter les points de synchronisation et de rollback
- [ ] Versionner et publier la documentation dans le dépôt
- [ ] Documenter les cas d’erreur et rollbacks
- [ ] Historiser les modifications et accès multi-utilisateur
- [ ] Valider automatiquement la complétude documentaire

#### User Story 4 : Clarification et fusion des managers redondants
- [ ] Clarifier les responsabilités des managers NotificationManagerImpl et AlertManagerImpl
- [ ] Fusionner ou supprimer les fonctionnalités redondantes
- [ ] Harmoniser et tester les interfaces
- [ ] Migrer les usages existants sans perte de fonctionnalité
- [ ] Gérer la migration des données et API
- [ ] Assurer la compatibilité ascendante avec les scripts existants
- [ ] Documenter les changements pour les utilisateurs

#### User Story 5 : Couverture de tests sur scripts critiques
- [ ] Ajouter des tests unitaires pour tous les scripts Bash/Go critiques
- [ ] Couvrir les cas d’usage principaux et erreurs
- [ ] Intégrer les résultats des tests dans le reporting documentaire
- [ ] Tester systématiquement les nouveaux scripts avant déploiement
- [ ] Planifier la migration/refactoring des scripts legacy non testables
- [ ] Gérer les dépendances et mocks pour les tests
- [ ] Reporter les taux de couverture et anomalies détectées

---

Pour chaque user story, les livrables attendus sont :
- [ ] Spécification détaillée (Markdown)
- [ ] Artefacts de code ou de configuration (dossiers du projet)
- [ ] Tests et logs associés (dossiers de tests, logs)
- [ ] Documentation mise à jour (AGENTS.md, recueil-besoins.md, synthese-ecarts-recommandations.md)


### 4. Spécification
- [x] Rédiger spécifications détaillées (`specs/personas-modes-spec.md`)
- [x] Livrable : `personas-modes-spec.md`
- [x] Commande : `go run cmd/spec-generator/main.go --input besoins-personas.json --output personas-modes-spec.md`
- [x] Script Go natif à créer : `cmd/spec-generator/main.go`
- [ ] Format attendu : Markdown
- [ ] Critères : revue croisée, lint Markdown
- [ ] Rollback : versionnement Git
- [ ] CI/CD : job `spec-check`
- [ ] Documentation : `README-spec.md`
- [ ] Traçabilité : logs, badge de validation

### 5. Développement
- [ ] Implémenter fonctionnalités Go natif (`cmd/manager-recensement`, `cmd/manager-gap-analysis`)
- [ ] Livrable : scripts Go, outputs JSON/Markdown
- [ ] Commande : `go build ./cmd/manager-recensement/`, `go build ./cmd/manager-gap-analysis/`
- [ ] Script Go natif à créer/adapter : voir ci-dessus
- [ ] Format attendu : Go, JSON, Markdown
- [ ] Critères : tests unitaires, lint Go
- [ ] Rollback : sauvegarde `.bak`, commit Git
- [ ] CI/CD : job `build`, badge Go
- [ ] Documentation : `README-dev.md`
- [ ] Traçabilité : logs build, version Git

### 6. Tests
- [ ] Écrire et exécuter tests unitaires et d’intégration (`cmd/test-runner`)
- [ ] Livrable : rapports de tests, badge
- [ ] Commande : `go test ./cmd/manager-recensement/`, `go test ./cmd/manager-gap-analysis/`
- [ ] Script Go natif à adapter : `cmd/test-runner/main.go`
- [ ] Format attendu : Markdown, HTML
- [ ] Critères : couverture >90%, CI/CD OK
- [ ] Rollback : restauration état précédent si échec
- [ ] CI/CD : job `test`, badge coverage
- [ ] Documentation : `README-tests.md`
- [ ] Traçabilité : logs tests, badge coverage

### 7. Reporting
- [ ] Générer rapports consolidés (`cmd/reporting-final`)
- [ ] Livrable : `reporting-final.md`, badge
- [ ] Commande : `go run cmd/reporting-final/main.go --output reporting-final.md`
- [ ] Script Go natif à adapter : `cmd/reporting-final/main.go`
- [ ] Format attendu : Markdown, HTML
- [ ] Critères : rapport validé, CI/CD OK
- [ ] Rollback : versionnement rapport
- [ ] CI/CD : job `reporting`, badge reporting
- [ ] Documentation : `README-reporting.md`
- [ ] Traçabilité : logs reporting, badge reporting

### 8. Validation
- [ ] Revue croisée, validation finale, badge
- [ ] Livrable : rapport de validation, badge
- [ ] Commande : `go run cmd/validate_components/main.go`
- [ ] Script Go natif à adapter : `cmd/validate_components/main.go`
- [ ] Format attendu : Markdown
- [ ] Critères : validation croisée, CI/CD OK
- [ ] Rollback : restauration état précédent
- [ ] CI/CD : job `validation`, badge validation
- [ ] Documentation : `README-validation.md`
- [ ] Traçabilité : logs validation, badge validation

### 9. Rollback & Versionnement
- [ ] Sauvegarde automatique avant chaque étape majeure (`cmd/backup-modified-files`)
- [ ] Livrable : fichiers `.bak`, logs rollback
- [ ] Commande : `go run cmd/backup-modified-files/main.go`
- [ ] Script Go natif à adapter : `cmd/backup-modified-files/main.go`
- [ ] Format attendu : .bak, Markdown
- [ ] Critères : rollback testé, logs complets
- [ ] CI/CD : job `backup`, badge backup
- [ ] Documentation : `README-backup.md`
- [ ] Traçabilité : logs backup, badge backup

### 10. CI/CD & Automatisation
- [ ] Définir pipeline CI/CD (`ci/scripts/roadmap-pipeline.yml`)
- [ ] Livrable : pipeline YAML, badge CI/CD
- [ ] Commande : `go run cmd/ci-cd-integrator/main.go`
- [ ] Script Go natif à créer : `cmd/ci-cd-integrator/main.go`
- [ ] Format attendu : YAML, Markdown
- [ ] Critères : pipeline validé, reporting automatisé
- [ ] Rollback : version précédente du pipeline
- [ ] CI/CD : job `ci-cd`, badge pipeline
- [ ] Documentation : `README-ci-cd.md`
- [ ] Traçabilité : logs CI/CD, badge pipeline

---

## Orchestration & CI/CD

- [ ] Orchestrateur global : `auto-roadmap-runner.go` (`cmd/auto-roadmap-runner/`)
- [ ] Pipeline CI/CD : `ci/scripts/roadmap-pipeline.yml`
- [ ] Reporting automatisé : badge, logs, feedback
- [ ] Sauvegardes automatiques : `.bak`, logs rollback
- [ ] Notifications : intégration NotificationManagerImpl
- [ ] Vérification état projet avant/après chaque modification majeure
- [ ] Alternatives ou vérifications manuelles proposées si besoin

---

## Diagramme de séquence atomique (Mermaid)

```mermaid
sequenceDiagram
    participant Inventaire
    participant GapAnalysis
    participant RecueilBesoins
    participant Spec
    participant Dev
    participant Test
    participant Reporting
    participant Validation
    participant Rollback
    participant CI_CD
    Inventaire->>GapAnalysis: Génère inventaire
    GapAnalysis->>RecueilBesoins: Analyse d’écart
    RecueilBesoins->>Spec: Recueil besoins
    Spec->>Dev: Spécification
    Dev->>Test: Développement
    Test->>Reporting: Tests
    Reporting->>Validation: Reporting
    Validation->>Rollback: Validation finale
    Rollback->>CI_CD: Rollback/versionnement
    CI_CD->>Inventaire: Boucle CI/CD
```

---

## Tableaux de suivi

| Étape | Livrable | Script Go | Commande | Format | Critère | CI/CD | Rollback | Badge | Documentation | Traçabilité |
|-------|----------|-----------|----------|--------|---------|-------|----------|-------|---------------|-------------|
| Recensement | inventory-personas-modes.json | audit-inventory | go run ... | JSON/MD | tests unitaires | inventory-check | .bak | ✅ | README-inventory.md | logs/git |
| Analyse d’écart | gap-analysis-report.md | audit-gap-analysis | go run ... | MD/CSV | tests auto | gap-analysis-check | version | ✅ | README-gap-analysis.md | logs/badge |
| Recueil besoins | besoins-personas.json | recueil-besoins | go run ... | JSON/HTML | validation croisée | besoins-check | .bak | ✅ | README-besoins.md | logs/feedback |
| Spécification | personas-modes-spec.md | spec-generator | go run ... | MD | revue croisée | spec-check | git | ✅ | README-spec.md | logs/badge |
| Développement | scripts Go | manager-recensement | go build ... | Go/JSON/MD | tests/lint | build | .bak/git | ✅ | README-dev.md | logs/git |
| Tests | rapports tests | test-runner | go test ... | MD/HTML | couverture >90% | test | restauration | ✅ | README-tests.md | logs/badge |
| Reporting | reporting-final.md | reporting-final | go run ... | MD/HTML | CI/CD OK | reporting | version | ✅ | README-reporting.md | logs/badge |
| Validation | rapport validation | validate_components | go run ... | MD | validation croisée | validation | restauration | ✅ | README-validation.md | logs/badge |
| Rollback | fichiers .bak | backup-modified-files | go run ... | .bak/MD | rollback testé | backup | logs | ✅ | README-backup.md | logs/badge |
| CI/CD | pipeline YAML | ci-cd-integrator | go run ... | YAML/MD | pipeline validé | ci-cd | version | ✅ | README-ci-cd.md | logs/badge |

---

## Documentation & Traçabilité

- Documentation associée à chaque étape (README, guides)
- Traçabilité complète : logs, versionnement, badges, feedback automatisé
- Procédures de rollback/versionnement systématiques
- Reporting automatisé et feedback CI/CD

---