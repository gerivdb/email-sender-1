#Requires -Version 5.1
<#
.SYNOPSIS
    Valide la structure du dÃ©pÃ´t selon le standard dÃ©fini
.DESCRIPTION
    Ce script vÃ©rifie que la structure du dÃ©pÃ´t est conforme au standard dÃ©fini
    dans le document RepoStructureStandard.md. Il gÃ©nÃ¨re un rapport de conformitÃ©
    et peut suggÃ©rer des corrections.
.PARAMETER Path
    Chemin du dÃ©pÃ´t Ã  valider
.PARAMETER ReportPath
    Chemin oÃ¹ gÃ©nÃ©rer le rapport de conformitÃ©
.PARAMETER Fix
    Indique si le script doit tenter de corriger les problÃ¨mes dÃ©tectÃ©s
.EXAMPLE
    .\Test-RepoStructure.ps1 -Path "D:\Repos\EMAIL_SENDER_1"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "reports\structure-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').md",
    
    [Parameter(Mandatory = $false)]
    [switch]$Fix
)

# DÃ©finition des dossiers principaux attendus
$mainFolders = @(
    "scripts",
    "modules",
    "docs",
    "tests",
    "config",
    "assets",
    "tools",
    "logs",
    "reports",
    ".github",
    ".vscode",
    "Roadmap"
)

# DÃ©finition des sous-dossiers attendus
$subFolders = @{
    "scripts" = @(
        "scripts\analysis",
        "scripts\automation",
        "scripts\gui",
        "scripts\integration",
        "scripts\maintenance",
        "scripts\setup",
        "scripts\utils"
    )
    "modules" = @(
        "modules\PowerShell",
        "modules\Python",
        "modules\Common"
    )
    "docs" = @(
        "docs\guides",
        "docs\api",
        "docs\development",
        "docs\architecture"
    )
    "tests" = @(
        "tests\unit",
        "tests\integration",
        "tests\performance",
        "tests\fixtures"
    )
}

# Fonction pour vÃ©rifier l'existence d'un dossier
function Test-FolderExists {
    param (
        [string]$FolderPath
    )
    
    $fullPath = Join-Path -Path $Path -ChildPath $FolderPath
    return Test-Path -Path $fullPath -PathType Container
}

# Fonction pour crÃ©er un dossier s'il n'existe pas
function New-FolderIfNotExists {
    param (
        [string]$FolderPath
    )
    
    $fullPath = Join-Path -Path $Path -ChildPath $FolderPath
    if (-not (Test-Path -Path $fullPath -PathType Container)) {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        return $true
    }
    return $false
}

# Fonction pour vÃ©rifier les conventions de nommage des fichiers
function Test-FileNamingConventions {
    param (
        [string]$FolderPath,
        [string]$Pattern,
        [string]$Convention
    )
    
    $fullPath = Join-Path -Path $Path -ChildPath $FolderPath
    if (Test-Path -Path $fullPath -PathType Container) {
        $files = Get-ChildItem -Path $fullPath -File -Filter $Pattern -Recurse
        $nonCompliantFiles = @()
        
        foreach ($file in $files) {
            $isCompliant = $false
            
            switch ($Convention) {
                "PascalCase" {
                    # VÃ©rifier le format PascalCase (Verbe-Nom.ps1)
                    $isCompliant = $file.Name -match '^[A-Z][a-z0-9]+(-[A-Z][a-z0-9]+)*\.(ps1|psm1)$'
                }
                "snake_case" {
                    # VÃ©rifier le format snake_case
                    $isCompliant = $file.Name -match '^[a-z0-9_]+\.(py|sh)$'
                }
                "kebab-case" {
                    # VÃ©rifier le format kebab-case
                    $isCompliant = $file.Name -match '^[a-z0-9]+(-[a-z0-9]+)*\.(cmd|bat|json|yaml|yml)$'
                }
            }
            
            if (-not $isCompliant) {
                $nonCompliantFiles += $file
            }
        }
        
        return $nonCompliantFiles
    }
    
    return @()
}

# Initialiser les rÃ©sultats
$results = @{
    MissingMainFolders = @()
    MissingSubFolders = @()
    NonCompliantPowerShellFiles = @()
    NonCompliantPythonFiles = @()
    NonCompliantBatchFiles = @()
    CreatedFolders = @()
}

# VÃ©rifier les dossiers principaux
foreach ($folder in $mainFolders) {
    if (-not (Test-FolderExists -FolderPath $folder)) {
        $results.MissingMainFolders += $folder
        
        if ($Fix) {
            $created = New-FolderIfNotExists -FolderPath $folder
            if ($created) {
                $results.CreatedFolders += $folder
            }
        }
    }
}

# VÃ©rifier les sous-dossiers
foreach ($mainFolder in $subFolders.Keys) {
    foreach ($subFolder in $subFolders[$mainFolder]) {
        if (-not (Test-FolderExists -FolderPath $subFolder)) {
            $results.MissingSubFolders += $subFolder
            
            if ($Fix) {
                $created = New-FolderIfNotExists -FolderPath $subFolder
                if ($created) {
                    $results.CreatedFolders += $subFolder
                }
            }
        }
    }
}

