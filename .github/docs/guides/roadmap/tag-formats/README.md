# Système de configuration des formats de tags

## Introduction

Le système de configuration des formats de tags permet de définir, gérer et utiliser des formats de tags personnalisés dans les roadmaps. Il offre une solution flexible pour détecter et analyser différents types de tags dans les tâches, comme les durées, les priorités, les complexités, etc.

## Structure de la configuration

La configuration des formats de tags est stockée dans un fichier JSON avec la structure suivante :

```json
{
  "name": "Tag Formats Configuration",
  "description": "Configuration des formats de tags pour les roadmaps",
  "version": "1.0.0",
  "updated_at": "2025-05-15T12:00:00Z",
  "tag_formats": {
    "duration": {
      "name": "Duration",
      "description": "Tags pour la durée en anglais",
      "formats": [
        {
          "name": "DurationDays",
          "pattern": "#duration:(\\d+(?:\\.\\d+)?)d\\b",

          "description": "Format #duration:Xd (jours)",

          "example": "#duration:5d",

          "value_group": 1,
          "unit": "days"
        },
        // Autres formats...
      ]
    },
    // Autres types de tags...
  }
}
```plaintext
### Éléments de la configuration

- **name** : Nom de la configuration
- **description** : Description de la configuration
- **version** : Version de la configuration
- **updated_at** : Date de dernière mise à jour
- **tag_formats** : Dictionnaire des types de tags

Chaque type de tag contient :
- **name** : Nom du type de tag
- **description** : Description du type de tag
- **formats** : Liste des formats pour ce type de tag

Chaque format contient :
- **name** : Nom unique du format
- **pattern** : Expression régulière pour détecter le format
- **description** : Description du format
- **example** : Exemple d'utilisation
- **value_group** : Numéro du groupe de capture pour la valeur (pour les formats simples)
- **unit** : Unité de la valeur (pour les formats simples)
- **value_groups** : Liste des numéros des groupes de capture pour les valeurs (pour les formats composites)
- **units** : Liste des unités pour chaque valeur (pour les formats composites)
- **composite** : Booléen indiquant si le format est composite (plusieurs valeurs/unités)

## Utilisation du script Manage-TagFormats.ps1

Le script `Manage-TagFormats.ps1` permet de gérer la configuration des formats de tags.

### Paramètres

- **Action** : Action à effectuer (Get, Add, Update, Remove, List, Export, Import)
- **TagType** : Type de tag à manipuler
- **FormatName** : Nom du format à manipuler
- **Pattern** : Expression régulière pour le format
- **Description** : Description du format
- **Example** : Exemple d'utilisation du format
- **Unit** : Unité de la valeur
- **ValueGroup** : Numéro du groupe de capture pour la valeur
- **ConfigPath** : Chemin du fichier de configuration
- **OutputPath** : Chemin du fichier de sortie pour l'export
- **ImportPath** : Chemin du fichier à importer
- **Force** : Forcer l'opération

### Exemples d'utilisation

#### Obtenir un format spécifique

```powershell
.\Manage-TagFormats.ps1 -Action Get -TagType duration -FormatName DurationDays -ConfigPath "path\to\config.json"
```plaintext
#### Ajouter un nouveau format

```powershell
.\Manage-TagFormats.ps1 -Action Add -TagType duration -FormatName DurationHours -Pattern "#duration:(\d+(?:\.\d+)?)h\b" -Description "Format #duration:Xh (heures)" -Example "#duration:3h" -Unit "hours" -ValueGroup 1 -ConfigPath "path\to\config.json"

```plaintext
#### Mettre à jour un format existant

```powershell
.\Manage-TagFormats.ps1 -Action Update -TagType duration -FormatName DurationDays -Description "Nouvelle description" -ConfigPath "path\to\config.json"
```plaintext
#### Supprimer un format

```powershell
.\Manage-TagFormats.ps1 -Action Remove -TagType duration -FormatName DurationDays -ConfigPath "path\to\config.json"
```plaintext
#### Lister tous les formats

```powershell
.\Manage-TagFormats.ps1 -Action List -ConfigPath "path\to\config.json"
```plaintext
#### Lister les formats d'un type spécifique

```powershell
.\Manage-TagFormats.ps1 -Action List -TagType duration -ConfigPath "path\to\config.json"
```plaintext
#### Exporter la configuration

```powershell
.\Manage-TagFormats.ps1 -Action Export -ConfigPath "path\to\config.json" -OutputPath "path\to\export.json"
```plaintext
#### Importer une configuration

```powershell
.\Manage-TagFormats.ps1 -Action Import -ConfigPath "path\to\config.json" -ImportPath "path\to\import.json"
```plaintext
## Utilisation programmatique

Vous pouvez également utiliser les fonctions du script dans vos propres scripts PowerShell.

```powershell
# Charger les fonctions du script

. "path\to\Manage-TagFormats.ps1"

# Charger la configuration

$config = Get-TagFormatsConfig -ConfigPath "path\to\config.json"

# Obtenir un format spécifique

$format = Get-TagFormat -Config $config -TagType "duration" -FormatName "DurationDays"

# Ajouter un nouveau format

$result = Add-TagFormat -Config $config -TagType "duration" -FormatName "DurationHours" -Pattern "#duration:(\d+(?:\.\d+)?)h\b" -Description "Format #duration:Xh (heures)" -Example "#duration:3h" -Unit "hours" -ValueGroup 1

# Sauvegarder la configuration

Save-TagFormatsConfig -Config $config -ConfigPath "path\to\config.json"
```plaintext
## Bonnes pratiques

### Nommage des formats

- Utilisez des noms descriptifs et uniques pour chaque format
- Préfixez les noms avec le type de tag pour éviter les conflits
- Utilisez le CamelCase pour les noms de formats

### Expressions régulières

- Utilisez des expressions régulières précises pour éviter les faux positifs
- Utilisez des groupes de capture nommés pour améliorer la lisibilité
- Testez vos expressions régulières avec des exemples variés

### Gestion de la configuration

- Sauvegardez régulièrement la configuration
- Utilisez le versionnement pour suivre les modifications
- Documentez les formats personnalisés

## Dépannage

### Problèmes courants

- **Le format n'est pas détecté** : Vérifiez l'expression régulière et testez-la avec des exemples
- **Erreur lors du chargement de la configuration** : Vérifiez que le fichier JSON est valide
- **Conflit de noms** : Assurez-vous que les noms des formats sont uniques

### Solutions

- Utilisez des outils de validation JSON pour vérifier la structure de la configuration
- Testez vos expressions régulières avec des outils comme RegExr ou Regex101
- Utilisez l'action List pour vérifier les formats existants avant d'en ajouter de nouveaux

## Conclusion

Le système de configuration des formats de tags offre une solution flexible et extensible pour gérer les tags dans les roadmaps. Il permet de définir des formats personnalisés, de les détecter dans les tâches et d'extraire les informations pertinentes pour l'analyse et la visualisation.

Pour plus d'informations sur la détection des tags et l'apprentissage de nouveaux formats, consultez les guides correspondants :

- [Détection des tags avec expressions régulières](./tag-detection.md)
- [Apprentissage des nouveaux formats de tags](./tag-learning.md)
