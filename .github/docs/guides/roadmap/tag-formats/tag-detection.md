# Détection des tags avec expressions régulières

## Introduction

Le système de détection des tags permet d'identifier et d'extraire les tags présents dans les tâches des roadmaps. Il utilise des expressions régulières configurables pour détecter différents formats de tags et extraire les informations pertinentes.

## Fonctionnement

Le processus de détection des tags se déroule en plusieurs étapes :

1. **Chargement de la configuration** : Chargement des formats de tags définis dans le fichier de configuration
2. **Détection des tâches** : Analyse du contenu pour identifier les tâches
3. **Détection des tags** : Application des expressions régulières pour détecter les tags dans chaque tâche
4. **Formatage des résultats** : Présentation des résultats dans le format souhaité

## Utilisation du script Detect-TagsWithRegex.ps1

Le script `Detect-TagsWithRegex.ps1` permet de détecter les tags dans les tâches des roadmaps.

### Paramètres

- **FilePath** : Chemin du fichier à analyser
- **Content** : Contenu à analyser (alternative à FilePath)
- **TagTypes** : Types de tags à détecter (tous par défaut)
- **ConfigPath** : Chemin du fichier de configuration des formats de tags
- **OutputPath** : Chemin du fichier de sortie pour les résultats
- **OutputFormat** : Format de sortie (JSON, Markdown, CSV, Text)
- **IncludeTaskContent** : Inclure le contenu des tâches dans les résultats
- **Force** : Forcer l'opération

### Exemples d'utilisation

#### Détecter les tags dans un fichier

```powershell
.\Detect-TagsWithRegex.ps1 -FilePath "path\to\roadmap.md" -ConfigPath "path\to\config.json" -OutputFormat "JSON"
```plaintext
#### Détecter les tags dans un contenu

```powershell
$content = Get-Content -Path "path\to\roadmap.md" -Raw
.\Detect-TagsWithRegex.ps1 -Content $content -ConfigPath "path\to\config.json" -OutputFormat "Markdown"
```plaintext
#### Détecter des types de tags spécifiques

```powershell
.\Detect-TagsWithRegex.ps1 -FilePath "path\to\roadmap.md" -TagTypes @("duration", "priority") -ConfigPath "path\to\config.json" -OutputFormat "JSON"
```plaintext
#### Enregistrer les résultats dans un fichier

```powershell
.\Detect-TagsWithRegex.ps1 -FilePath "path\to\roadmap.md" -ConfigPath "path\to\config.json" -OutputFormat "JSON" -OutputPath "path\to\results.json"
```plaintext
#### Inclure le contenu des tâches dans les résultats

```powershell
.\Detect-TagsWithRegex.ps1 -FilePath "path\to\roadmap.md" -ConfigPath "path\to\config.json" -OutputFormat "Markdown" -IncludeTaskContent
```plaintext
## Formats de sortie

Le script prend en charge plusieurs formats de sortie pour les résultats de la détection.

### JSON

Le format JSON fournit une représentation structurée des résultats, adaptée pour l'intégration avec d'autres outils ou pour l'analyse programmatique.

```json
{
  "1.1": {
    "Id": "1.1",
    "Title": "Tâche sans tag",
    "Status": false,
    "LineNumber": 5,
    "Line": "- [ ] **1.1** Tâche sans tag",
    "Tags": {
      "duration": [],
      "priority": []
    }
  },
  "1.2": {
    "Id": "1.2",
    "Title": "Tâche avec tag",
    "Status": false,
    "LineNumber": 6,
    "Line": "- [ ] **1.2** Tâche avec tag #duration:3d",

    "Tags": {
      "duration": [
        {
          "Type": "duration",
          "Format": "DurationDays",
          "Value": "3",
          "Unit": "days",
          "Original": "#duration:3d",

          "IsComposite": false
        }
      ],
      "priority": []
    }
  }
}
```plaintext
### Markdown

Le format Markdown génère un rapport lisible et formaté, adapté pour la documentation ou le partage.

