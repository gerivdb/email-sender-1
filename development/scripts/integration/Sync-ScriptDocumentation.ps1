#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronise l'inventaire des scripts avec le systÃƒÂ¨me de documentation
.DESCRIPTION
    Ce script gÃƒÂ©nÃƒÂ¨re et met ÃƒÂ  jour la documentation ÃƒÂ  partir des mÃƒÂ©tadonnÃƒÂ©es
    des scripts dans l'inventaire.
.PARAMETER Path
    Chemin du rÃƒÂ©pertoire ÃƒÂ  analyser
.PARAMETER DocsPath
    Chemin du rÃƒÂ©pertoire de documentation
.PARAMETER UpdateExisting
    Indique s'il faut mettre ÃƒÂ  jour la documentation existante
.EXAMPLE
    .\Sync-ScriptDocumentation.ps1 -Path "C:\Scripts" -DocsPath "C:\Scripts\docs"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: documentation, scripts, intÃƒÂ©gration
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

# Importer les modules nÃƒÂ©cessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Fonction pour gÃƒÂ©nÃƒÂ©rer la documentation d'un script
function New-ScriptDocumentation {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $Script.FullPath -Raw -ErrorAction SilentlyContinue
    
    # Extraire les fonctions et les paramÃƒÂ¨tres
    $functions = @()
    $parameters = @()
    
    if ($Script.Language -like "PowerShell*") {
        # Extraire les fonctions PowerShell
        $functionMatches = [regex]::Matches($content, '(?:function|filter)\s+([A-Za-z0-9\-_]+)')
        foreach ($match in $functionMatches) {
            $functions += $match.Groups[1].Value
        }
        
        # Extraire les paramÃƒÂ¨tres PowerShell
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
    
    # GÃƒÂ©nÃƒÂ©rer le contenu de la documentation
    $doc = @"
# $($Script.FileName)

## Informations gÃƒÂ©nÃƒÂ©rales

- **Nom du fichier**: $($Script.FileName)
- **Chemin**: $($Script.FullPath)
- **Langage**: $($Script.Language)
- **Auteur**: $($Script.Author)
- **Version**: $($Script.Version)
- **CatÃƒÂ©gorie**: $($Script.Category)
- **Sous-catÃƒÂ©gorie**: $($Script.SubCategory)
- **DerniÃƒÂ¨re modification**: $($Script.LastModified)
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
    
    # Ajouter les paramÃƒÂ¨tres si disponibles
    if ($parameters.Count -gt 0) {
        $doc += @"

## ParamÃƒÂ¨tres

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
- [Retour ÃƒÂ  l'index](../index.md)

---

*Documentation gÃƒÂ©nÃƒÂ©rÃƒÂ©e automatiquement le $(Get-Date -Format "yyyy-MM-dd") ÃƒÂ  $(Get-Date -Format "HH:mm:ss")*

"@

    # Ãƒâ€°crire le fichier de documentation
    Set-Content -Path $OutputPath -Value $doc -Encoding UTF8
    
    return $OutputPath
}

# Fonction pour gÃƒÂ©nÃƒÂ©rer l'index de la documentation
function New-DocumentationIndex {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Scripts,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Grouper les scripts par catÃƒÂ©gorie
    $scriptsByCategory = $Scripts | Group-Object -Property Category
    
    # GÃƒÂ©nÃƒÂ©rer le contenu de l'index
    $index = @"
# Index de la Documentation des Scripts

## Vue d'ensemble

Cette documentation a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©e automatiquement ÃƒÂ  partir de l'inventaire des scripts.
Elle contient des informations sur tous les scripts du projet, organisÃƒÂ©s par catÃƒÂ©gorie.

- **Nombre total de scripts**: $($Scripts.Count)
- **Nombre de catÃƒÂ©gories**: $($scriptsByCategory.Count)
- **Date de gÃƒÂ©nÃƒÂ©ration**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Scripts par catÃƒÂ©gorie

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

- **Scripts rÃƒÂ©cemment modifiÃƒÂ©s**:
$(foreach ($script in ($Scripts | Sort-Object -Property LastModified -Descending | Select-Object -First 5)) {
    "  - $($script.FileName) ($(Get-Date $script.LastModified -Format 'yyyy-MM-dd'))"
})

---

*Documentation gÃƒÂ©nÃƒÂ©rÃƒÂ©e automatiquement le $(Get-Date -Format "yyyy-MM-dd") ÃƒÂ  $(Get-Date -Format "HH:mm:ss")*

"@

    # Ãƒâ€°crire le fichier d'index
    Set-Content -Path $OutputPath -Value $index -Encoding UTF8
    
    return $OutputPath
}

# RÃƒÂ©cupÃƒÂ©rer les scripts
Write-Host "RÃƒÂ©cupÃƒÂ©ration des scripts..." -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $Path

# VÃƒÂ©rifier qu'il y a des scripts
if (-not $scripts -or $scripts.Count -eq 0) {
    Write-Host "Aucun script trouvÃƒÂ© dans le rÃƒÂ©pertoire spÃƒÂ©cifiÃƒÂ©." -ForegroundColor Red
    exit
}

# CrÃƒÂ©er le rÃƒÂ©pertoire de documentation s'il n'existe pas
if (-not (Test-Path $DocsPath)) {
    New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
    Write-Host "RÃƒÂ©pertoire de documentation crÃƒÂ©ÃƒÂ©: $DocsPath" -ForegroundColor Green
}

# CrÃƒÂ©er le rÃƒÂ©pertoire pour les scripts
$scriptsDocsPath = Join-Path -Path $DocsPath -ChildPath "scripts"
if (-not (Test-Path $scriptsDocsPath)) {
    New-Item -ItemType Directory -Path $scriptsDocsPath -Force | Out-Null
}

# GÃƒÂ©nÃƒÂ©rer la documentation pour chaque script
$docsGenerated = 0
$docsUpdated = 0
$docsSkipped = 0

foreach ($script in $scripts) {
    # CrÃƒÂ©er le rÃƒÂ©pertoire pour la catÃƒÂ©gorie
    $categoryPath = Join-Path -Path $scriptsDocsPath -ChildPath $script.Category
    if (-not (Test-Path $categoryPath)) {
        New-Item -ItemType Directory -Path $categoryPath -Force | Out-Null
    }
    
    # Chemin du fichier de documentation
    $docFileName = $script.FileName.Replace('.', '_') + ".md"
    $docPath = Join-Path -Path $categoryPath -ChildPath $docFileName
    
    # VÃƒÂ©rifier si le fichier existe dÃƒÂ©jÃƒÂ 
    $fileExists = Test-Path $docPath
    
    if (-not $fileExists -or $UpdateExisting) {
        # GÃƒÂ©nÃƒÂ©rer la documentation
        New-ScriptDocumentation -Script $script -OutputPath $docPath | Out-Null
        
        if ($fileExists) {
            $docsUpdated++
            Write-Host "Documentation mise ÃƒÂ  jour: $docPath" -ForegroundColor Yellow
        } else {
            $docsGenerated++
            Write-Host "Documentation gÃƒÂ©nÃƒÂ©rÃƒÂ©e: $docPath" -ForegroundColor Green
        }
    } else {
        $docsSkipped++
        Write-Host "Documentation existante ignorÃƒÂ©e: $docPath" -ForegroundColor Gray
    }
}

# GÃƒÂ©nÃƒÂ©rer l'index
$indexPath = Join-Path -Path $DocsPath -ChildPath "index.md"
New-DocumentationIndex -Scripts $scripts -OutputPath $indexPath | Out-Null
Write-Host "Index gÃƒÂ©nÃƒÂ©rÃƒÂ©: $indexPath" -ForegroundColor Green

# Afficher un rÃƒÂ©sumÃƒÂ©
Write-Host "`nRÃƒÂ©sumÃƒÂ©:" -ForegroundColor Cyan
Write-Host "- Documentation gÃƒÂ©nÃƒÂ©rÃƒÂ©e pour $docsGenerated scripts" -ForegroundColor Green
Write-Host "- Documentation mise ÃƒÂ  jour pour $docsUpdated scripts" -ForegroundColor Yellow
Write-Host "- Documentation existante ignorÃƒÂ©e pour $docsSkipped scripts" -ForegroundColor Gray
Write-Host "- Index gÃƒÂ©nÃƒÂ©rÃƒÂ© avec $($scripts.Count) scripts" -ForegroundColor Green

# Demander ÃƒÂ  l'utilisateur s'il veut ouvrir l'index
$openIndex = Read-Host "Voulez-vous ouvrir l'index de la documentation? (O/N)"
if ($openIndex -eq "O" -or $openIndex -eq "o") {
    Start-Process $indexPath
}
