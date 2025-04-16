#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronise l'inventaire des scripts avec le système de documentation
.DESCRIPTION
    Ce script génère et met à jour la documentation à partir des métadonnées
    des scripts dans l'inventaire.
.PARAMETER Path
    Chemin du répertoire à analyser
.PARAMETER DocsPath
    Chemin du répertoire de documentation
.PARAMETER UpdateExisting
    Indique s'il faut mettre à jour la documentation existante
.EXAMPLE
    .\Sync-ScriptDocumentation.ps1 -Path "C:\Scripts" -DocsPath "C:\Scripts\docs"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: documentation, scripts, intégration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string]$DocsPath = (Join-Path -Path (Get-Location).Path -ChildPath "docs"),
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateExisting
)

# Importer les modules nécessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Fonction pour générer la documentation d'un script
function New-ScriptDocumentation {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $Script.FullPath -Raw -ErrorAction SilentlyContinue
    
    # Extraire les fonctions et les paramètres
    $functions = @()
    $parameters = @()
    
    if ($Script.Language -like "PowerShell*") {
        # Extraire les fonctions PowerShell
        $functionMatches = [regex]::Matches($content, '(?:function|filter)\s+([A-Za-z0-9\-_]+)')
        foreach ($match in $functionMatches) {
            $functions += $match.Groups[1].Value
        }
        
        # Extraire les paramètres PowerShell
        $paramMatches = [regex]::Matches($content, 'param\s*\(\s*(?:\[Parameter.*?\])?\s*\[([^\]]+)\]\s*\$([A-Za-z0-9\-_]+)')
        foreach ($match in $paramMatches) {
            $paramType = $match.Groups[1].Value
            $paramName = $match.Groups[2].Value
            $parameters += "$paramName ($paramType)"
        }
    }
    elseif ($Script.Language -eq "Python") {
        # Extraire les fonctions Python
        $functionMatches = [regex]::Matches($content, 'def\s+([A-Za-z0-9_]+)\s*\(')
        foreach ($match in $functionMatches) {
            $functions += $match.Groups[1].Value
        }
        
        # Extraire les classes Python
        $classMatches = [regex]::Matches($content, 'class\s+([A-Za-z0-9_]+)')
        foreach ($match in $classMatches) {
            $functions += "class $($match.Groups[1].Value)"
        }
    }
    
    # Générer le contenu de la documentation
    $doc = @"
# $($Script.FileName)

## Informations générales

- **Nom du fichier**: $($Script.FileName)
- **Chemin**: $($Script.FullPath)
- **Langage**: $($Script.Language)
- **Auteur**: $($Script.Author)
- **Version**: $($Script.Version)
- **Catégorie**: $($Script.Category)
- **Sous-catégorie**: $($Script.SubCategory)
- **Dernière modification**: $($Script.LastModified)
- **Nombre de lignes**: $($Script.LineCount)

## Description

$($Script.Description)

## Tags

$(if ($Script.Tags) { $Script.Tags -join ", " } else { "Aucun tag" })

"@

    # Ajouter les fonctions si disponibles
    if ($functions.Count -gt 0) {
        $doc += @"

## Fonctions

$(foreach ($function in $functions) { "- `$function`" })

"@
    }
    
    # Ajouter les paramètres si disponibles
    if ($parameters.Count -gt 0) {
        $doc += @"

## Paramètres

$(foreach ($parameter in $parameters) { "- `$parameter`" })

"@
    }
    
    # Ajouter un extrait du code
    $doc += @"

## Extrait du code

```$($Script.Language.ToLower())
$(if ($content) { $content.Substring(0, [Math]::Min(500, $content.Length)) + (if ($content.Length -gt 500) { "..." } else { "" }) } else { "Contenu non disponible" })
```

## Liens

- [Voir le fichier complet]($($Script.FullPath))
- [Retour à l'index](../index.md)

---

*Documentation générée automatiquement le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm:ss")*

"@

    # Écrire le fichier de documentation
    Set-Content -Path $OutputPath -Value $doc -Encoding UTF8
    
    return $OutputPath
}

# Fonction pour générer l'index de la documentation
function New-DocumentationIndex {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Scripts,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Grouper les scripts par catégorie
    $scriptsByCategory = $Scripts | Group-Object -Property Category
    
    # Générer le contenu de l'index
    $index = @"
# Index de la Documentation des Scripts

## Vue d'ensemble

Cette documentation a été générée automatiquement à partir de l'inventaire des scripts.
Elle contient des informations sur tous les scripts du projet, organisés par catégorie.

- **Nombre total de scripts**: $($Scripts.Count)
- **Nombre de catégories**: $($scriptsByCategory.Count)
- **Date de génération**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Scripts par catégorie

"@

    foreach ($category in $scriptsByCategory | Sort-Object -Property Name) {
        $index += @"

### $($category.Name)

$(foreach ($script in $category.Group | Sort-Object -Property FileName) {
    $docPath = "scripts/$($script.Category)/$($script.FileName.Replace('.', '_')).md"
    "- [$($script.FileName)]($docPath) - $($script.Description)"
})

"@
    }
    
    # Ajouter des informations sur les langages
    $index += @"

## Scripts par langage

$(foreach ($language in ($Scripts | Group-Object -Property Language | Sort-Object -Property Name)) {
    "### $($language.Name) ($($language.Count) scripts)"
})

## Statistiques

- **Scripts les plus grands**:
$(foreach ($script in ($Scripts | Sort-Object -Property LineCount -Descending | Select-Object -First 5)) {
    "  - $($script.FileName) ($($script.LineCount) lignes)"
})

- **Scripts récemment modifiés**:
$(foreach ($script in ($Scripts | Sort-Object -Property LastModified -Descending | Select-Object -First 5)) {
    "  - $($script.FileName) ($(Get-Date $script.LastModified -Format 'yyyy-MM-dd'))"
})

---

*Documentation générée automatiquement le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm:ss")*

"@

    # Écrire le fichier d'index
    Set-Content -Path $OutputPath -Value $index -Encoding UTF8
    
    return $OutputPath
}

# Récupérer les scripts
Write-Host "Récupération des scripts..." -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $Path

# Vérifier qu'il y a des scripts
if (-not $scripts -or $scripts.Count -eq 0) {
    Write-Host "Aucun script trouvé dans le répertoire spécifié." -ForegroundColor Red
    exit
}

# Créer le répertoire de documentation s'il n'existe pas
if (-not (Test-Path $DocsPath)) {
    New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
    Write-Host "Répertoire de documentation créé: $DocsPath" -ForegroundColor Green
}

# Créer le répertoire pour les scripts
$scriptsDocsPath = Join-Path -Path $DocsPath -ChildPath "scripts"
if (-not (Test-Path $scriptsDocsPath)) {
    New-Item -ItemType Directory -Path $scriptsDocsPath -Force | Out-Null
}

# Générer la documentation pour chaque script
$docsGenerated = 0
$docsUpdated = 0
$docsSkipped = 0

foreach ($script in $scripts) {
    # Créer le répertoire pour la catégorie
    $categoryPath = Join-Path -Path $scriptsDocsPath -ChildPath $script.Category
    if (-not (Test-Path $categoryPath)) {
        New-Item -ItemType Directory -Path $categoryPath -Force | Out-Null
    }
    
    # Chemin du fichier de documentation
    $docFileName = $script.FileName.Replace('.', '_') + ".md"
    $docPath = Join-Path -Path $categoryPath -ChildPath $docFileName
    
    # Vérifier si le fichier existe déjà
    $fileExists = Test-Path $docPath
    
    if (-not $fileExists -or $UpdateExisting) {
        # Générer la documentation
        New-ScriptDocumentation -Script $script -OutputPath $docPath | Out-Null
        
        if ($fileExists) {
            $docsUpdated++
            Write-Host "Documentation mise à jour: $docPath" -ForegroundColor Yellow
        } else {
            $docsGenerated++
            Write-Host "Documentation générée: $docPath" -ForegroundColor Green
        }
    } else {
        $docsSkipped++
        Write-Host "Documentation existante ignorée: $docPath" -ForegroundColor Gray
    }
}

# Générer l'index
$indexPath = Join-Path -Path $DocsPath -ChildPath "index.md"
New-DocumentationIndex -Scripts $scripts -OutputPath $indexPath | Out-Null
Write-Host "Index généré: $indexPath" -ForegroundColor Green

# Afficher un résumé
Write-Host "`nRésumé:" -ForegroundColor Cyan
Write-Host "- Documentation générée pour $docsGenerated scripts" -ForegroundColor Green
Write-Host "- Documentation mise à jour pour $docsUpdated scripts" -ForegroundColor Yellow
Write-Host "- Documentation existante ignorée pour $docsSkipped scripts" -ForegroundColor Gray
Write-Host "- Index généré avec $($scripts.Count) scripts" -ForegroundColor Green

# Demander à l'utilisateur s'il veut ouvrir l'index
$openIndex = Read-Host "Voulez-vous ouvrir l'index de la documentation? (O/N)"
if ($openIndex -eq "O" -or $openIndex -eq "o") {
    Start-Process $indexPath
}
