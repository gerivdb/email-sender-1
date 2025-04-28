# Module de gÃ©nÃ©ration de README pour le Script Manager
# Ce module gÃ©nÃ¨re des fichiers README pour chaque dossier de scripts
# Author: Script Manager
# Version: 1.0
# Tags: documentation, readme, scripts

function New-FolderReadmes {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re des fichiers README pour chaque dossier de scripts
    .DESCRIPTION
        Analyse la structure des dossiers et gÃ©nÃ¨re un README.md pour chaque dossier
        contenant une description, la liste des scripts et des exemples d'utilisation
    .PARAMETER Analysis
        Objet d'analyse des scripts
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les fichiers README
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
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $Results = @()
    
    # Obtenir tous les dossiers uniques contenant des scripts
    $Folders = $Analysis.Scripts | ForEach-Object { Split-Path -Parent $_.Path } | Sort-Object -Unique
    
    Write-Host "GÃ©nÃ©ration de README pour $($Folders.Count) dossiers..." -ForegroundColor Cyan
    
    # Traiter chaque dossier
    foreach ($Folder in $Folders) {
        # Obtenir le nom du dossier
        $FolderName = Split-Path -Leaf $Folder
        
        # Obtenir les scripts dans ce dossier
        $FolderScripts = $Analysis.Scripts | Where-Object { (Split-Path -Parent $_.Path) -eq $Folder }
        
        # CrÃ©er le chemin du README
        $ReadmePath = Join-Path -Path $Folder -ChildPath "README.md"
        
        # GÃ©nÃ©rer le contenu du README
        $ReadmeContent = Get-ReadmeContent -FolderName $FolderName -FolderScripts $FolderScripts
        
        # Enregistrer le README
        try {
            Set-Content -Path $ReadmePath -Value $ReadmeContent
            Write-Host "  README gÃ©nÃ©rÃ©: $ReadmePath" -ForegroundColor Green
            
            # Ajouter le rÃ©sultat au tableau
            $Results += [PSCustomObject]@{
                FolderPath = $Folder
                FolderName = $FolderName
                ReadmePath = $ReadmePath
                ScriptCount = $FolderScripts.Count
                Success = $true
            }
        } catch {
            Write-Warning "Erreur lors de la crÃ©ation du README pour $Folder : $_"
            
            # Ajouter le rÃ©sultat au tableau
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
    
    # CrÃ©er une copie des README dans le dossier de documentation
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
        GÃ©nÃ¨re le contenu d'un fichier README pour un dossier
    .DESCRIPTION
        CrÃ©e un contenu de README adaptÃ© au dossier et aux scripts qu'il contient
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
    
    # DÃ©terminer la catÃ©gorie du dossier
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
        "n8n" { "IntÃ©gration n8n" }
        "mcp" { "Model Context Protocol" }
        "encoding" { "Gestion de l'encodage" }
        "security" { "SÃ©curitÃ©" }
        "database" { "Base de donnÃ©es" }
        "maintenance" { "Maintenance" }
        default { "Scripts" }
    }
    
    # GÃ©nÃ©rer une description
    $Description = switch -Regex ($FolderName.ToLower()) {
        "utils?" { "Scripts utilitaires pour diverses tÃ¢ches courantes." }
        "doc(s|umentation)?" { "Scripts liÃ©s Ã  la gÃ©nÃ©ration et la gestion de la documentation." }
        "test(s|ing)?" { "Scripts de test pour valider le fonctionnement des autres scripts." }
        "api" { "Scripts d'intÃ©gration avec diverses API." }
        "setup" { "Scripts d'installation et de configuration de l'environnement." }
        "config(uration)?" { "Scripts et fichiers de configuration." }
        "workflow" { "Scripts liÃ©s Ã  la gestion des workflows." }
        "email" { "Scripts pour la gestion et l'envoi d'emails." }
        "git" { "Scripts d'intÃ©gration avec Git." }
        "journal" { "Scripts liÃ©s au journal de bord et Ã  la documentation des activitÃ©s." }
        "roadmap" { "Scripts pour la gestion et la mise Ã  jour de la roadmap." }
        "n8n" { "Scripts d'intÃ©gration avec la plateforme n8n." }
        "mcp" { "Scripts liÃ©s au Model Context Protocol." }
        "encoding" { "Scripts pour la gestion de l'encodage des fichiers." }
        "security" { "Scripts liÃ©s Ã  la sÃ©curitÃ© et Ã  l'authentification." }
        "database" { "Scripts d'interaction avec les bases de donnÃ©es." }
        "maintenance" { "Scripts de maintenance du systÃ¨me." }
        default { "Collection de scripts pour diverses tÃ¢ches." }
    }
    
    # GÃ©nÃ©rer la liste des scripts
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
    
    # GÃ©nÃ©rer des exemples d'utilisation
    $Examples = $FolderScripts | Where-Object { $_.Type -eq "PowerShell" } | Select-Object -First 3 | ForEach-Object {
        $ScriptName = $_.Name
        $ScriptPath = $_.Path
        
        @"
### Exemple d'utilisation de $ScriptName

```powershell
# ExÃ©cuter le script
.\$ScriptName

# Ou avec des paramÃ¨tres (si applicable)
# .\$ScriptName -Param1 Value1 -Param2 Value2
```
"@
    }
    
    # GÃ©nÃ©rer le contenu complet du README
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

Ce README est gÃ©nÃ©rÃ© automatiquement par le Script Manager. Pour mettre Ã  jour la documentation, exÃ©cutez :

```powershell
.\scripts\manager\Phase3-DocumentAndMonitor.ps1
```

DerniÃ¨re mise Ã  jour : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    return $Content
}

# Exporter les fonctions
Export-ModuleMember -Function New-FolderReadmes, Get-ReadmeContent
