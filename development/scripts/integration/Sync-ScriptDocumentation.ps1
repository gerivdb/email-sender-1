#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronise l'inventaire des scripts avec le systÃ¨me de documentation
.DESCRIPTION
    Ce script gÃ©nÃ¨re et met Ã  jour la documentation Ã  partir des mÃ©tadonnÃ©es
    des scripts dans l'inventaire.
.PARAMETER Path
    Chemin du rÃ©pertoire Ã  analyser
.PARAMETER DocsPath
    Chemin du rÃ©pertoire de documentation
.PARAMETER UpdateExisting
    Indique s'il faut mettre Ã  jour la documentation existante
.EXAMPLE
    .\Sync-ScriptDocumentation.ps1 -Path "C:\Scripts" -DocsPath "C:\Scripts\docs"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: documentation, scripts, intÃ©gration
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

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Fonction pour gÃ©nÃ©rer la documentation d'un script
function New-ScriptDocumentation {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $Script.FullPath -Raw -ErrorAction SilentlyContinue
    
    # Extraire les fonctions et les paramÃ¨tres
    $functions = @()
    $parameters = @()
    
    if ($Script.Language -like "PowerShell*") {
        # Extraire les fonctions PowerShell
        $functionMatches = [regex]::Matches($content, '(?:function|filter)\s+([A-Za-z0-9\-_]+)')
        foreach ($match in $functionMatches) {
            $functions += $match.Groups[1].Value
        }
        
        # Extraire les paramÃ¨tres PowerShell
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
    
    # GÃ©nÃ©rer le contenu de la documentation
    $doc = @"
# $($Script.FileName)

## Informations gÃ©nÃ©rales

- **Nom du fichier**: $($Script.FileName)
- **Chemin**: $($Script.FullPath)
- **Langage**: $($Script.Language)
- **Auteur**: $($Script.Author)
- **Version**: $($Script.Version)
- **CatÃ©gorie**: $($Script.Category)
- **Sous-catÃ©gorie**: $($Script.SubCategory)
- **DerniÃ¨re modification**: $($Script.LastModified)
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
    
    # Ajouter les paramÃ¨tres si disponibles
    if ($parameters.Count -gt 0) {
        $doc += @"

## ParamÃ¨tres

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
- [Retour Ã  l'index](../index.md)

---

*Documentation gÃ©nÃ©rÃ©e automatiquement le $(Get-Date -Format "yyyy-MM-dd") Ã  $(Get-Date -Format "HH:mm:ss")*

"@

    # Ã‰crire le fichier de documentation
    Set-Content -Path $OutputPath -Value $doc -Encoding UTF8
    
    return $OutputPath
}

# Fonction pour gÃ©nÃ©rer l'index de la documentation
function New-DocumentationIndex {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Scripts,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Grouper les scripts par catÃ©gorie
    $scriptsByCategory = $Scripts | Group-Object -Property Category
    
    # GÃ©nÃ©rer le contenu de l'index
    $index = @"
# Index de la Documentation des Scripts

## Vue d'ensemble

Cette documentation a Ã©tÃ© gÃ©nÃ©rÃ©e automatiquement Ã  partir de l'inventaire des scripts.
Elle contient des informations sur tous les scripts du projet, organisÃ©s par catÃ©gorie.

- **Nombre total de scripts**: $($Scripts.Count)
- **Nombre de catÃ©gories**: $($scriptsByCategory.Count)
- **Date de gÃ©nÃ©ration**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Scripts par catÃ©gorie

"@

    foreach ($category in $scriptsByCategory | Sort-Object -Property Name) {
        $index += @"

### $($category.Name)

$(foreach ($script in $category.Group | Sort-Object -Property FileName) {
    $docPath = "development/scripts/$($script.Category)/$($script.FileName.Replace('.', '_')).md"
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

- **Scripts rÃ©cemment modifiÃ©s**:
$(foreach ($script in ($Scripts | Sort-Object -Property LastModified -Descending | Select-Object -First 5)) {
    "  - $($script.FileName) ($(Get-Date $script.LastModified -Format 'yyyy-MM-dd'))"
})

---

*Documentation gÃ©nÃ©rÃ©e automatiquement le $(Get-Date -Format "yyyy-MM-dd") Ã  $(Get-Date -Format "HH:mm:ss")*

"@

    # Ã‰crire le fichier d'index
    Set-Content -Path $OutputPath -Value $index -Encoding UTF8
    
    return $OutputPath
}

# RÃ©cupÃ©rer les scripts
Write-Host "RÃ©cupÃ©ration des scripts..." -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $Path

# VÃ©rifier qu'il y a des scripts
if (-not $scripts -or $scripts.Count -eq 0) {
    Write-Host "Aucun script trouvÃ© dans le rÃ©pertoire spÃ©cifiÃ©." -ForegroundColor Red
    exit
}

# CrÃ©er le rÃ©pertoire de documentation s'il n'existe pas
if (-not (Test-Path $DocsPath)) {
    New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
    Write-Host "RÃ©pertoire de documentation crÃ©Ã©: $DocsPath" -ForegroundColor Green
}

# CrÃ©er le rÃ©pertoire pour les scripts
$scriptsDocsPath = Join-Path -Path $DocsPath -ChildPath "scripts"
if (-not (Test-Path $scriptsDocsPath)) {
    New-Item -ItemType Directory -Path $scriptsDocsPath -Force | Out-Null
}

# GÃ©nÃ©rer la documentation pour chaque script
$docsGenerated = 0
$docsUpdated = 0
$docsSkipped = 0

foreach ($script in $scripts) {
    # CrÃ©er le rÃ©pertoire pour la catÃ©gorie
    $categoryPath = Join-Path -Path $scriptsDocsPath -ChildPath $script.Category
    if (-not (Test-Path $categoryPath)) {
        New-Item -ItemType Directory -Path $categoryPath -Force | Out-Null
    }
    
    # Chemin du fichier de documentation
    $docFileName = $script.FileName.Replace('.', '_') + ".md"
    $docPath = Join-Path -Path $categoryPath -ChildPath $docFileName
    
    # VÃ©rifier si le fichier existe dÃ©jÃ 
    $fileExists = Test-Path $docPath
    
    if (-not $fileExists -or $UpdateExisting) {
        # GÃ©nÃ©rer la documentation
        New-ScriptDocumentation -Script $script -OutputPath $docPath | Out-Null
        
        if ($fileExists) {
            $docsUpdated++
            Write-Host "Documentation mise Ã  jour: $docPath" -ForegroundColor Yellow
        } else {
            $docsGenerated++
            Write-Host "Documentation gÃ©nÃ©rÃ©e: $docPath" -ForegroundColor Green
        }
    } else {
        $docsSkipped++
        Write-Host "Documentation existante ignorÃ©e: $docPath" -ForegroundColor Gray
    }
}

# GÃ©nÃ©rer l'index
$indexPath = Join-Path -Path $DocsPath -ChildPath "index.md"
New-DocumentationIndex -Scripts $scripts -OutputPath $indexPath | Out-Null
Write-Host "Index gÃ©nÃ©rÃ©: $indexPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ©:" -ForegroundColor Cyan
Write-Host "- Documentation gÃ©nÃ©rÃ©e pour $docsGenerated scripts" -ForegroundColor Green
Write-Host "- Documentation mise Ã  jour pour $docsUpdated scripts" -ForegroundColor Yellow
Write-Host "- Documentation existante ignorÃ©e pour $docsSkipped scripts" -ForegroundColor Gray
Write-Host "- Index gÃ©nÃ©rÃ© avec $($scripts.Count) scripts" -ForegroundColor Green

# Demander Ã  l'utilisateur s'il veut ouvrir l'index
$openIndex = Read-Host "Voulez-vous ouvrir l'index de la documentation? (O/N)"
if ($openIndex -eq "O" -or $openIndex -eq "o") {
    Start-Process $indexPath
}
