# Template Hygen pour les plans de développement

Ce template permet de générer un nouveau plan de développement avec une structure standardisée.

## Utilisation

Vous pouvez utiliser ce template de trois façons :

1. **Via le script batch** (recommandé) :
   ```
   generate-plan-dev.bat
   ```
   Ce script vous guidera à travers les différentes étapes de création d'un plan de développement.

2. **Via PowerShell directement** :
   ```powershell
   .\development\scripts\Generate-PlanDev.ps1 -Version "v24" -Title "Titre du plan" -Description "Description du plan" -Phases 3
   ```

3. **Via Hygen directement** (si installé) :
   ```
   hygen plan-dev new --version v24 --title "Titre du plan" --description "Description du plan" --phases 3
   ```

## Paramètres

- `version` : Numéro de version du plan (ex: v24)
- `title` : Titre du plan de développement
- `description` : Description du plan (objectif principal)
- `phases` : Nombre de phases (1-6)

## Fichier généré

Le template génère un fichier Markdown dans le dossier `projet/roadmaps/plans/` avec le nom suivant :
```
plan-dev-{version}-{titre-en-minuscules-avec-tirets}.md
```

Exemple : `plan-dev-v24-titre-du-plan.md`

## Structure du fichier généré

Le fichier généré suit la structure standard des plans de développement du projet :

```markdown
# Plan de développement v24 - Titre du plan
*Version 1.0 - 2025-05-25 - Progression globale : 0%*

Description du plan

## 1. Phase 1 (Phase 1)

- [ ] **1.1** Tâche principale 1
  - [ ] **1.1.1** Sous-tâche 1.1
    - [ ] **1.1.1.1** Sous-sous-tâche 1.1.1
      - [ ] **1.1.1.1.1** Action 1.1.1.1
      ...
```
