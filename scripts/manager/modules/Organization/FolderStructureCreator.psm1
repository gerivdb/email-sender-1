# Module de création de structure de dossiers pour le Script Manager
# Ce module crée une structure de dossiers sémantiques
# Author: Script Manager
# Version: 1.0
# Tags: organization, folders, structure

function New-FolderStructure {
    <#
    .SYNOPSIS
        Crée une structure de dossiers sémantiques
    .DESCRIPTION
        Crée une structure de dossiers basée sur les règles de classification
    .PARAMETER Rules
        Règles de classification
    .PARAMETER AutoApply
        Applique automatiquement la création des dossiers
    .EXAMPLE
        New-FolderStructure -Rules $rules -AutoApply
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Rules,
        
        [switch]$AutoApply
    )
    
    # Initialiser le tableau des dossiers
    $Folders = @()
    
    # Extraire les destinations des règles
    $Destinations = @()
    foreach ($Rule in $Rules.rules) {
        foreach ($Condition in $Rule.conditions) {
            if ($Condition.destination) {
                $Destinations += $Condition.destination
            }
        }
    }
    
    # Éliminer les doublons
    $Destinations = $Destinations | Sort-Object -Unique
    
    # Créer les dossiers
    foreach ($Destination in $Destinations) {
        # Vérifier si le dossier existe déjà
        $FolderExists = Test-Path -Path $Destination
        
        # Créer un objet pour représenter le dossier
        $Folder = [PSCustomObject]@{
            Path = $Destination
            Exists = $FolderExists
            Created = $false
            ReadmeCreated = $false
        }
        
        # Créer le dossier si nécessaire
        if (-not $FolderExists -and $AutoApply) {
            try {
                New-Item -ItemType Directory -Path $Destination -Force | Out-Null
                $Folder.Created = $true
                Write-Host "  Dossier créé: $Destination" -ForegroundColor Green
                
                # Créer un fichier README.md dans le dossier
                $ReadmePath = Join-Path -Path $Destination -ChildPath "README.md"
                $ReadmeContent = Get-FolderReadmeContent -FolderPath $Destination
                Set-Content -Path $ReadmePath -Value $ReadmeContent
                $Folder.ReadmeCreated = $true
                Write-Host "  README créé: $ReadmePath" -ForegroundColor Green
            } catch {
                Write-Warning "Erreur lors de la création du dossier $Destination : $_"
            }
        } elseif (-not $FolderExists) {
            Write-Host "  Dossier à créer: $Destination" -ForegroundColor Yellow
        } else {
            Write-Host "  Dossier existant: $Destination" -ForegroundColor Cyan
            
            # Vérifier si un README.md existe dans le dossier
            $ReadmePath = Join-Path -Path $Destination -ChildPath "README.md"
            if (-not (Test-Path -Path $ReadmePath) -and $AutoApply) {
                # Créer un fichier README.md dans le dossier
                $ReadmeContent = Get-FolderReadmeContent -FolderPath $Destination
                Set-Content -Path $ReadmePath -Value $ReadmeContent
                $Folder.ReadmeCreated = $true
                Write-Host "  README créé: $ReadmePath" -ForegroundColor Green
            }
        }
        
        # Ajouter le dossier au tableau
        $Folders += $Folder
    }
    
    return $Folders
}

function Get-FolderReadmeContent {
    <#
    .SYNOPSIS
        Génère le contenu d'un fichier README.md pour un dossier
    .DESCRIPTION
        Génère un contenu de README.md adapté au type de dossier
    .PARAMETER FolderPath
        Chemin du dossier
    .EXAMPLE
        Get-FolderReadmeContent -FolderPath "scripts/maintenance"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )
    
    # Extraire le nom du dossier
    $FolderName = Split-Path -Path $FolderPath -Leaf
    
    # Extraire la catégorie et la sous-catégorie
    $PathParts = $FolderPath -split "/"
    $Category = if ($PathParts.Count -gt 1) { $PathParts[1] } else { $FolderName }
    $SubCategory = if ($PathParts.Count -gt 2) { $PathParts[2] } else { "General" }
    
    # Générer le titre
    $Title = if ($SubCategory -ne "General") {
        "$Category - $SubCategory"
    } else {
        $Category
    }
    
    # Générer la description
    $Description = switch ($Category.ToLower()) {
        "maintenance" { "Scripts de maintenance du système" }
        "setup" { "Scripts d'installation et de configuration" }
        "workflow" { "Scripts liés aux workflows" }
        "utils" { "Scripts utilitaires" }
        "api" { "Scripts liés aux API" }
        "documentation" { "Scripts de génération de documentation" }
        "roadmap" { "Scripts liés à la roadmap" }
        "journal" { "Scripts liés au journal de bord" }
        "mcp" { "Scripts liés au Model Context Protocol" }
        "n8n" { "Scripts liés à n8n" }
        "git" { "Scripts liés à Git" }
        "encoding" { "Scripts liés à l'encodage des fichiers" }
        "email" { "Scripts liés à la gestion des emails" }
        "testing" { "Scripts de test" }
        "security" { "Scripts liés à la sécurité" }
        "database" { "Scripts liés aux bases de données" }
        default { "Scripts divers" }
    }
    
    # Générer le contenu du README
    $Content = @"
# $Title

$Description

## Contenu du dossier

Ce dossier contient les scripts suivants :

*(Cette liste sera mise à jour automatiquement)*

## Utilisation

*(À compléter)*

## Bonnes pratiques

- Suivre les principes SOLID, DRY, KISS et Clean Code
- Utiliser des chemins relatifs et des variables d'environnement
- Documenter les scripts avec des commentaires
- Tester les scripts avant de les utiliser en production
"@
    
    return $Content
}

# Exporter les fonctions
Export-ModuleMember -Function New-FolderStructure, Get-FolderReadmeContent
