# Mode GRAN

## Description
Le mode GRAN (Granularisation) décompose la ou les tâches complexe(s) d'un plan de développement en sous-tâches plus petites, adaptées à la complexité et au domaine technique, pour faciliter la gestion, l’estimation et l’automatisation du développement. La  granularisation décompose soit en étapes progressives, soit en domaines spécifiques, soit par fichier ou par dossier, selon le besoin.

## Objectifs
- Décomposer les tâches complexes en unités de travail plus petites et précises.
- Adapter le niveau de granularité selon la complexité et le domaine.
- Mettre à jour la roadmap avec les sous-tâches générées.

## Commandes principales
- gran run : Granularise une tâche spécifique (détection automatique de la complexité et du domaine).
- gran custom : Granularise avec un modèle de sous-tâches personnalisé.
- gran manager : Utilise le mode-manager pour exécuter le mode GRAN sur une tâche.

## Fonctionnement
- Analyse la tâche cible pour détecter la complexité et le domaine.
- Génère automatiquement les sous-tâches selon des modèles adaptés.
- Met à jour la roadmap avec les nouvelles sous-tâches.
- Permet d’utiliser des modèles personnalisés pour des besoins spécifiques.

## Bonnes pratiques
- Toujours granulariser avant d’implémenter une tâche complexe.
- Adapter le niveau de granularité au contexte du projet.
- Documenter chaque sous-tâche générée.
- Utiliser des modèles adaptés au domaine technique.

## Intégration avec les autres modes
Le mode GRAN s’intègre naturellement avec :
- **DEV-R** : Pour implémenter les sous-tâches générées ([voir mode_dev_r.md](mode_dev_r.md))
- **TEST** : Pour générer des tests pour chaque sous-tâche ([voir mode_test.md](mode_test.md))
- **CHECK** : Pour vérifier l’avancement des sous-tâches ([voir mode_check_enhanced.md](mode_check_enhanced.md))

Exemple de workflow typique : GRAN → DEV-R → TEST → CHECK

## Exemples d’utilisation
```powershell
# Granulariser une tâche avec détection automatique
Invoke-AugmentMode -Mode "GRAN" -FilePath "projet/roadmaps/roadmap.md" -TaskIdentifier "1.2.3"

# Granulariser avec un modèle personnalisé
Invoke-AugmentMode -Mode "GRAN" -FilePath "projet/roadmaps/roadmap.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates/subtasks.txt"
```

## Snippet VS Code (optionnel)
```json
{
  "Mode GRAN": {
    "prefix": "granmode",
    "body": [
      "# Mode GRAN",
      "",
      "## Description",
      "Le mode GRAN (Granularisation) décompose les tâches complexes en sous-tâches plus petites.",
      "",
      "## Fonctionnement",
      "- Analyse la tâche et détecte la complexité et le domaine",
      "- Génère automatiquement les sous-tâches",
      "- Met à jour la roadmap avec les sous-tâches générées"
    ],
    "description": "Insère le template du mode GRAN pour la granularisation des tâches."
  }
}
```
