# Plan de développement v11 — Opérationnalisation interopérable documentation/agents

> **Références :**
> - [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer-reference.md)
> - [`AGENTS.md`](AGENTS.md)
> - [`workflows-matrix.md`](.roo/rules/workflows-matrix.md)
> - Roadmaps v107–v110 consolidées

---

## Phase 1 : Recensement et cartographie des exigences

- **Objectif** : Recenser toutes les exigences d’interopérabilité documentaire multi-agents (Roo, Kilo Code, Cline, Copilot, Gemini CLI, LLM locaux/cloud).
- **Livrables** : `exigences-interoperabilite.yaml`, `cartographie-integration.md`
- **Dépendances** : Documentation centrale, AGENTS.md, retours utilisateurs.
- **Risques** : Oubli d’un agent, exigences implicites non formalisées.
- **Outils/Agents mobilisés** : Script Go, feedback utilisateur, analyse statique.
- **Tâches** :
  - [x] Générer le script Go `recensement_exigences.go` (doublons struct Exigence supprimés, script nettoyé).
  - [ ] Exécuter `go run scripts/recensement_exigences.go --output=exigences-interoperabilite.yaml`
  - [ ] Valider la complétude via `go test scripts/recensement_exigences_test.go`
  - [ ] Documenter la procédure dans `README.md`

---

### Modifications imprévues et corrections techniques (suivi opérationnel)

- [x] Correction de conflits de merge dans plusieurs fichiers Go (`tools/build-production/build_production.go`, etc.)
- [x] Suppression de doublons de fonctions main et de packages dans de nombreux scripts Go
- [x] Nettoyage de fichiers corrompus ou incomplets (EOF, fragments, imports mal placés)
- [ ] Finalisation du nettoyage sur l’ensemble des dossiers Go :
    - [ ] Recenser tous les dossiers Go contenant des erreurs de compilation (packages multiples, EOF, imports manquants, cycles)
    - [ ] Lister les fichiers problématiques par type d’erreur (doublon de package, import manquant, EOF, cycle d’import)
    - [ ] Corriger les doublons de déclaration de package dans chaque dossier concerné
    - [ ] Supprimer ou compléter les fichiers vides ou corrompus (EOF, balises `<<`)
    - [ ] Ajouter les modules Go manquants via `go get` ou corriger les chemins d’import
    - [ ] Résoudre les cycles d’import et les imports relatifs non supportés
    - [ ] Relancer la compilation globale pour vérifier la correction des erreurs
    - [ ] Documenter les corrections apportées et les choix structurants dans le README technique
- [ ] Relance de la compilation et des tests unitaires globale (à faire)
- [ ] Vérification de la génération YAML d’exigences (à faire)
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
- Compilation Go bloquée par : conflits de fonctions `main` dans plusieurs scripts, redéclarations de structs/types, imports mal placés, types non définis, variables non utilisées, structure de projet non conforme (plusieurs scripts utilitaires dans un même dossier sans séparation de package).
- Plusieurs corrections manuelles et scans automatisés ont été nécessaires pour supprimer les doublons, corriger les packages et garantir un seul point d’entrée par dossier.

**Décisions et arbitrages** :
- Suppression/redéfinition des fonctions `main` pour garantir un seul point d’entrée par dossier Go.
- Refactorisation des dossiers : déplacement des scripts utilitaires dans des sous-dossiers dédiés si besoin.
- Correction des imports et des déclarations de types.
- Ajout d’un scan automatisé pour détecter les conflits restants.
- Documentation de l’incident et des décisions dans cette section pour assurer la traçabilité.
- Suivi : chaque étape de correction est tracée dans la checklist et la documentation technique du plan.

**Prochaines étapes** :
- Finaliser la résolution des conflits de `main` et de packages dans tous les dossiers Go concernés.
- Relancer la compilation et les tests unitaires pour valider la correction.
- Vérifier la génération et la complétude du YAML d’exigences.
- Mettre à jour la section “Incidents et arbitrages” du plan v111 à chaque évolution.
