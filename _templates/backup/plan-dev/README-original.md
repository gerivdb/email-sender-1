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
   .\development\scripts\Generate-PlanDev.ps1 -Version "{{version}}" -Title "{{title}}" -Description "{{description}}" -Phases {{phases}}
   ```

3. **Via Hygen directement** (si installé) :
   ```
   hygen plan-dev new --version {{version}} --title "{{title}}" --description "{{description}}" --phases {{phases}}
   ```

## Paramètres dynamiques

- `version` : Numéro de version du plan (ex: v24)
- `title` : Titre du plan de développement
- `description` : Description du plan (objectif principal)
- `phases` : Nombre de phases (1-6)

## Fichier généré

Le template génère un fichier Markdown dans le dossier `projet/roadmaps/plans/consolidated/` avec le nom suivant :
```plaintext
plan-dev-v{{version}}-{{title.toLowerCase().replace(/ /g, '-').replace(/[^a-z0-9\-]/g, '').slice(0,50)}}.md
```plaintext
Exemple : `plan-dev-v24-titre-du-plan.md`

## Structure du fichier généré (exemple dynamique)

```markdown
# Plan de développement v{{version}} - {{title}}

*Version 1.0 - {{date}} - Progression globale : 0%*

{{description}}

## 1. Phase 1 (Phase 1)

- [ ] **1.1** Tâche principale 1
  - [ ] **1.1.1** Sous-tâche 1.1
    - [ ] **1.1.1.1** Sous-sous-tâche 1.1.1
      - [ ] **1.1.1.1.1** Action 1.1.1.1
      ...
```plaintext
## Génération avancée

Ce template supporte l'inclusion dynamique de sous-tâches, table des matières, progression, points de vigilance, liens doc, annexes, scénarios de test, etc. via les fichiers EJS du dossier `plan-dev/` :
- `subtasks.ejs` : sous-tâches récursives
- `toc.ejs` : table des matières
- `progress.ejs` : progression globale
- `warnings.ejs` : points de vigilance
- `doclinks.ejs` : liens vers la documentation
- `annexes.ejs` : annexes
- `tests.ejs` : scénarios de test

Pour les utiliser, voir les exemples dans chaque fichier ou dans le template principal.

---

> Généré dynamiquement avec Hygen (plan-dev template)
