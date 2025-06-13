# Prompt – Génération avancée de plan de développement (mode DEV-R, format EMAIL_SENDER_1)

MODE: DEV-R

TÂCHE: Générer un plan de développement détaillé pour la réalisation/exécution de tâches sélectionnées, au format standardisé EMAIL_SENDER_1.

> ⚠️ Le mode DEV-R est dédié à la mise en œuvre, l’implémentation, l’exécution et la livraison incrémentale de tâches existantes ou planifiées. Il n’inclut pas de refonte, migration majeure ou restructuration profonde (voir mode GRAN pour ces cas).

CONTEXTE:
@docs/guides/standards/Conventions-Nommage.md
@docs/guides/standards/Guide-Style-Codage.md
@docs/guides/augment/PROMPT_REFERENCE.md
@development/templates/hygen/plan-dev/new/new.ejs.t

SPÉCIFICATIONS:
1. Le plan doit suivre la structure et la granularité du template de référence (voir `plan-dev-v36-Orchestration-et-Parrellisation-go.md` et `new.ejs.t`).
2. Chaque phase doit être découpée en tâches atomiques, numérotées, avec sous-tâches si nécessaire.
3. Pour chaque composant à réaliser, inclure systématiquement :
   - Un script de tests unitaires dédié (ex: tests Go, tests Pester, etc.)
   - Un script ou une section de debug pour la tâche
4. Chaque tâche doit préciser :
   - Objectif
   - Entrées/sorties attendues
   - Critères de validation
   - Format de suivi (checkbox, timestamps, résultats)
5. Prévoir une section “Actions Immédiates Requises” en fin de plan.
6. Respecter la syntaxe Markdown et la présentation visuelle du template.

FORMAT ATTENDU (exemple) :

# Plan de Développement (DEV-R) : [Titre du module]

## Réalisation/Exécution – EMAIL SENDER 1

**Date de création :** [YYYY-MM-DD]
**Version :** vX.X
**Objectif :** [Résumé objectif]
**Dernière mise à jour :** [YYYY-MM-DD]

**État d'avancement :**
- Phase 1 (...) : ⬜️ 0%
...

---

## PHASE 1 : [Titre de la phase]

**Objectif :** [Description]

- [ ] **1.1** [Tâche principale]
    - [ ] **1.1.1** [Sous-tâche]
        - [ ] **1.1.1.1** Générer le script principal
        - [ ] **1.1.1.2** Générer le script de tests unitaires associé
        - [ ] **1.1.1.3** Générer le script/debug pour cette tâche
    - [ ] **1.1.2** [Sous-tâche suivante]
...

## PHASE 2 : ...

...

## Actions Immédiates Requises

1. [Action prioritaire]
2. ...

**Standards à respecter :**
- ✅ Complexité cyclomatique < 10
- ✅ Documentation minimum 20%
- ✅ Tests unitaires obligatoires pour chaque script
- ✅ Section debug pour chaque composant critique
- ✅ Respect du format Markdown et du template

> Principe directeur : *Livraison incrémentale, robustesse, et prévention des erreurs en cascade.*

---
## Différences entre DEV-R et GRAN

- **DEV-R** : Implémentation et exécution de tâches existantes ou planifiées. Focus sur la robustesse, les tests, le debug, et la livraison incrémentale. Ne pas inclure de refonte ou migration majeure.
- **GRAN** : Refonte, migration, ou restructuration profonde d’un module ou d’une architecture. Focus sur la conception, la documentation, la validation globale, et la planification de rollback.

---
Voir aussi :
- [plan-dev-v36-Orchestration-et-Parrellisation-go.md](../../projet/roadmaps/plans/consolidated/plan-dev-v36-Orchestration-et-Parrellisation-go.md)
- [new.ejs.t](../../development/templates/hygen/plan-dev/new/new.ejs.t)
- [plan-executor.instructions.md](../../instructions/plan-executor.instructions.md)
