# Module Format-Converters

## Vue d'ensemble

Le module Format-Converters est un outil puissant pour la dÃ©tection, la conversion et l'analyse de formats de fichiers. Il prend en charge de nombreux formats courants tels que JSON, XML, HTML, CSV, YAML, Markdown, etc.

## FonctionnalitÃ©s principales

- **DÃ©tection automatique de format** : DÃ©tecte automatiquement le format d'un fichier en utilisant des critÃ¨res avancÃ©s.
- **Gestion des cas ambigus** : GÃ¨re les cas oÃ¹ plusieurs formats sont possibles, avec confirmation utilisateur ou rÃ©solution automatique.
- **Conversion de format** : Convertit des fichiers d'un format Ã  un autre.
- **Analyse de format** : Analyse les fichiers pour obtenir des informations dÃ©taillÃ©es sur leur structure et leur contenu.

## Installation

1. Copiez le rÃ©pertoire `Format-Converters` dans votre dossier de modules PowerShell.
2. Importez le module en utilisant la commande suivante :

```powershell
Import-Module -Path "chemin\vers\Format-Converters\Format-Converters.psm1"
```plaintext
## Commandes disponibles

### Detect-FileFormat

DÃ©tecte le format d'un fichier.

```powershell
Detect-FileFormat -FilePath "chemin\vers\fichier.txt" [-AutoResolve] [-ShowDetails] [-RememberChoices]
```plaintext
#### ParamÃ¨tres

- **FilePath** : Le chemin du fichier Ã  analyser.
- **AutoResolve** : Indique si les cas ambigus doivent Ãªtre rÃ©solus automatiquement sans intervention de l'utilisateur.
- **ShowDetails** : Indique si les dÃ©tails de la dÃ©tection doivent Ãªtre affichÃ©s.
- **RememberChoices** : Indique si les choix de l'utilisateur doivent Ãªtre mÃ©morisÃ©s pour les cas similaires.

#### Exemple

```powershell
$result = Detect-FileFormat -FilePath "data.txt" -ShowDetails
Write-Host "Format dÃ©tectÃ© : $($result.DetectedFormat)"
```plaintext
### Convert-FileFormat

Convertit un fichier d'un format Ã  un autre.

```powershell
Convert-FileFormat -InputPath "chemin\vers\fichier.json" -OutputPath "chemin\vers\fichier.xml" -OutputFormat "XML" [-InputFormat "JSON"] [-AutoDetect] [-Force] [-ShowProgress]
```plaintext
#### ParamÃ¨tres

- **InputPath** : Le chemin du fichier d'entrÃ©e.
- **OutputPath** : Le chemin du fichier de sortie.
- **InputFormat** : Le format du fichier d'entrÃ©e.
- **OutputFormat** : Le format du fichier de sortie.
- **AutoDetect** : Indique si le format d'entrÃ©e doit Ãªtre dÃ©tectÃ© automatiquement.
- **Force** : Indique si le fichier de sortie doit Ãªtre Ã©crasÃ© s'il existe dÃ©jÃ .
- **ShowProgress** : Indique si la progression de la conversion doit Ãªtre affichÃ©e.

#### Exemple

```powershell
$result = Convert-FileFormat -InputPath "data.json" -OutputPath "data.xml" -OutputFormat "XML" -AutoDetect
if ($result.Success) {
    Write-Host "Conversion rÃ©ussie !"
}
```plaintext
### Analyze-FileFormat

Analyse un fichier pour obtenir des informations dÃ©taillÃ©es sur son format.

```powershell
Analyze-FileFormat -FilePath "chemin\vers\fichier.json" [-Format "JSON"] [-AutoDetect] [-IncludeContent] [-ExportReport] [-ReportPath "chemin\vers\rapport.json"]
```plaintext
#### ParamÃ¨tres

- **FilePath** : Le chemin du fichier Ã  analyser.
- **Format** : Le format du fichier.
- **AutoDetect** : Indique si le format doit Ãªtre dÃ©tectÃ© automatiquement.
- **IncludeContent** : Indique si le contenu du fichier doit Ãªtre inclus dans l'analyse.
- **ExportReport** : Indique si un rapport d'analyse doit Ãªtre gÃ©nÃ©rÃ©.
- **ReportPath** : Le chemin oÃ¹ exporter le rapport d'analyse.

#### Exemple

```powershell
$result = Analyze-FileFormat -FilePath "data.json" -AutoDetect -ExportReport
$result | Format-List
```plaintext
## Gestion des cas ambigus

Le module Format-Converters inclut un systÃ¨me avancÃ© de gestion des cas ambigus, oÃ¹ plusieurs formats sont possibles pour un mÃªme fichier. Ce systÃ¨me utilise un score de confiance pour chaque format potentiel et peut rÃ©soudre les ambiguÃ¯tÃ©s de plusieurs faÃ§ons :

1. **RÃ©solution automatique** : Le format avec la prioritÃ© la plus Ã©levÃ©e est choisi automatiquement.
2. **Confirmation utilisateur** : L'utilisateur est invitÃ© Ã  choisir le format correct parmi les options possibles.
3. **MÃ©morisation des choix** : Les choix de l'utilisateur peuvent Ãªtre mÃ©morisÃ©s pour les cas similaires.

### Exemple de gestion des cas ambigus

```powershell
$result = Detect-FileFormat -FilePath "data.txt" -ShowDetails -RememberChoices
```plaintext
Si le fichier a un format ambigu, l'utilisateur sera invitÃ© Ã  choisir le format correct. Ce choix sera mÃ©morisÃ© pour les cas similaires.

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

Consultez les scripts d'exemple dans le rÃ©pertoire `Examples` pour des exemples d'utilisation du module Format-Converters :

- `Detect-FileFormat-Example.ps1` : Exemple de dÃ©tection de format.
- `Convert-FileFormat-Example.ps1` : Exemple de conversion de format.
- `Analyze-FileFormat-Example.ps1` : Exemple d'analyse de format.

## Personnalisation

Le module Format-Converters peut Ãªtre personnalisÃ© en modifiant les critÃ¨res de dÃ©tection dans le fichier `Detectors\FormatDetectionCriteria.json`. Ce fichier contient les critÃ¨res utilisÃ©s pour dÃ©tecter chaque format, tels que les extensions, les motifs d'en-tÃªte, les motifs de contenu, etc.

## DÃ©pannage

### ProblÃ¨mes courants

1. **Format non dÃ©tectÃ©** : VÃ©rifiez que le fichier est valide et que son format est pris en charge par le module.
2. **Erreur de conversion** : VÃ©rifiez que la conversion entre les formats spÃ©cifiÃ©s est prise en charge.
3. **Cas ambigu non rÃ©solu** : Utilisez l'option `-ShowDetails` pour voir les formats possibles et leurs scores de confiance.

### Journalisation

Le module Format-Converters inclut un systÃ¨me de journalisation qui peut Ãªtre utile pour le dÃ©pannage. Les journaux sont enregistrÃ©s dans le rÃ©pertoire `logs` du module.

## Contribution

Les contributions au module Format-Converters sont les bienvenues ! Voici comment vous pouvez contribuer :

1. Ajoutez de nouveaux formats en modifiant le fichier `Detectors\FormatDetectionCriteria.json`.
2. AmÃ©liorez les algorithmes de dÃ©tection et de conversion.
3. Ajoutez de nouveaux exemples et de la documentation.

## Licence

Le module Format-Converters est distribuÃ© sous licence MIT.