```markdown
# Rapport de détection des tags

## Résumé

- Nombre de tâches analysées: 2
- Tags détectés par type:
  - duration: 1
  - priority: 0

## Détails par tâche

### Tâche 1.1

- Titre: Tâche sans tag
- Statut: À faire
- Ligne: 5
- Tags:
  - Aucun tag détecté

### Tâche 1.2

- Titre: Tâche avec tag
- Statut: À faire
- Ligne: 6
- Tags:
  - duration:
    - Format: DurationDays, Valeur: 3 days, Original: #duration:3d

```plaintext
### CSV

Le format CSV fournit une représentation tabulaire des résultats, adaptée pour l'importation dans des tableurs ou des bases de données.

```csv
TaskId,Title,Status,LineNumber,TagType,Format,Value,Unit,Original
1.1,"Tâche sans tag",False,5,,,,,
1.2,"Tâche avec tag",False,6,duration,DurationDays,3,days,"#duration:3d"

```plaintext
### Text

Le format Text génère un rapport en texte brut, adapté pour l'affichage dans la console ou pour une lecture rapide.

```plaintext
Rapport de détection des tags

Résumé:
- Nombre de tâches analysées: 2
- Tags détectés par type:
  - duration: 1
  - priority: 0

Détails par tâche:

Tâche 1.1:
- Titre: Tâche sans tag
- Statut: À faire
- Ligne: 5
- Tags:
  - Aucun tag détecté

Tâche 1.2:
- Titre: Tâche avec tag
- Statut: À faire
- Ligne: 6
- Tags:
  - duration:
    - Format: DurationDays, Valeur: 3 days, Original: #duration:3d

```plaintext
## Utilisation programmatique

Vous pouvez également utiliser les fonctions du script dans vos propres scripts PowerShell.

```powershell
# Charger les fonctions du script

. "path\to\Detect-TagsWithRegex.ps1"

# Charger la configuration

$config = Get-TagFormatsConfig -ConfigPath "path\to\config.json"

# Détecter les tâches dans le contenu

$content = Get-Content -Path "path\to\roadmap.md" -Raw
$tasks = Get-TasksFromContent -Content $content

# Détecter les tags dans les tâches

$tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config -TagTypes @("duration", "priority")

# Formater les résultats

$output = Format-DetectionResults -Tasks $tasksWithTags -Format "JSON"

# Afficher ou enregistrer les résultats

$output | Set-Content -Path "path\to\results.json" -Encoding UTF8
```plaintext
## Gestion des formats composites

Le système prend en charge les formats de tags composites, qui contiennent plusieurs valeurs et unités. Par exemple, `#duration:2d4h` représente une durée de 2 jours et 4 heures.

Pour les formats composites, les résultats incluent :
- **IsComposite** : Indique qu'il s'agit d'un format composite
- **Values** : Liste des valeurs extraites
- **Units** : Liste des unités correspondantes

Exemple de résultat pour un format composite :

```json
{
  "Type": "duration",
  "Format": "DurationDaysHours",
  "Values": ["2", "4"],
  "Units": ["days", "hours"],
  "Original": "#duration:2d4h",

  "IsComposite": true
}
```plaintext
## Bonnes pratiques

### Performance

- Utilisez des expressions régulières optimisées pour améliorer les performances
- Limitez les types de tags à détecter si vous n'avez besoin que de certains types
- Pour les fichiers volumineux, utilisez le paramètre FilePath plutôt que Content

### Intégration

- Utilisez le format JSON pour l'intégration avec d'autres outils
- Utilisez le format Markdown pour la documentation
- Utilisez le format CSV pour l'analyse dans des tableurs

### Dépannage

- Vérifiez que les expressions régulières dans la configuration sont correctes
- Assurez-vous que le format des tâches correspond au pattern attendu
- Utilisez l'option IncludeTaskContent pour voir le contenu exact des tâches

## Conclusion

Le système de détection des tags offre une solution flexible et puissante pour identifier et extraire les tags dans les tâches des roadmaps. Il permet d'analyser les tags pour obtenir des informations précieuses sur les durées, les priorités, les complexités, etc.

Pour plus d'informations sur la configuration des formats de tags et l'apprentissage de nouveaux formats, consultez les guides correspondants :

- [Système de configuration des formats de tags](./README.md)
- [Apprentissage des nouveaux formats de tags](./tag-learning.md)
