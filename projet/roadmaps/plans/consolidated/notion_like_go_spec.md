# Spécification du Prototype Notion-like Go

## 1. Objectif

Fournir une interface moderne et dynamique pour la gestion des plans/tâches, avec backend Go (API REST), stockage structuré (fichiers Markdown/JSON), et front minimaliste.

## 2. Backend Go

- API RESTful :
  - `GET /plans` : liste tous les plans (lecture de `plans_harmonized.md` ou `.json`)
  - `GET /plans/{id}` : détail d’un plan
  - `POST /plans` : création d’un plan
  - `PUT /plans/{id}` : modification d’un plan
  - `DELETE /plans/{id}` : suppression d’un plan
- Stockage : fichiers Markdown/JSON dans `consolidated/`
- Synchronisation avec template-manager

## 3. Interface Web

- Front minimaliste (Go templates ou JS léger)
- Table dynamique : visualisation, édition, création/suppression de colonnes
- Planification intelligente : priorisation automatique, suggestions

## 4. Synchronisation

- Intégration avec la table harmonisée et le template-manager
- Mise à jour automatique des fichiers lors des modifications

## 5. Critères de validation

- Visualisation/édition dynamique
- Manipulation flexible des plans
- Planification intelligente

*À implémenter dans `cmd/notion-like/` (backend) et `web/` (front).*