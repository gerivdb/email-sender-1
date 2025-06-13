# Mode DEV-R

## Description

Le mode DEV-R (Développement Roadmap) permet d’implémenter concrètement toutes les tâches d’un plan de développement : création, modification, tests, debug, documentation, automatisation, analyse, rapport, etc. Il s’appuie sur les autres modes (GRAN, TEST, REVIEW…) pour garantir la qualité, la traçabilité et l’automatisation du workflow.

---

## Objectifs

- Implémenter toutes les tâches roadmap (création, modification, suppression, analyse, documentation, automatisation…)
- Générer, exécuter et valider automatiquement les tests associés à chaque tâche.
- Mettre à jour la roadmap et la documentation après chaque tâche complétée.
- Intégrer automatiquement les modes complémentaires selon le contexte (GRAN, TEST, DEBUG, REVIEW, OPTI, CHECK…)
- Générer des rapports d’avancement et de qualité.

---

## Commandes principales

- `devr start` : Démarre l’implémentation séquentielle des tâches de la roadmap.
- `devr next` : Passe à la tâche suivante après validation.
- `devr test` : Lance les tests associés à la tâche courante.
- `devr debug` : Active le mode DEBUG en cas d’échec d’un test ou d’une tâche.
- `devr review` : Lance une revue qualité sur la tâche courante.
- `devr opti` : Propose des optimisations ou refactorings sur la tâche ou le code.
- `devr check` : Vérifie l’intégrité et la conformité de la tâche ou du livrable.
- `devr custom <mode>` : Intègre dynamiquement d’autres modes selon la nature de la tâche (UI, DB, SECURE, META…).
- `devr report` : Génère un rapport d’avancement et de qualité.
- `devr apply <tâche>` : Implémente immédiatement la tâche sélectionnée (création, modif, suppression, etc.).

---

## Fonctionnement général

1. **Sélection de la tâche** : Parcourt la roadmap et sélectionne la prochaine tâche à implémenter (filtrage/priorisation possible).
2. **Granularisation (optionnelle)** : Si la tâche est complexe, utilise le mode GRAN (`gran + N`) pour la découper en sous-tâches actionnables.
3. **Implémentation** : Réalise concrètement la tâche (création de fichier, modification de code, documentation, automatisation…).
4. **Tests** : Exécute les tests associés (`devr test`). En cas d’échec, active le mode DEBUG.
5. **Revue et validation** : Lance une revue qualité (`devr review`), propose des optimisations (`devr opti`), vérifie la conformité (`devr check`).
6. **Mise à jour** : Met à jour la roadmap, la documentation, les changelogs, les liens vers commits/MR.
7. **Rapport** : Génère un rapport d’avancement et de qualité (`devr report`).
8. **Passage à la tâche suivante** : Passe à la tâche suivante ou propose des actions complémentaires.

---

## Exemples d’utilisation concrète

### Exemple 1 : Création d’une veille technique régulière

- **Entrée (roadmap)** :
  - [ ] Mettre en place une veille technique régulière (analyse des besoins d’harmonisation, retours d’expérience, nouvelles pratiques) pour chaque mode et pour le Mode Manager.
- **Action DEV-R** :
  - Crée un fichier ou tableau partagé `veille_technique.md` dans le dossier du projet.
  - Ajoute une structure de suivi : date, source, résumé, impact, responsable.
  - Met à jour la roadmap avec le lien vers le fichier et le statut.

### Exemple 2 : Modification ou harmonisation d’un mode

- **Entrée (roadmap)** :
  - [ ] Identifier, documenter et prioriser les changements nécessaires : ajout, modification, suppression de modes, adaptation du Mode Manager, évolution des workflows.
- **Action DEV-R** :
  - Analyse les besoins (lecture des retours, veille, etc.).
  - Modifie les fichiers concernés dans `development/methodologies/modes/`.
  - Met à jour la documentation et le changelog.
  - Ajoute les liens vers les commits/MR dans la roadmap.

### Exemple 3 : Automatisation ou génération de snippets

- **Entrée (roadmap)** :
  - [ ] Mettre à jour les snippets VS Code et les scripts d’automatisation si besoin.
- **Action DEV-R** :
  - Modifie ou crée les snippets dans `.vscode/snippets/`.
  - Met à jour les scripts dans `development/tools/scripts/`.
  - Exécute les tests d’intégrité.
  - Met à jour la roadmap et la documentation.

---

## Format attendu des tâches et livrables

- **Entrée** : Tâche en Markdown (checklist, tableau, ou liste à puces)
- **Sortie** :  
  - Mise à jour de la roadmap (statut, commentaires, liens, date, responsable)
  - Fichiers créés/modifiés (code, doc, scripts, snippets…)
  - Changelog et documentation mis à jour
  - Rapport d’avancement (optionnel)

---

## Snippet VS Code (optionnel)

```json
{
  "Mode DEV-R": {
    "prefix": "devr",
    "body": [
      "# Mode DEV-R",

      "",
      "## Description",

      "Le mode DEV-R (Développement Roadmap) permet d’implémenter concrètement toutes les tâches d’un plan de développement : création, modification, tests, debug, documentation, automatisation, etc.",
      "",
      "## Fonctionnement",

      "- Sélectionne la tâche dans la roadmap",
      "- Granularise si besoin (mode GRAN)",
      "- Implémente la tâche (création, modif, suppression…)",
      "- Exécute les tests et debug",
      "- Met à jour la roadmap, la doc, les changelogs",
      "- Génère un rapport d’avancement"
    ],
    "description": "Insère le template du mode DEV-R pour l’implémentation concrète des tâches roadmap."
  }
}
```plaintext
---

## Bonnes pratiques et intégration avec les autres modes

- Toujours granulariser (`gran + N`) avant d’implémenter une tâche complexe.
- Utiliser les modes TEST, DEBUG, REVIEW, OPTI, CHECK selon le contexte.
- Documenter systématiquement chaque action (roadmap, changelog, doc).
- Générer des rapports réguliers pour le suivi d’avancement.
- Automatiser au maximum les tâches répétitives (snippets, scripts, CI/CD).

---

## Panel d’adaptabilité

- **Développement** : création, modification, suppression de code ou de fichiers.
- **Documentation** : génération, mise à jour, validation de docs.
- **Automatisation** : scripts, snippets, CI/CD, tests d’intégrité.
- **Analyse et reporting** : génération de rapports, synthèses, tableaux de suivi.
- **Qualité** : tests, debug, revue, optimisation, vérification de conformité.
- **Personnalisation** : intégration de modes spécifiques selon le contexte du projet.

---

## Liens utiles et ressources associées

- [Exemples de roadmaps consolidées](../../projet/roadmaps/plans/consolidated/)
- [Scripts d’automatisation](../../development/tools/scripts/)
- [Documentation des autres modes](../modes/)
- [Bonnes pratiques de gestion de projet](../../documentation/best-practices.md)

---

> Ce mode est conçu pour permettre à l’agent ou à l’utilisateur d’implémenter concrètement toute tâche roadmap, en s’appuyant sur les outils et modes adaptés, sans commentaire superflu.  
> En cas d’information manquante, demander explicitement le complément avant d’agir.
