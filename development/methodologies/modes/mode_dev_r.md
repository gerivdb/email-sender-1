# Mode DEV-R

## Description
Le mode DEV-R (Développement Roadmap) est un mode opérationnel dédié à l’implémentation séquentielle, fiable et automatisée des tâches définies dans la roadmap d’un projet. Il vise à fluidifier le passage d’une tâche à l’autre, à garantir la qualité par l’intégration automatique des tests, du debug, de la revue et de l’optimisation, et à s’adapter à la diversité des tâches rencontrées dans les roadmaps.

---

## Objectifs
- Implémenter les tâches de la roadmap de façon séquentielle, fiable et traçable.
- Générer, exécuter et valider automatiquement les tests associés à chaque tâche.
- Mettre à jour la roadmap après chaque tâche complétée (statut, commentaires, suggestions, liens).
- Intégrer automatiquement les modes TEST, DEBUG, REVIEW, OPTI, CHECK selon le contexte ou l’échec d’une étape.
- Optimiser le flux de développement en limitant les interruptions, les redondances et en facilitant la collaboration.

---

## Commandes principales
- `devr start` : Démarre l’implémentation séquentielle des tâches de la roadmap.
- `devr next` : Passe à la tâche suivante après validation.
- `devr test` : Lance les tests associés à la tâche courante.
- `devr debug` : Active le mode DEBUG en cas d’échec d’un test ou d’une tâche.
- `devr review` : Lance une revue qualité sur la tâche courante.
- `devr opti` : Propose des optimisations ou refactorings sur la tâche ou le code.
- `devr check` : Vérifie l’intégrité et la conformité de la tâche ou du livrable.
- `devr custom <mode>` : Permet d’intégrer dynamiquement d’autres modes selon la nature de la tâche (UI, DB, SECURE, META…).

---

## Fonctionnement général
1. **Sélection de la tâche** : Parcourt la roadmap et sélectionne la prochaine tâche à implémenter (avec possibilité de filtrer/prioriser).
2. **Implémentation** : Implémente la tâche, puis exécute les tests associés.
3. **Gestion des erreurs** : Si un test échoue, active automatiquement le mode DEBUG, puis relance les tests.
4. **Mise à jour** : Met à jour la roadmap (statut, commentaires, suggestions, liens vers commits ou MR).
5. **Validation** : Passe à la tâche suivante ou propose des améliorations/tests complémentaires.
6. **Adaptabilité** : Peut intégrer d’autres modes selon la nature de la tâche (ex : UI, DB, SECURE, OPTI, etc.).

---

## Principe d'action de l'agent DEV-R

> **Toute ligne sélectionnée dans une roadmap ou un plan est considérée comme une tâche à exécuter concrètement et immédiatement par l’agent DEV-R.**
> L’agent DEV-R agit sans commentaire superflu : il effectue l’action décrite par la ligne sélectionnée, en appliquant la logique et les outils adaptés.
> Si une information essentielle manque pour l’exécution, il la demande explicitement, puis agit dès que possible.

---

## Critères d’approfondissement et spécifications détaillées

### 1. Exemple concret du produit attendu
- **Avant** :  
  ```markdown
  | Tâche | Statut | Commentaires | Dernier commit |
  |-------|--------|--------------|---------------|
  | 1.2.3 | En cours | - | - |
  ```
- **Après passage DEV-R** :  
  ```markdown
  | Tâche | Statut     | Commentaires                        | Dernier commit |
  |-------|------------|-------------------------------------|---------------|
  | 1.2.3 | Terminé    | Tests OK, debug passé, optimisé     | abc1234       |
  | 1.2.4 | À faire    | -                                   | -             |
  ```

### 2. Format exact du document en sortie
- **Format principal** : Markdown (roadmap.md), structuré en tableau ou en liste à puces.
- **Champs obligatoires** : Identifiant de tâche, statut, commentaires, liens vers commits/MR, date de validation.
- **Champs optionnels** : Suggestions, liens vers documentation, tags de mode utilisé (TEST, DEBUG, OPTI…).
- **Possibilité d’export** : JSON ou CSV pour intégration dans d’autres outils.

