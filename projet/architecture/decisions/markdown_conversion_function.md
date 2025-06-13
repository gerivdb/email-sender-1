# Spécification de la Fonction de Conversion Markdown vers Objet

## Vue d'Ensemble

La fonction `ConvertFrom-MarkdownToObject` est la fonction principale du module RoadmapParser pour convertir un fichier markdown en structure d'objet PowerShell. Cette spécification détaille son fonctionnement, ses paramètres, sa logique interne et ses résultats attendus.

## Signature de la Fonction

```powershell
function ConvertFrom-MarkdownToObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "UTF32", "ASCII", "Unicode", "BigEndianUnicode", "Default")]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [hashtable]$CustomStatusMarkers
    )
}
```plaintext
## Paramètres

### FilePath

- **Type**: string
- **Obligatoire**: Oui
- **Description**: Chemin du fichier markdown à convertir.
- **Validation**: Ne doit pas être null ou vide, le fichier doit exister.

### Encoding

- **Type**: string
- **Obligatoire**: Non
- **Valeur par défaut**: "UTF8"
- **Valeurs possibles**: "UTF8", "UTF7", "UTF32", "ASCII", "Unicode", "BigEndianUnicode", "Default"
- **Description**: Encodage du fichier markdown.

### IncludeMetadata

- **Type**: switch
- **Obligatoire**: Non
- **Valeur par défaut**: $false
- **Description**: Indique si les métadonnées supplémentaires (dates, assignations, tags, priorités) doivent être extraites et incluses dans les objets.

### CustomStatusMarkers

- **Type**: hashtable
- **Obligatoire**: Non
- **Description**: Hashtable définissant des marqueurs de statut personnalisés et leur correspondance avec les statuts standard.
- **Format**: Clé = marqueur personnalisé, Valeur = statut standard ("Complete", "InProgress", "Blocked", "Incomplete")

## Fonctions Internes

### Get-FileEncoding

- **Description**: Détecte l'encodage d'un fichier en analysant ses premiers octets (BOM).
- **Paramètres**:
  - **FilePath**: Chemin du fichier à analyser.
- **Retour**: Objet System.Text.Encoding représentant l'encodage détecté.

### ConvertFrom-StatusMarker

- **Description**: Convertit un marqueur de statut en valeur d'énumération.
- **Paramètres**:
  - **StatusMarker**: Marqueur de statut à convertir (x, X, ~, !, espace, etc.).
  - **CustomMarkers**: Hashtable de marqueurs personnalisés.
- **Retour**: Chaîne représentant le statut ("Complete", "InProgress", "Blocked", "Incomplete").

### Get-LineMetadata

- **Description**: Extrait les métadonnées d'une ligne de texte.
- **Paramètres**:
  - **Line**: Ligne de texte à analyser.
- **Retour**: Hashtable contenant les métadonnées extraites (Date, Assignee, Tags, Priority).

## Logique de Traitement

1. **Validation des Entrées**:
   - Vérifier que le fichier existe.
   - Valider les paramètres d'encodage.

2. **Lecture du Fichier**:
   - Détecter l'encodage si nécessaire.
   - Lire le contenu du fichier avec l'encodage spécifié.
   - Diviser le contenu en lignes.

3. **Création de l'Objet Racine**:
   - Créer un objet PSCustomObject avec les propriétés Title, Description, Items et Metadata.

4. **Extraction du Titre et de la Description**:
   - Rechercher la première ligne commençant par # pour extraire le titre.

   - Extraire les lignes suivantes non vides jusqu'à la première section comme description.

5. **Parsing des Lignes**:
   - Pour chaque ligne du fichier:
     - Ignorer les lignes vides.
     - Détecter les tâches (lignes commençant par -, *, + avec ou sans case à cocher).
     - Détecter les sections (lignes commençant par #).

6. **Traitement des Tâches**:
   - Extraire l'indentation, le marqueur de statut, l'ID et le titre.
   - Déterminer le statut en fonction du marqueur.
   - Générer un ID si non spécifié.
   - Extraire les métadonnées si demandé.
   - Créer un objet tâche avec les propriétés extraites.
   - Déterminer le parent en fonction de l'indentation.
   - Ajouter la tâche au parent approprié.

7. **Traitement des Sections**:
   - Extraire le niveau et le titre de la section.
   - Créer un objet section avec les propriétés extraites.
   - Déterminer le parent en fonction du niveau.
   - Ajouter la section au parent approprié.

8. **Gestion des Erreurs**:
   - Capturer et journaliser les erreurs.
   - Propager les exceptions avec des messages clairs.

## Structure de l'Objet Retourné

```plaintext
RootObject
|-- Title: string
|-- Description: string
|-- Items: ArrayList
|   |-- Section
|   |   |-- Title: string
|   |   |-- Level: int
|   |   |-- Items: ArrayList
|   |   |   |-- Task
|   |   |   |   |-- Id: string
|   |   |   |   |-- Title: string
|   |   |   |   |-- Status: string
|   |   |   |   |-- Level: int
|   |   |   |   |-- Items: ArrayList
|   |   |   |   |-- Metadata: hashtable
|   |   |   |   |-- OriginalText: string
|   |   |   |-- ...
|   |   |-- Metadata: hashtable
|   |   |-- OriginalText: string
|   |-- ...
|-- Metadata: hashtable
```plaintext
## Exemples d'Utilisation

### Exemple 1: Conversion Simple

```powershell
ConvertFrom-MarkdownToObject -FilePath ".\roadmap.md"
```plaintext
### Exemple 2: Conversion avec Extraction des Métadonnées

```powershell
ConvertFrom-MarkdownToObject -FilePath ".\roadmap.md" -Encoding "UTF8" -IncludeMetadata
```plaintext
### Exemple 3: Conversion avec Marqueurs Personnalisés

```powershell
$customMarkers = @{
    "o" = "InProgress";
    "?" = "Blocked"
}
ConvertFrom-MarkdownToObject -FilePath ".\roadmap.md" -CustomStatusMarkers $customMarkers
```plaintext
## Considérations de Performance

- La fonction est optimisée pour traiter des fichiers de taille moyenne (jusqu'à quelques MB).
- Pour les très grands fichiers, une approche de lecture par blocs pourrait être nécessaire.
- L'extraction des métadonnées peut ralentir le traitement, donc elle est optionnelle.

## Limitations Connues

- La fonction suppose une structure hiérarchique basée sur l'indentation (2 espaces par niveau).
- Les tâches doivent suivre un format spécifique (-, *, + avec ou sans case à cocher).
- La détection automatique d'encodage n'est pas infaillible pour tous les types de fichiers.

## Évolutions Futures

- Support pour d'autres formats de markdown.
- Amélioration de la détection des dépendances entre tâches.
- Optimisation pour les très grands fichiers.
- Support pour des métadonnées personnalisées.

## Conclusion

La fonction `ConvertFrom-MarkdownToObject` est le cœur du module RoadmapParser, permettant de convertir des roadmaps au format markdown en structures d'objets PowerShell manipulables. Elle est conçue pour être robuste, flexible et extensible, tout en offrant des performances satisfaisantes pour la plupart des cas d'utilisation.