# VÃ©rifier les conventions de nommage
$results.NonCompliantPowerShellFiles = Test-FileNamingConventions -FolderPath "scripts" -Pattern "*.ps1" -Convention "PascalCase"
$results.NonCompliantPythonFiles = Test-FileNamingConventions -FolderPath "scripts" -Pattern "*.py" -Convention "snake_case"
$results.NonCompliantBatchFiles = Test-FileNamingConventions -FolderPath "scripts" -Pattern "*.cmd" -Convention "kebab-case"

# GÃ©nÃ©rer le rapport
$reportContent = @"
# Rapport de Validation de Structure du DÃ©pÃ´t

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Chemin: $Path

## RÃ©sumÃ©

- Dossiers principaux manquants: $($results.MissingMainFolders.Count)
- Sous-dossiers manquants: $($results.MissingSubFolders.Count)
- Fichiers PowerShell non conformes: $($results.NonCompliantPowerShellFiles.Count)
- Fichiers Python non conformes: $($results.NonCompliantPythonFiles.Count)
- Fichiers Batch non conformes: $($results.NonCompliantBatchFiles.Count)
- Dossiers crÃ©Ã©s (si Fix=True): $($results.CreatedFolders.Count)

## DÃ©tails

### Dossiers principaux manquants

$(if ($results.MissingMainFolders.Count -eq 0) {
    "Aucun dossier principal manquant."
} else {
    $results.MissingMainFolders | ForEach-Object { "- $_" } | Out-String
})

### Sous-dossiers manquants

$(if ($results.MissingSubFolders.Count -eq 0) {
    "Aucun sous-dossier manquant."
} else {
    $results.MissingSubFolders | ForEach-Object { "- $_" } | Out-String
})

### Fichiers PowerShell non conformes

$(if ($results.NonCompliantPowerShellFiles.Count -eq 0) {
    "Aucun fichier PowerShell non conforme."
} else {
    $results.NonCompliantPowerShellFiles | ForEach-Object { "- $($_.FullName)" } | Out-String
})

### Fichiers Python non conformes

$(if ($results.NonCompliantPythonFiles.Count -eq 0) {
    "Aucun fichier Python non conforme."
} else {
    $results.NonCompliantPythonFiles | ForEach-Object { "- $($_.FullName)" } | Out-String
})

### Fichiers Batch non conformes

$(if ($results.NonCompliantBatchFiles.Count -eq 0) {
    "Aucun fichier Batch non conforme."
} else {
    $results.NonCompliantBatchFiles | ForEach-Object { "- $($_.FullName)" } | Out-String
})

### Dossiers crÃ©Ã©s

$(if ($results.CreatedFolders.Count -eq 0) {
    "Aucun dossier crÃ©Ã©."
} else {
    $results.CreatedFolders | ForEach-Object { "- $_" } | Out-String
})

## Recommandations

$(if ($results.MissingMainFolders.Count -eq 0 -and $results.MissingSubFolders.Count -eq 0 -and 
      $results.NonCompliantPowerShellFiles.Count -eq 0 -and $results.NonCompliantPythonFiles.Count -eq 0 -and 
      $results.NonCompliantBatchFiles.Count -eq 0) {
    "La structure du dÃ©pÃ´t est conforme au standard dÃ©fini."
} else {
    if (-not $Fix) {
        "ExÃ©cutez le script avec le paramÃ¨tre -Fix pour corriger automatiquement les problÃ¨mes de structure."
    } else {
        "Certains problÃ¨mes ont Ã©tÃ© corrigÃ©s automatiquement. VÃ©rifiez le rapport pour plus de dÃ©tails."
    }
    
    if ($results.NonCompliantPowerShellFiles.Count -gt 0 -or $results.NonCompliantPythonFiles.Count -gt 0 -or 
        $results.NonCompliantBatchFiles.Count -gt 0) {
        "Utilisez le script Rename-NonCompliantFiles.ps1 pour renommer les fichiers non conformes."
    }
})
"@

# CrÃ©er le dossier de rapport s'il n'existe pas
$reportDir = Split-Path -Path $ReportPath -Parent
if (-not (Test-Path -Path $reportDir -PathType Container)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

# Enregistrer le rapport
$reportFullPath = Join-Path -Path $Path -ChildPath $ReportPath
Set-Content -Path $reportFullPath -Value $reportContent -Encoding UTF8

# Afficher un rÃ©sumÃ©
Write-Host "Validation de la structure du dÃ©pÃ´t terminÃ©e." -ForegroundColor Green
Write-Host "Dossiers principaux manquants: $($results.MissingMainFolders.Count)" -ForegroundColor $(if ($results.MissingMainFolders.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Sous-dossiers manquants: $($results.MissingSubFolders.Count)" -ForegroundColor $(if ($results.MissingSubFolders.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Fichiers PowerShell non conformes: $($results.NonCompliantPowerShellFiles.Count)" -ForegroundColor $(if ($results.NonCompliantPowerShellFiles.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Fichiers Python non conformes: $($results.NonCompliantPythonFiles.Count)" -ForegroundColor $(if ($results.NonCompliantPythonFiles.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Fichiers Batch non conformes: $($results.NonCompliantBatchFiles.Count)" -ForegroundColor $(if ($results.NonCompliantBatchFiles.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Dossiers crÃ©Ã©s: $($results.CreatedFolders.Count)" -ForegroundColor $(if ($results.CreatedFolders.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Rapport gÃ©nÃ©rÃ©: $reportFullPath" -ForegroundColor Cyan

# Retourner les rÃ©sultats
return $results

