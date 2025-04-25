# Module Format-Converters

## Vue d'ensemble

Le module Format-Converters est un outil puissant pour la détection, la conversion et l'analyse de formats de fichiers. Il prend en charge de nombreux formats courants tels que JSON, XML, HTML, CSV, YAML, Markdown, etc.

## Fonctionnalités principales

- **Détection automatique de format** : Détecte automatiquement le format d'un fichier en utilisant des critères avancés.
- **Gestion des cas ambigus** : Gère les cas où plusieurs formats sont possibles, avec confirmation utilisateur ou résolution automatique.
- **Conversion de format** : Convertit des fichiers d'un format à un autre.
- **Analyse de format** : Analyse les fichiers pour obtenir des informations détaillées sur leur structure et leur contenu.

## Installation

1. Copiez le répertoire `Format-Converters` dans votre dossier de modules PowerShell.
2. Importez le module en utilisant la commande suivante :

```powershell
Import-Module -Path "chemin\vers\Format-Converters\Format-Converters.psm1"
```

## Commandes disponibles

### Detect-FileFormat

Détecte le format d'un fichier.

```powershell
Detect-FileFormat -FilePath "chemin\vers\fichier.txt" [-AutoResolve] [-ShowDetails] [-RememberChoices]
```

#### Paramètres

- **FilePath** : Le chemin du fichier à analyser.
- **AutoResolve** : Indique si les cas ambigus doivent être résolus automatiquement sans intervention de l'utilisateur.
- **ShowDetails** : Indique si les détails de la détection doivent être affichés.
- **RememberChoices** : Indique si les choix de l'utilisateur doivent être mémorisés pour les cas similaires.

#### Exemple

```powershell
$result = Detect-FileFormat -FilePath "data.txt" -ShowDetails
Write-Host "Format détecté : $($result.DetectedFormat)"
```

### Convert-FileFormat

Convertit un fichier d'un format à un autre.

```powershell
Convert-FileFormat -InputPath "chemin\vers\fichier.json" -OutputPath "chemin\vers\fichier.xml" -OutputFormat "XML" [-InputFormat "JSON"] [-AutoDetect] [-Force] [-ShowProgress]
```

#### Paramètres

- **InputPath** : Le chemin du fichier d'entrée.
- **OutputPath** : Le chemin du fichier de sortie.
- **InputFormat** : Le format du fichier d'entrée.
- **OutputFormat** : Le format du fichier de sortie.
- **AutoDetect** : Indique si le format d'entrée doit être détecté automatiquement.
- **Force** : Indique si le fichier de sortie doit être écrasé s'il existe déjà.
- **ShowProgress** : Indique si la progression de la conversion doit être affichée.

#### Exemple

```powershell
$result = Convert-FileFormat -InputPath "data.json" -OutputPath "data.xml" -OutputFormat "XML" -AutoDetect
if ($result.Success) {
    Write-Host "Conversion réussie !"
}
```

### Analyze-FileFormat

Analyse un fichier pour obtenir des informations détaillées sur son format.

```powershell
Analyze-FileFormat -FilePath "chemin\vers\fichier.json" [-Format "JSON"] [-AutoDetect] [-IncludeContent] [-ExportReport] [-ReportPath "chemin\vers\rapport.json"]
```

#### Paramètres

- **FilePath** : Le chemin du fichier à analyser.
- **Format** : Le format du fichier.
- **AutoDetect** : Indique si le format doit être détecté automatiquement.
- **IncludeContent** : Indique si le contenu du fichier doit être inclus dans l'analyse.
- **ExportReport** : Indique si un rapport d'analyse doit être généré.
- **ReportPath** : Le chemin où exporter le rapport d'analyse.

#### Exemple

```powershell
$result = Analyze-FileFormat -FilePath "data.json" -AutoDetect -ExportReport
$result | Format-List
```

## Gestion des cas ambigus

Le module Format-Converters inclut un système avancé de gestion des cas ambigus, où plusieurs formats sont possibles pour un même fichier. Ce système utilise un score de confiance pour chaque format potentiel et peut résoudre les ambiguïtés de plusieurs façons :

1. **Résolution automatique** : Le format avec la priorité la plus élevée est choisi automatiquement.
2. **Confirmation utilisateur** : L'utilisateur est invité à choisir le format correct parmi les options possibles.
3. **Mémorisation des choix** : Les choix de l'utilisateur peuvent être mémorisés pour les cas similaires.

### Exemple de gestion des cas ambigus

```powershell
$result = Detect-FileFormat -FilePath "data.txt" -ShowDetails -RememberChoices
```

Si le fichier a un format ambigu, l'utilisateur sera invité à choisir le format correct. Ce choix sera mémorisé pour les cas similaires.

## Formats pris en charge

Le module prend en charge les formats suivants :

- JSON
- XML
- HTML
- CSV
- YAML
- Markdown
- JavaScript
- CSS
- PowerShell
- Python
- INI
- Texte brut

## Exemples d'utilisation

Consultez les scripts d'exemple dans le répertoire `Examples` pour des exemples d'utilisation du module Format-Converters :

- `Detect-FileFormat-Example.ps1` : Exemple de détection de format.
- `Convert-FileFormat-Example.ps1` : Exemple de conversion de format.
- `Analyze-FileFormat-Example.ps1` : Exemple d'analyse de format.

## Personnalisation

Le module Format-Converters peut être personnalisé en modifiant les critères de détection dans le fichier `Detectors\FormatDetectionCriteria.json`. Ce fichier contient les critères utilisés pour détecter chaque format, tels que les extensions, les motifs d'en-tête, les motifs de contenu, etc.

## Dépannage

### Problèmes courants

1. **Format non détecté** : Vérifiez que le fichier est valide et que son format est pris en charge par le module.
2. **Erreur de conversion** : Vérifiez que la conversion entre les formats spécifiés est prise en charge.
3. **Cas ambigu non résolu** : Utilisez l'option `-ShowDetails` pour voir les formats possibles et leurs scores de confiance.

### Journalisation

Le module Format-Converters inclut un système de journalisation qui peut être utile pour le dépannage. Les journaux sont enregistrés dans le répertoire `logs` du module.

## Contribution

Les contributions au module Format-Converters sont les bienvenues ! Voici comment vous pouvez contribuer :

1. Ajoutez de nouveaux formats en modifiant le fichier `Detectors\FormatDetectionCriteria.json`.
2. Améliorez les algorithmes de détection et de conversion.
3. Ajoutez de nouveaux exemples et de la documentation.

## Licence

Le module Format-Converters est distribué sous licence MIT.
