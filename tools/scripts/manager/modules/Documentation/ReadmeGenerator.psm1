# Module de génération de README pour le Script Manager
# Ce module génère des fichiers README pour chaque dossier de scripts
# Author: Script Manager
# Version: 1.0
# Tags: documentation, readme, scripts

function New-FolderReadmes {
    <#
    .SYNOPSIS
        Génère des fichiers README pour chaque dossier de scripts
    .DESCRIPTION
        Analyse la structure des dossiers et génère un README.md pour chaque dossier
        contenant une description, la liste des scripts et des exemples d'utilisation
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin où enregistrer les fichiers README
    .EXAMPLE
        New-FolderReadmes -Analysis $analysis -OutputPath "docs"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer un tableau pour stocker les résultats
    $Results = @()
    
    # Obtenir tous les dossiers uniques contenant des scripts
    $Folders = $Analysis.Scripts | ForEach-Object { Split-Path -Parent $_.Path } | Sort-Object -Unique
    
    Write-Host "Génération de README pour $($Folders.Count) dossiers..." -ForegroundColor Cyan
    
    # Traiter chaque dossier
    foreach ($Folder in $Folders) {
        # Obtenir le nom du dossier
        $FolderName = Split-Path -Leaf $Folder
        
        # Obtenir les scripts dans ce dossier
        $FolderScripts = $Analysis.Scripts | Where-Object { (Split-Path -Parent $_.Path) -eq $Folder }
        
        # Créer le chemin du README
        $ReadmePath = Join-Path -Path $Folder -ChildPath "README.md"
        
        # Générer le contenu du README
        $ReadmeContent = Get-ReadmeContent -FolderName $FolderName -FolderScripts $FolderScripts
        
        # Enregistrer le README
        try {
            Set-Content -Path $ReadmePath -Value $ReadmeContent
            Write-Host "  README généré: $ReadmePath" -ForegroundColor Green
            
            # Ajouter le résultat au tableau
            $Results += [PSCustomObject]@{
                FolderPath = $Folder
                FolderName = $FolderName
                ReadmePath = $ReadmePath
                ScriptCount = $FolderScripts.Count
                Success = $true
            }
        } catch {
            Write-Warning "Erreur lors de la création du README pour $Folder : $_"
            
            # Ajouter le résultat au tableau
            $Results += [PSCustomObject]@{
                FolderPath = $Folder
                FolderName = $FolderName
                ReadmePath = $ReadmePath
                ScriptCount = $FolderScripts.Count
                Success = $false
                Error = $_.ToString()
            }
        }
    }
    
    # Créer une copie des README dans le dossier de documentation
    foreach ($Result in $Results | Where-Object { $_.Success }) {
        $DocsFolderPath = Join-Path -Path $OutputPath -ChildPath "folders"
        $DocsFolderPath = Join-Path -Path $DocsFolderPath -ChildPath $Result.FolderName
        
        if (-not (Test-Path -Path $DocsFolderPath)) {
            New-Item -ItemType Directory -Path $DocsFolderPath -Force | Out-Null
        }
        
        $DocsReadmePath = Join-Path -Path $DocsFolderPath -ChildPath "README.md"
        
        try {
            Copy-Item -Path $Result.ReadmePath -Destination $DocsReadmePath -Force
        } catch {
            Write-Warning "Erreur lors de la copie du README vers $DocsReadmePath : $_"
        }
    }
    
    return $Results
}

