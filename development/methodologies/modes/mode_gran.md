# Mode GRAN

## Description
Le mode GRAN (Granularisation) permet de décomposer une ou plusieurs tâches complexes en sous-tâches plus petites, adaptées à la complexité, au domaine technique et au contexte du projet. Il propose différents niveaux de granularité et choisit automatiquement l’approche la plus pertinente (progressivité, responsabilité, domaine, fichier, dossier, etc.) pour détailler la tâche ou l’ensemble de tâches sélectionnées.

## Objectifs
- Décomposer les tâches complexes en unités de travail plus petites, précises et actionnables.
- Adapter dynamiquement le niveau de granularité selon la complexité, le domaine et le contexte rencontré.
- Permettre l’ajout de plusieurs niveaux de sous-tâches supplémentaires (ex : `GRAN + 2`).
- Mettre à jour la roadmap avec les sous-tâches générées.

## Commandes principales
- `gran run` : Granularise une tâche spécifique (détection automatique de la complexité et du domaine).
- `gran custom` : Granularise avec un modèle de sous-tâches personnalisé.
- `gran manager` : Utilise le mode-manager pour exécuter le mode GRAN sur une tâche.
- `GRAN + N` : Granularise en ajoutant N niveaux de sous-tâches supplémentaires, en choisissant l’approche la plus adaptée au contexte (progressivité, responsabilité, etc.).

## Fonctionnement
- Analyse la tâche ou l’ensemble de tâches sélectionnées pour détecter la complexité, le domaine et le contexte.
- Choisit automatiquement l’approche de granularisation la plus pertinente (progressivité, responsabilité, domaine, etc.).
- Génère automatiquement les sous-tâches selon le niveau de granularité demandé (ex : `GRAN + 2` ajoute 2 niveaux supplémentaires).
- Met à jour la roadmap avec les nouvelles sous-tâches détaillées.
- Permet d’utiliser des modèles personnalisés pour des besoins spécifiques.

## Bonnes pratiques
- Toujours granulariser avant d’implémenter une tâche complexe ou floue.
- Utiliser `GRAN + N` pour obtenir le niveau de détail souhaité selon la complexité du sujet.
- Adapter le niveau de granularité au contexte du projet et à la lisibilité attendue.
- Documenter chaque sous-tâche générée pour faciliter le suivi et l’automatisation.
- Privilégier l’approche la plus pertinente (progressivité, responsabilité, domaine, etc.) selon la nature de la tâche.

## Intégration avec les autres modes
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

# Granulariser en ajoutant 2 niveaux de sous-tâches supplémentaires (snippet GRAN + 2)
Invoke-AugmentMode -Mode "GRAN" -FilePath "projet/roadmaps/roadmap.md" -TaskIdentifier "1.2.3" -GranularityLevel 2
```

## Snippet VS Code (optionnel)
```json
{
  "Mode GRAN + N": {
    "prefix": "granplusn",
    "body": [
      "# Mode GRAN + ${1:N}",
      "",
      "## Description",
      "Granularise la tâche sélectionnée en ajoutant ${1:N} niveaux de sous-tâches supplémentaires, selon l’approche la plus pertinente (progressivité, responsabilité, etc.).",
      "",
      "## Exemple d’appel",
      "Invoke-AugmentMode -Mode \"GRAN\" -FilePath \"${2:projet/roadmaps/roadmap.md}\" -TaskIdentifier \"${3:1.2.3}\" -GranularityLevel ${1:N}"
    ],
    "description": "Granularise la tâche sélectionnée avec N niveaux de sous-tâches supplémentaires."
  }
}
```
