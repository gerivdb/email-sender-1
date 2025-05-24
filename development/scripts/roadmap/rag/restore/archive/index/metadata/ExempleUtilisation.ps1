# ExempleUtilisation.ps1
# Exemple d'utilisation du gestionnaire de metadonnees
# Version: 1.0
# Date: 2025-05-15

# Importer le module de gestion des metadonnees
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "MetadataManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier MetadataManager.ps1 est introuvable."
    exit 1
}

# Fonction pour creer un document a partir d'un fichier markdown
function New-DocumentFromMarkdown {
    param (
        [string]$FilePath
    )
    
    # Verifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }
    
    # Extraire les metadonnees du fichier
    $metadata = Get-MarkdownMetadata -FilePath $FilePath
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Supprimer le frontmatter YAML s'il existe
    if ($content -match "^---\s*\n([\s\S]*?)\n---") {
        $content = $content -replace "^---\s*\n([\s\S]*?)\n---", ""
    }
    
    # Creer le document
    $document = [PSCustomObject]@{
        id = [guid]::NewGuid().ToString()
        title = if ($metadata.ContainsKey("title")) { $metadata["title"] } else { "Sans titre" }
        content = $content.Trim()
        file_path = $FilePath
    }
    
    # Ajouter les metadonnees au document
    foreach ($key in $metadata.Keys) {
        if (-not $document.PSObject.Properties.Match($key).Count) {
            $document | Add-Member -MemberType NoteProperty -Name $key -Value $metadata[$key]
        }
    }
    
    return $document
}

# Fonction pour indexer un repertoire de fichiers markdown
function Add-MarkdownDirectory {
    param (
        [string]$DirectoryPath,
        [string]$OutputPath,
        [switch]$Recursive
    )
    
    # Verifier si le repertoire existe
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Error "Le repertoire n'existe pas: $DirectoryPath"
        return $null
    }
    
    # Creer le repertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath -PathType Container)) {
        New-Item -Path $OutputPath -ItemType Directory | Out-Null
    }
    
    # Rechercher les fichiers markdown
    $searchOption = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
    $markdownFiles = Get-ChildItem -Path $DirectoryPath -Filter "*.md" -Recurse:$Recursive
    
    # Indexer chaque fichier
    $documents = @()
    foreach ($file in $markdownFiles) {
        Write-Output "Indexation du fichier: $($file.FullName)"
        $document = New-DocumentFromMarkdown -FilePath $file.FullName
        if ($document) {
            $documents += $document
        }
    }
    
    # Enregistrer l'index
    $indexPath = Join-Path -Path $OutputPath -ChildPath "index.json"
    $documents | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8
    
    Write-Output "Index cree avec $($documents.Count) documents: $indexPath"
    
    return $documents
}

