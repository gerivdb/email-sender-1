# Gestionnaire de Metadonnees

Ce module PowerShell fournit des fonctionnalites pour gerer les metadonnees des documents et des fichiers markdown.

## Fonctionnalites

- Extraction des metadonnees des documents
- Ajout et mise a jour des metadonnees des documents
- Suppression des metadonnees des documents
- Extraction des metadonnees des fichiers markdown (YAML frontmatter et inline)
- Ajout et mise a jour des metadonnees des fichiers markdown

## Installation

1. Copiez le fichier `MetadataManager.ps1` dans votre projet.
2. Importez le module avec la commande suivante :

```powershell
. "chemin/vers/MetadataManager.ps1"
```

## Utilisation

### Gestion des metadonnees des documents

#### Extraction des metadonnees

```powershell
$document = [PSCustomObject]@{
    id = "doc1"
    title = "Document de test"
    content = "Contenu du document de test"
    author = "Jean Dupont"
    created_at = "2024-01-15T10:30:00Z"
    status = "draft"
    priority = "high"
}

# Extraire toutes les metadonnees sauf le contenu
$metadata = Get-DocumentMetadata -Document $document

# Extraire uniquement les metadonnees specifiees
$metadata = Get-DocumentMetadata -Document $document -IncludeFields @("title", "author", "status")
```

#### Ajout et mise a jour des metadonnees

```powershell
# Ajouter de nouvelles metadonnees
$newMetadata = @{
    category = "documentation"
    tags = @("test", "metadata")
    language = "fr"
}
$updatedDocument = Add-DocumentMetadata -Document $document -Metadata $newMetadata

# Mettre a jour des metadonnees existantes
$updateMetadata = @{
    status = "published"
    priority = "medium"
}
$updatedDocument = Add-DocumentMetadata -Document $document -Metadata $updateMetadata -Force
```

#### Suppression des metadonnees

```powershell
$fieldsToRemove = @("status", "priority", "tags")
$updatedDocument = Remove-DocumentMetadata -Document $document -Fields $fieldsToRemove
```

### Gestion des metadonnees des fichiers markdown

#### Extraction des metadonnees

```powershell
$metadata = Get-MarkdownMetadata -FilePath "chemin/vers/document.md"
```

Cette fonction extrait les metadonnees des sources suivantes :

- YAML frontmatter (entre `---` au debut du fichier)
- Tags inline (format `#key:value`)
- Attributs entre parentheses (format `(key:value)`)
- Metadonnees de base du fichier (chemin, nom, extension, taille, dates)

#### Ajout et mise a jour des metadonnees

```powershell
# Ajouter des metadonnees au format YAML
$metadata = @{
    title = "Document mis a jour"
    author = "Marie Martin"
    date = "2024-05-15"
    status = "published"
}
Add-MarkdownMetadata -FilePath "chemin/vers/document.md" -Metadata $metadata -Format "YAML"

# Ajouter des metadonnees au format inline
$metadata = @{
    priority = "medium"
    team = "qa"
    due = "2024-06-30"
}
Add-MarkdownMetadata -FilePath "chemin/vers/document.md" -Metadata $metadata -Format "Inline"

# Ajouter des metadonnees aux deux formats
$metadata = @{
    status = "published"
    priority = "high"
}
Add-MarkdownMetadata -FilePath "chemin/vers/document.md" -Metadata $metadata -Format "Both"
```

## Exemple complet

Voir le fichier `ExempleUtilisation.ps1` pour un exemple complet d'utilisation du module.

## Fonctions

### Get-DocumentMetadata

Extrait les metadonnees d'un document.

#### Parametres

- `Document` : Le document dont on veut extraire les metadonnees.
- `IncludeFields` : Les champs a inclure dans les metadonnees (par defaut : tous les champs).
- `ExcludeFields` : Les champs a exclure des metadonnees (par defaut : "content").

### Add-DocumentMetadata

Ajoute ou met a jour des metadonnees dans un document.

#### Parametres

- `Document` : Le document auquel on veut ajouter des metadonnees.
- `Metadata` : Les metadonnees a ajouter ou mettre a jour.
- `Force` : Indique si les metadonnees existantes doivent etre mises a jour (par defaut : $false).

### Remove-DocumentMetadata

Supprime des metadonnees d'un document.

#### Parametres

- `Document` : Le document dont on veut supprimer des metadonnees.
- `Fields` : Les champs a supprimer.

### Get-MarkdownMetadata

Extrait les metadonnees d'un fichier markdown.

#### Parametres

- `FilePath` : Le chemin du fichier markdown.

### Add-MarkdownMetadata

Ajoute ou met a jour des metadonnees dans un fichier markdown.

#### Parametres

- `FilePath` : Le chemin du fichier markdown.
- `Metadata` : Les metadonnees a ajouter ou mettre a jour.
- `Format` : Le format des metadonnees a ajouter (YAML, Inline, Both).

## Exemples d'utilisation avancee

### Indexation d'un repertoire de fichiers markdown

```powershell
# Fonction pour indexer un repertoire de fichiers markdown
function Index-MarkdownDirectory {
    param (
        [string]$DirectoryPath,
        [string]$OutputPath,
        [switch]$Recursive
    )
    
    # Rechercher les fichiers markdown
    $markdownFiles = Get-ChildItem -Path $DirectoryPath -Filter "*.md" -Recurse:$Recursive
    
    # Indexer chaque fichier
    $documents = @()
    foreach ($file in $markdownFiles) {
        $metadata = Get-MarkdownMetadata -FilePath $file.FullName
        $content = Get-Content -Path $file.FullName -Raw
        
        $document = [PSCustomObject]@{
            id = [guid]::NewGuid().ToString()
            title = if ($metadata.ContainsKey("title")) { $metadata["title"] } else { "Sans titre" }
            content = $content
            file_path = $file.FullName
        }
        
        # Ajouter les metadonnees au document
        foreach ($key in $metadata.Keys) {
            if (-not $document.PSObject.Properties.Match($key).Count) {
                $document | Add-Member -MemberType NoteProperty -Name $key -Value $metadata[$key]
            }
        }
        
        $documents += $document
    }
    
    # Enregistrer l'index
    $indexPath = Join-Path -Path $OutputPath -ChildPath "index.json"
    $documents | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8
    
    return $documents
}
```

### Recherche dans l'index

```powershell
# Fonction pour rechercher dans l'index
function Search-Index {
    param (
        [string]$IndexPath,
        [string]$SearchTerm = "",
        [hashtable]$Filters = @{},
        [int]$MaxResults = 10
    )
    
    # Charger l'index
    $documents = Get-Content -Path $IndexPath -Raw | ConvertFrom-Json
    
    # Filtrer les documents par terme de recherche
    if (-not [string]::IsNullOrEmpty($SearchTerm)) {
        $documents = $documents | Where-Object {
            $_.content -like "*$SearchTerm*" -or $_.title -like "*$SearchTerm*"
        }
    }
    
    # Appliquer les filtres
    foreach ($key in $Filters.Keys) {
        $value = $Filters[$key]
        $documents = $documents | Where-Object {
            $_.PSObject.Properties.Match($key).Count -and $_.$key -eq $value
        }
    }
    
    # Limiter le nombre de resultats
    $documents = $documents | Select-Object -First $MaxResults
    
    return $documents
}
```

## Licence

Ce module est distribue sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
