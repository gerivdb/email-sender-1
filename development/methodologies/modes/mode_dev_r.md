# Mode DEV-R

## Description
Le mode DEV-R (Développement Roadmap) est un mode opérationnel dédié à l’implémentation séquentielle des tâches définies dans la roadmap d’un projet. Il vise à automatiser l’enchaînement des tâches, la gestion des tests et l’intégration continue des corrections.

## Objectifs
- Implémenter les tâches de la roadmap de façon séquentielle et fiable.
- Générer et exécuter automatiquement les tests associés à chaque tâche.
- Mettre à jour la roadmap après chaque tâche complétée.
- Intégrer automatiquement les modes TEST et DEBUG en cas d’erreur.
- Optimiser le flux de développement en limitant les interruptions et les redondances.

## Commandes principales
- devr start : Démarre l’implémentation séquentielle des tâches de la roadmap.
- devr next : Passe à la tâche suivante après validation.
- devr test : Lance les tests associés à la tâche courante.
- devr debug : Active le mode DEBUG en cas d’échec d’un test ou d’une tâche.

## Fonctionnement
- Parcourt la roadmap et sélectionne la prochaine tâche à implémenter.
- Implémente la tâche, puis exécute les tests associés.
- Si un test échoue, active automatiquement le mode DEBUG.
- Met à jour la roadmap (statut, commentaires, suggestions).
- Passe à la tâche suivante ou propose des améliorations/tests complémentaires.

## Bonnes pratiques
- Toujours valider les tests avant de passer à la tâche suivante.
- Documenter les corrections et suggestions dans la roadmap.
- Utiliser la granularisation (mode GRAN) pour découper les tâches complexes.
- Limiter les explications intermédiaires et se concentrer sur l’action.

## Intégration avec les autres modes
Le mode DEV-R s’intègre naturellement avec :
- **GRAN** : Pour décomposer les tâches complexes avant implémentation ([voir mode_gran.md](mode_gran.md))
- **TEST** : Pour valider chaque implémentation ([voir mode_test.md](mode_test.md))
- **DEBUG** : Pour corriger les erreurs détectées lors des tests ([voir mode_debug.md](mode_debug.md))
- **CHECK** : Pour vérifier et marquer les tâches complétées ([voir mode_check_enhanced.md](mode_check_enhanced.md))
- **REVIEW** : Pour soumettre les tâches à une revue qualité ([voir mode_review.md](mode_review.md))

Exemple de workflow typique : GRAN → DEV-R → TEST → DEBUG → REVIEW → CHECK

## Exemples d’utilisation
```powershell
# Démarrer le mode DEV-R sur une roadmap
Invoke-AugmentMode -Mode "DEV-R" -FilePath "projet/roadmap.md" -TaskIdentifier "1.2.3"

# Passer à la tâche suivante
Invoke-AugmentMode -Mode "DEV-R" -FilePath "projet/roadmap.md" -Next
```

## Snippet VS Code (optionnel)
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
