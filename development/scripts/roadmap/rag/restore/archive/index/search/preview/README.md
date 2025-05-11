# Module de Previsualisation des Resultats de Recherche

Ce module PowerShell fournit des fonctionnalites pour generer des previsualisations de resultats de recherche, avec mise en evidence des termes de recherche et formatage des resultats en differents formats (texte, HTML, JSON).

## Fonctionnalites

- Generation d'extraits de texte autour des termes de recherche
- Mise en evidence des termes de recherche dans les extraits
- Generation de previsualisations de documents
- Inclusion de metadonnees dans les previsualisations
- Formatage des previsualisations en texte, HTML et JSON

## Installation

1. Copiez les fichiers `SearchResultPreview.psm1` et `SearchResultPreview.psd1` dans un repertoire de modules PowerShell.
2. Importez le module avec la commande suivante :

```powershell
Import-Module -Name "SearchResultPreview"
```

Ou importez directement le fichier `.psm1` :

```powershell
Import-Module -Name "chemin/vers/SearchResultPreview.psm1"
```

## Utilisation

### Generation d'extraits de texte

```powershell
$texte = "Ce rapport presente les resultats financiers de l'annee 2024."
$termeRecherche = "resultats"
$extrait = Get-TextSnippet -Text $texte -SearchTerm $termeRecherche -ContextLength 20
```

### Generation de previsualisations de documents

```powershell
$document = [PSCustomObject]@{
    id = "doc1"
    type = "document"
    title = "Rapport annuel 2024"
    content = "Ce rapport presente les resultats financiers de l'annee 2024."
    created_at = "2024-01-15T10:30:00Z"
    author = "Jean Dupont"
    language = "fr"
}

$previsualisation = Get-DocumentPreview -Document $document -SearchTerm "resultats" -IncludeMetadata
```

### Generation de previsualisations pour une liste de documents

```powershell
$documents = @(
    # Liste de documents
)

$previsualisations = Get-SearchResultPreviews -Documents $documents -SearchTerm "terme" -IncludeMetadata -MaxResults 10
```

### Formatage des previsualisations

```powershell
# Formatage en texte
$texte = Format-PreviewsAsText -Previews $previsualisations

# Formatage en HTML
$html = Format-PreviewsAsHtml -Previews $previsualisations
$html | Out-File -FilePath "resultats.html" -Encoding utf8

# Formatage en JSON
$json = Format-PreviewsAsJson -Previews $previsualisations
```

## Exemple complet

Voir le fichier `ExempleUtilisation.ps1` pour un exemple complet d'utilisation du module.

## Fonctions

### Get-TextSnippet

Genere un extrait de texte autour d'un terme de recherche.

#### Parametres

- `Text` : Le texte dans lequel rechercher le terme.
- `SearchTerm` : Le terme a rechercher.
- `ContextLength` : Le nombre de caracteres a inclure avant et apres le terme (par defaut : 50).
- `CaseSensitive` : Indique si la recherche est sensible a la casse (par defaut : $false).

### Get-DocumentPreview

Genere une previsualisation d'un document.

#### Parametres

- `Document` : Le document a previsualiser.
- `SearchTerm` : Le terme a rechercher dans le document (par defaut : "").
- `ContentField` : Le nom du champ contenant le contenu du document (par defaut : "content").
- `TitleField` : Le nom du champ contenant le titre du document (par defaut : "title").
- `SnippetLength` : La longueur maximale de l'extrait (par defaut : 150).
- `IncludeMetadata` : Indique si les metadonnees doivent etre incluses dans la previsualisation (par defaut : $false).

### Get-SearchResultPreviews

Genere des previsualisations pour une liste de documents.

#### Parametres

- `Documents` : La liste des documents a previsualiser.
- `SearchTerm` : Le terme a rechercher dans les documents (par defaut : "").
- `ContentField` : Le nom du champ contenant le contenu des documents (par defaut : "content").
- `TitleField` : Le nom du champ contenant le titre des documents (par defaut : "title").
- `SnippetLength` : La longueur maximale des extraits (par defaut : 150).
- `IncludeMetadata` : Indique si les metadonnees doivent etre incluses dans les previsualisations (par defaut : $false).
- `MaxResults` : Le nombre maximum de resultats a retourner (par defaut : 10).

### Format-PreviewsAsText

Formate des previsualisations en texte.

#### Parametres

- `Previews` : Les previsualisations a formater.

### Format-PreviewsAsHtml

Formate des previsualisations en HTML.

#### Parametres

- `Previews` : Les previsualisations a formater.

### Format-PreviewsAsJson

Formate des previsualisations en JSON.

#### Parametres

- `Previews` : Les previsualisations a formater.

## Licence

Ce module est distribue sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