# Fonction pour rechercher dans l'index
function Search-Index {
    param (
        [string]$IndexPath,
        [string]$SearchTerm = "",
        [hashtable]$Filters = @{},
        [int]$MaxResults = 10
    )
    
    # Verifier si l'index existe
    if (-not (Test-Path -Path $IndexPath -PathType Leaf)) {
        Write-Error "L'index n'existe pas: $IndexPath"
        return $null
    }
    
    # Charger l'index
    $documents = Get-Content -Path $IndexPath -Raw | ConvertFrom-Json
    
    # Convertir les documents en objets PowerShell
    $documents = $documents | ForEach-Object {
        $document = [PSCustomObject]@{}
        foreach ($property in $_.PSObject.Properties) {
            $document | Add-Member -MemberType NoteProperty -Name $property.Name -Value $property.Value
        }
        $document
    }
    
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

# Fonction pour mettre a jour les metadonnees d'un document
function Update-DocumentMetadata {
    param (
        [PSObject]$Document,
        [hashtable]$Metadata,
        [switch]$UpdateFile
    )
    
    # Mettre a jour les metadonnees du document
    $updatedDocument = Add-DocumentMetadata -Document $Document -Metadata $Metadata -Force
    
    # Mettre a jour le fichier si demande
    if ($UpdateFile -and $updatedDocument.PSObject.Properties.Match("file_path").Count) {
        $filePath = $updatedDocument.file_path
        if (Test-Path -Path $filePath -PathType Leaf) {
            Add-MarkdownMetadata -FilePath $filePath -Metadata $Metadata -Format "YAML"
        }
    }
    
    return $updatedDocument
}

# Exemple 1: Creer un document a partir d'un fichier markdown
Write-Output "Exemple 1: Creer un document a partir d'un fichier markdown"
Write-Output "------------------------------------------------------"

# Creer un repertoire temporaire pour les exemples
$exampleDir = Join-Path -Path $scriptPath -ChildPath "examples"
if (-not (Test-Path -Path $exampleDir)) {
    New-Item -Path $exampleDir -ItemType Directory | Out-Null
}

# Creer un fichier markdown de test
$testFilePath = Join-Path -Path $exampleDir -ChildPath "exemple1.md"
$testFileContent = @"
---
title: Document d'exemple
author: Jean Dupont
date: 2024-05-15
status: draft
tags: exemple, metadata, test
---

# Document d'exemple

Ceci est un document d'exemple pour montrer comment utiliser le gestionnaire de metadonnees.

## Section 1

Cette section contient des informations importantes #priority:high #category:documentation

## Section 2

Cette tache doit etre terminee (due:2024-06-30) par l'equipe (team:dev)
"@
Set-Content -Path $testFilePath -Value $testFileContent

# Creer un document a partir du fichier
$document = New-DocumentFromMarkdown -FilePath $testFilePath
Write-Output "Document cree a partir du fichier markdown:"
$document | Format-List
Write-Output ""

# Exemple 2: Indexer un repertoire de fichiers markdown
Write-Output "Exemple 2: Indexer un repertoire de fichiers markdown"
Write-Output "------------------------------------------------"

# Creer d'autres fichiers markdown de test
$testFile2Path = Join-Path -Path $exampleDir -ChildPath "exemple2.md"
$testFile2Content = @"
---
title: Guide d'utilisation
author: Marie Martin
date: 2024-04-10
status: published
tags: guide, documentation
---

# Guide d'utilisation

Ce guide explique comment utiliser le produit.

## Installation

Instructions d'installation...

## Configuration

Instructions de configuration...
"@
Set-Content -Path $testFile2Path -Value $testFile2Content

$testFile3Path = Join-Path -Path $exampleDir -ChildPath "exemple3.md"
$testFile3Content = @"
---
title: Notes de reunion
author: Pierre Durand
date: 2024-05-05
status: draft
tags: reunion, notes
---

# Notes de reunion

Notes de la reunion du 5 mai 2024.

## Participants

- Jean Dupont
- Marie Martin
- Pierre Durand

## Points discutes

- Point 1
- Point 2
- Point 3
"@
Set-Content -Path $testFile3Path -Value $testFile3Content

# Indexer le repertoire
$indexDir = Join-Path -Path $exampleDir -ChildPath "index"
if (-not (Test-Path -Path $indexDir)) {
    New-Item -Path $indexDir -ItemType Directory | Out-Null
}
$documents = Add-MarkdownDirectory -DirectoryPath $exampleDir -OutputPath $indexDir
Write-Output ""

# Exemple 3: Rechercher dans l'index
Write-Output "Exemple 3: Rechercher dans l'index"
Write-Output "-------------------------------"

# Rechercher par terme
$indexPath = Join-Path -Path $indexDir -ChildPath "index.json"
$searchResults = Search-Index -IndexPath $indexPath -SearchTerm "document"
Write-Output "Resultats de la recherche pour 'document':"
foreach ($result in $searchResults) {
    Write-Output "- $($result.title) (Auteur: $($result.author), Statut: $($result.status))"
}
Write-Output ""

# Rechercher avec filtres
$filters = @{
    status = "draft"
    author = "Jean Dupont"
}
$searchResults = Search-Index -IndexPath $indexPath -Filters $filters
Write-Output "Resultats de la recherche avec filtres (status=draft, author=Jean Dupont):"
foreach ($result in $searchResults) {
    Write-Output "- $($result.title) (Auteur: $($result.author), Statut: $($result.status))"
}
Write-Output ""

# Exemple 4: Mettre a jour les metadonnees
Write-Output "Exemple 4: Mettre a jour les metadonnees"
Write-Output "----------------------------------"

# Mettre a jour les metadonnees d'un document
$document = $searchResults[0]
$newMetadata = @{
    status = "published"
    priority = "medium"
    reviewed_by = "Sophie Lefebvre"
    review_date = (Get-Date).ToString("yyyy-MM-dd")
}
$updatedDocument = Update-DocumentMetadata -Document $document -Metadata $newMetadata -UpdateFile
Write-Output "Document mis a jour:"
$updatedDocument | Format-List
Write-Output ""

# Nettoyer les fichiers d'exemple
Write-Output "Nettoyage des fichiers d'exemple..."
Remove-Item -Path $exampleDir -Recurse -Force

Write-Output "Tous les exemples sont termines."

