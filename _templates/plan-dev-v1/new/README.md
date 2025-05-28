# Template Hygen — plan-dev/new (README dynamique)

Ce dossier contient le template principal pour la génération de plans de développement structurés avec Hygen.

## Utilisation

Trois méthodes principales :

1. **Script batch** :
   ```
   generate-plan-dev.bat
   ```
2. **PowerShell** :
   ```powershell
   .\development\scripts\Generate-PlanDev.ps1 -Version "{{version}}" -Title "{{title}}" -Description "{{description}}" -Phases {{phases}}
   ```
3. **Hygen** :
   ```
   hygen plan-dev new --version {{version}} --title "{{title}}" --description "{{description}}" --phases {{phases}}
   ```

## Paramètres dynamiques

- `version` : Numéro de version (ex: v24)
- `title` : Titre du plan
- `description` : Objectif principal
- `phases` : Nombre de phases (1-6)

## Fichiers du dossier

- **plan-dev.ejs.t** : Template principal générant le plan de développement.
- **prompt.js** : Script de questions pour la génération interactive.

## Structure du fichier généré (exemple)

```markdown
# Plan de développement v{{version}} - {{title}}
*Version 1.0 - 2025-05-22 - Progression globale : 0%*

{{description}}

## 1. Phase 1 (Phase 1)
- [ ] **1.1** Tâche principale 1
  - [ ] **1.1.1** Sous-tâche 1.1
    - [ ] **1.1.1.1** Sous-sous-tâche 1.1.1
      - [ ] **1.1.1.1.1** Action 1.1.1.1
      ...
```

## Personnalisation et modules EJS

Ce template s’appuie sur des modules EJS situés dans le dossier parent (`plan-dev/`) :
- `subtasks.ejs` : sous-tâches récursives
- `toc.ejs` : table des matières
- `progress.ejs` : progression globale
- `warnings.ejs` : points de vigilance
- `doclinks.ejs` : liens documentation
- `annexes.ejs` : annexes
- `tests.ejs` : scénarios de test

Pour les utiliser, voir les exemples dans chaque fichier ou dans le template principal.

## Bonnes pratiques

1. Toujours tester les scripts générés en mode simulation avant exécution réelle.
2. Sauvegarder avant toute opération destructrice.
3. Journaliser les actions.
4. Tester en environnement de développement avant production.

---

> Ce README est généré dynamiquement pour refléter la structure réelle du template et de ses générateurs.
