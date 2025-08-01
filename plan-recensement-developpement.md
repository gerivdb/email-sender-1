# Plan détaillé – Recensement & Développement (Roo-Code)

## 1. Recensement

- **Objectif** : Identifier et inventorier tous les artefacts/documentations/codes/processus existants pertinents pour la roadmap.

- **Livrables attendus** :
  - Fichier d’inventaire structuré (`.roo/config/recensement.yaml` ou `recensement.md`)
  - Rapport d’écart initial (diff entre existant et cible)

- **Exemple de script Go** : [`.roo/scripts/recensement.go`](.roo/scripts/recensement.go:1)
  - Scan récursif du repo, extraction des métadonnées, génération YAML/Markdown.

- **Format de fichier** :
  - YAML : liste structurée avec type, chemin, statut, tags, date.
  - Markdown : tableau synthétique avec liens cliquables.

- **Critères de validation** :
  - Exhaustivité (aucun artefact critique manquant)
  - Format conforme au modèle validé
  - Traçabilité (hash commit, timestamp)

- **Procédure de rollback** :
  - Restauration du dernier inventaire validé via RollbackManager

- **Intégration CI/CD** :
  - Script exécuté automatiquement à chaque PR majeure
  - Génération d’un rapport dans le pipeline

- **Documentation & traçabilité** :
  - Ajout d’un log dans `.github/docs/incidents/recensement-YYYYMMDD.md`
  - Lien vers le rapport dans la roadmap

---

## 2. Développement

- **Objectif** : Implémenter les fonctionnalités ou correctifs identifiés, en respectant les standards Roo-Code.

- **Livrables attendus** :
  - Code source modifié ou ajouté (Go/TypeScript)
  - Tests unitaires associés
  - Documentation technique mise à jour

- **Exemple de script Go** : [`.roo/scripts/dev-check.go`](.roo/scripts/dev-check.go:1)
  - Vérification automatique du respect des conventions, exécution des tests, génération d’un rapport Markdown.

- **Format de fichier** :
  - Code : `.go`, `.ts`
  - Tests : `_test.go`, `.spec.ts`
  - Documentation : `.md`

- **Critères de validation** :
  - Tous les tests passent (CI/CD)
  - Respect des conventions (lint, format)
  - Documentation à jour
  - Validation collaborative (PR review)

- **Procédure de rollback** :
  - Utilisation de RollbackManager ou revert Git sur le commit concerné

- **Intégration CI/CD** :
  - Build, test, lint, analyse de couverture, déploiement si succès
  - Génération automatique d’un rapport de build

- **Documentation & traçabilité** :
  - Mise à jour du changelog et des logs d’incident si bugfix
  - Lien vers la PR et le rapport de build dans la roadmap

---

## Diagramme Mermaid (workflow synthétique)

```mermaid
flowchart TD
    A[Recensement] --> B[Analyse d'écart]
    B --> C[Développement]
    C --> D[Tests & Validation]
    D --> E[Reporting & Documentation]
    E --> F[Rollback si échec]