### 3. Informations contextuelles sur l’environnement
- **Prérequis techniques** :  
  - Scripts PowerShell/Bash pour automatiser les commandes.
  - Accès aux outils de test, debug, CI/CD.
  - VS Code avec snippets adaptés.
- **Emplacement dans le dépôt** :  
  - Roadmaps : `projet/roadmaps/plans/consolidated/`
  - Modes : `development/methodologies/modes/`
  - Scripts : `development/tools/scripts/`
- **Conventions** :  
  - Nom des fichiers : `roadmap.md`, `mode_<nom>.md`
  - Organisation des tâches : numérotation hiérarchique (1.2.3, 2.1.1, etc.)

### 4. Workflow d’utilisation détaillé
1. Lancer `devr start` sur la roadmap cible.
2. Implémenter la tâche proposée.
3. Exécuter `devr test` pour valider l’implémentation.
4. En cas d’échec, passer automatiquement en mode DEBUG.
5. Une fois les tests validés, mettre à jour la roadmap et passer à la tâche suivante.
6. À chaque étape, possibilité d’intégrer d’autres modes selon le besoin (REVIEW, OPTI, CHECK…).

### 5. Critères de validation
- Tous les tests associés à la tâche sont passés.
- La roadmap est à jour (statut, commentaires, liens).
- Les commits sont référencés et documentés.
- Les suggestions ou améliorations sont notées.
- Les modes complémentaires ont été intégrés si nécessaire.

### 6. Bonnes pratiques et pièges à éviter
- Toujours valider les tests avant de passer à la tâche suivante.
- Documenter les corrections, suggestions et liens dans la roadmap.
- Utiliser la granularisation (mode GRAN) pour découper les tâches complexes.
- Ne pas négliger la revue qualité (mode REVIEW) même pour les petites tâches.
- Éviter de sauter des étapes (test, debug, check).

### 7. Exemples de snippets et d’automatisation
```json
{
  "Mode DEV-R": {
    "prefix": "devr",
    "body": [
      "# Mode DEV-R",
      "",
      "## Description",
      "Le mode DEV-R (Développement Roadmap) est un mode opérationnel qui se concentre sur l'implémentation des tâches définies dans la roadmap.",
      "",
      "## Fonctionnement",
      "- Implémente les tâches de la roadmap séquentiellement",
      "- Génère et exécute les tests automatiquement",
      "- Met à jour la roadmap après chaque tâche complétée",
      "- Intègre les modes TEST et DEBUG en cas d'erreurs"
    ],
    "description": "Insère le template du mode DEV-R pour la gestion de roadmap."
  }
}
```

---

## Panel d’adaptabilité pour tous types de tâches

- **Tâches de développement standard** : Implémentation, tests, debug, review, check.
- **Tâches de documentation** : Génération ou mise à jour de docs, validation de la structure, liens croisés.
- **Tâches d’intégration** : Connexion à des API, gestion de la CI/CD, déploiement automatisé.
- **Tâches UI/UX** : Prototypage, tests d’accessibilité, intégration de feedback utilisateur.
- **Tâches base de données** : Migration, seed, optimisation de requêtes, validation de schéma.
- **Tâches sécurité** : Audit, correctifs, tests de vulnérabilité, documentation des risques.
- **Tâches métaprojet** : Refactoring, harmonisation des modes, mise à jour des outils/scripts.
- **Tâches personnalisées** : Ajout de modes spécifiques selon le contexte du projet.

---

## Liens utiles et ressources associées

- [Exemples de roadmaps consolidées](../../projet/roadmaps/plans/consolidated/)
- [Scripts d’automatisation](../../development/tools/scripts/)
- [Documentation des autres modes](../modes/)
- [Bonnes pratiques de gestion de projet](../../documentation/best-practices.md)

---

> Ce mode est conçu pour s’adapter à la diversité des tâches rencontrées dans les roadmaps du projet. N’hésitez pas à enrichir cette fiche avec de nouveaux cas d’usage ou exemples concrets issus de vos propres workflows.