function Get-ReadmeContent {
    <#
    .SYNOPSIS
        Génère le contenu d'un fichier README pour un dossier
    .DESCRIPTION
        Crée un contenu de README adapté au dossier et aux scripts qu'il contient
    .PARAMETER FolderName
        Nom du dossier
    .PARAMETER FolderScripts
        Scripts contenus dans le dossier
    .EXAMPLE
        Get-ReadmeContent -FolderName "utils" -FolderScripts $scripts
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderName,
        
        [Parameter(Mandatory=$true)]
        [array]$FolderScripts
    )
    
    # Déterminer la catégorie du dossier
    $Category = switch -Regex ($FolderName.ToLower()) {
        "utils?" { "Utilitaires" }
        "doc(s|umentation)?" { "Documentation" }
        "test(s|ing)?" { "Tests" }
        "api" { "API" }
        "setup" { "Installation et configuration" }
        "config(uration)?" { "Configuration" }
        "workflow" { "Workflows" }
        "email" { "Gestion des emails" }
        "git" { "Gestion de Git" }
        "journal" { "Journal de bord" }
        "roadmap" { "Gestion de la roadmap" }
        "n8n" { "Intégration n8n" }
        "mcp" { "Model Context Protocol" }
        "encoding" { "Gestion de l'encodage" }
        "security" { "Sécurité" }
        "database" { "Base de données" }
        "maintenance" { "Maintenance" }
        default { "Scripts" }
    }
    
    # Générer une description
    $Description = switch -Regex ($FolderName.ToLower()) {
        "utils?" { "Scripts utilitaires pour diverses tâches courantes." }
        "doc(s|umentation)?" { "Scripts liés à la génération et la gestion de la documentation." }
        "test(s|ing)?" { "Scripts de test pour valider le fonctionnement des autres scripts." }
        "api" { "Scripts d'intégration avec diverses API." }
        "setup" { "Scripts d'installation et de configuration de l'environnement." }
        "config(uration)?" { "Scripts et fichiers de configuration." }
        "workflow" { "Scripts liés à la gestion des workflows." }
        "email" { "Scripts pour la gestion et l'envoi d'emails." }
        "git" { "Scripts d'intégration avec Git." }
        "journal" { "Scripts liés au journal de bord et à la documentation des activités." }
        "roadmap" { "Scripts pour la gestion et la mise à jour de la roadmap." }
        "n8n" { "Scripts d'intégration avec la plateforme n8n." }
        "mcp" { "Scripts liés au Model Context Protocol." }
        "encoding" { "Scripts pour la gestion de l'encodage des fichiers." }
        "security" { "Scripts liés à la sécurité et à l'authentification." }
        "database" { "Scripts d'interaction avec les bases de données." }
        "maintenance" { "Scripts de maintenance du système." }
        default { "Collection de scripts pour diverses tâches." }
    }
    
    # Générer la liste des scripts
    $ScriptsList = $FolderScripts | ForEach-Object {
        $ScriptName = $_.Name
        $ScriptDescription = if ($_.StaticAnalysis.CommentCount -gt 0) {
            # Essayer d'extraire une description des commentaires
            $FirstComment = (Get-Content -Path $_.Path -TotalCount 10) -match "^#" | Select-Object -First 1
            if ($FirstComment) {
                $FirstComment -replace "^#\s*", ""
            } else {
                "Script $($_.Type)"
            }
        } else {
            "Script $($_.Type)"
        }
        
        "- **[$ScriptName]($ScriptName)** - $ScriptDescription"
    }
    
    # Générer des exemples d'utilisation
    $Examples = $FolderScripts | Where-Object { $_.Type -eq "PowerShell" } | Select-Object -First 3 | ForEach-Object {
        $ScriptName = $_.Name
        $ScriptPath = $_.Path
        
        @"
### Exemple d'utilisation de $ScriptName

```powershell
# Exécuter le script
.\$ScriptName

# Ou avec des paramètres (si applicable)
# .\$ScriptName -Param1 Value1 -Param2 Value2
```
"@
    }
    
    # Générer le contenu complet du README
    $Content = @"
# $Category - $FolderName

$Description

## Contenu du dossier

Ce dossier contient les scripts suivants :

$($ScriptsList -join "`n")

## Utilisation

$($Examples -join "`n`n")

## Bonnes pratiques

- Suivre les principes SOLID, DRY, KISS et Clean Code
- Utiliser des chemins relatifs et des variables d'environnement
- Documenter les scripts avec des commentaires
- Tester les scripts avant de les utiliser en production

## Maintenance

Ce README est généré automatiquement par le Script Manager. Pour mettre à jour la documentation, exécutez :

```powershell
.\scripts\manager\Phase3-DocumentAndMonitor.ps1
```

Dernière mise à jour : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    return $Content
}

# Exporter les fonctions
Export-ModuleMember -Function New-FolderReadmes, Get-ReadmeContent
