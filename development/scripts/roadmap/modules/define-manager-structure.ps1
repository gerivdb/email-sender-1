<#
.SYNOPSIS
    DÃ©finit une structure de rÃ©pertoires standard pour les gestionnaires.

.DESCRIPTION
    Ce script dÃ©finit une structure de rÃ©pertoires standard pour les gestionnaires
    et crÃ©e les rÃ©pertoires nÃ©cessaires.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire parent du rÃ©pertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exÃ©cution du script sans demander de confirmation.

.EXAMPLE
    .\define-manager-structure.ps1
    DÃ©finit une structure de rÃ©pertoires standard pour les gestionnaires.

.EXAMPLE
    .\define-manager-structure.ps1 -WhatIf
    Affiche ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# DÃ©finir les chemins des rÃ©pertoires
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers"

# DÃ©finir la structure des gestionnaires
$managerStructure = @{
    "integrated-manager" = @{
        "Path" = Join-Path -Path $managersRoot -ChildPath "integrated-manager"
        "Subdirectories" = @(
            "config",
            "scripts",
            "modules",
            "tests"
        )
    }
    "mode-manager" = @{
        "Path" = Join-Path -Path $managersRoot -ChildPath "mode-manager"
        "Subdirectories" = @(
            "config",
            "scripts",
            "modules",
            "tests"
        )
    }
    "roadmap-manager" = @{
        "Path" = Join-Path -Path $managersRoot -ChildPath "roadmap-manager"
        "Subdirectories" = @(
            "config",
            "scripts",
            "modules",
            "tests"
        )
    }
    "mcp-manager" = @{
        "Path" = Join-Path -Path $managersRoot -ChildPath "mcp-manager"
        "Subdirectories" = @(
            "config",
            "scripts",
            "modules",
            "tests"
        )
    }
    "script-manager" = @{
        "Path" = Join-Path -Path $managersRoot -ChildPath "script-manager"
        "Subdirectories" = @(
            "config",
            "scripts",
            "modules",
            "tests"
        )
    }
    "error-manager" = @{
        "Path" = Join-Path -Path $managersRoot -ChildPath "error-manager"
        "Subdirectories" = @(
            "config",
            "scripts",
            "modules",
            "tests"
        )
    }
    "n8n-manager" = @{
        "Path" = Join-Path -Path $managersRoot -ChildPath "n8n-manager"
        "Subdirectories" = @(
            "config",
            "scripts",
            "modules",
            "tests"
        )
    }
}

# CrÃ©er le rÃ©pertoire racine des gestionnaires
if (-not (Test-Path -Path $managersRoot -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($managersRoot, "CrÃ©er le rÃ©pertoire racine des gestionnaires")) {
        New-Item -Path $managersRoot -ItemType Directory -Force | Out-Null
        Write-Host "RÃ©pertoire crÃ©Ã© : $managersRoot" -ForegroundColor Green
    }
}

# CrÃ©er le rÃ©pertoire de configuration des gestionnaires
if (-not (Test-Path -Path $configRoot -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($configRoot, "CrÃ©er le rÃ©pertoire de configuration des gestionnaires")) {
        New-Item -Path $configRoot -ItemType Directory -Force | Out-Null
        Write-Host "RÃ©pertoire crÃ©Ã© : $configRoot" -ForegroundColor Green
    }
}

# CrÃ©er les rÃ©pertoires pour chaque gestionnaire
foreach ($manager in $managerStructure.Keys) {
    $managerPath = $managerStructure[$manager].Path
    
    # CrÃ©er le rÃ©pertoire du gestionnaire
    if (-not (Test-Path -Path $managerPath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($managerPath, "CrÃ©er le rÃ©pertoire du gestionnaire $manager")) {
            New-Item -Path $managerPath -ItemType Directory -Force | Out-Null
            Write-Host "RÃ©pertoire crÃ©Ã© : $managerPath" -ForegroundColor Green
        }
    }
    
    # CrÃ©er les sous-rÃ©pertoires du gestionnaire
    foreach ($subdir in $managerStructure[$manager].Subdirectories) {
        $subdirPath = Join-Path -Path $managerPath -ChildPath $subdir
        
        if (-not (Test-Path -Path $subdirPath -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($subdirPath, "CrÃ©er le sous-rÃ©pertoire $subdir pour le gestionnaire $manager")) {
                New-Item -Path $subdirPath -ItemType Directory -Force | Out-Null
                Write-Host "RÃ©pertoire crÃ©Ã© : $subdirPath" -ForegroundColor Green
            }
        }
    }
    
    # CrÃ©er le rÃ©pertoire de configuration du gestionnaire
    $managerConfigPath = Join-Path -Path $configRoot -ChildPath $manager
    
    if (-not (Test-Path -Path $managerConfigPath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($managerConfigPath, "CrÃ©er le rÃ©pertoire de configuration du gestionnaire $manager")) {
            New-Item -Path $managerConfigPath -ItemType Directory -Force | Out-Null
            Write-Host "RÃ©pertoire crÃ©Ã© : $managerConfigPath" -ForegroundColor Green
        }
    }
}

# CrÃ©er un fichier README.md dans le rÃ©pertoire racine des gestionnaires
$readmePath = Join-Path -Path $managersRoot -ChildPath "README.md"

if (-not (Test-Path -Path $readmePath -PathType Leaf)) {
    if ($PSCmdlet.ShouldProcess($readmePath, "CrÃ©er le fichier README.md")) {
        $readmeContent = @"
# Gestionnaires

Ce rÃ©pertoire contient tous les gestionnaires du projet.

## Structure

Chaque gestionnaire est organisÃ© selon la structure suivante :

- `<gestionnaire>/config` : Fichiers de configuration spÃ©cifiques au gestionnaire
- `<gestionnaire>/scripts` : Scripts PowerShell du gestionnaire
- `<gestionnaire>/modules` : Modules PowerShell du gestionnaire
- `<gestionnaire>/tests` : Tests unitaires et d'intÃ©gration du gestionnaire

## Gestionnaires disponibles

- `integrated-manager` : Gestionnaire intÃ©grÃ© qui coordonne tous les autres gestionnaires
- `mode-manager` : Gestionnaire des modes opÃ©rationnels
- `roadmap-manager` : Gestionnaire de la roadmap
- `mcp-manager` : Gestionnaire MCP
- `script-manager` : Gestionnaire de scripts
- `error-manager` : Gestionnaire d'erreurs
- `n8n-manager` : Gestionnaire n8n

## Configuration

Les fichiers de configuration des gestionnaires sont centralisÃ©s dans le rÃ©pertoire `projet/config/managers`.
"@
        
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Host "Fichier crÃ©Ã© : $readmePath" -ForegroundColor Green
    }
}

# CrÃ©er un fichier README.md dans le rÃ©pertoire de configuration des gestionnaires
$configReadmePath = Join-Path -Path $configRoot -ChildPath "README.md"

if (-not (Test-Path -Path $configReadmePath -PathType Leaf)) {
    if ($PSCmdlet.ShouldProcess($configReadmePath, "CrÃ©er le fichier README.md")) {
        $configReadmeContent = @"
# Configuration des gestionnaires

Ce rÃ©pertoire contient les fichiers de configuration de tous les gestionnaires du projet.

## Structure

Chaque gestionnaire a son propre rÃ©pertoire de configuration :

- `integrated-manager` : Configuration du gestionnaire intÃ©grÃ©
- `mode-manager` : Configuration du gestionnaire des modes opÃ©rationnels
- `roadmap-manager` : Configuration du gestionnaire de la roadmap
- `mcp-manager` : Configuration du gestionnaire MCP
- `script-manager` : Configuration du gestionnaire de scripts
- `error-manager` : Configuration du gestionnaire d'erreurs
- `n8n-manager` : Configuration du gestionnaire n8n

## Format

Les fichiers de configuration sont au format JSON et suivent la convention de nommage `<gestionnaire>.config.json`.
"@
        
        Set-Content -Path $configReadmePath -Value $configReadmeContent -Encoding UTF8
        Write-Host "Fichier crÃ©Ã© : $configReadmePath" -ForegroundColor Green
    }
}

# Afficher un rÃ©sumÃ©
Write-Host ""
Write-Host "RÃ©sumÃ© de la structure des gestionnaires" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "RÃ©pertoire racine des gestionnaires : $managersRoot" -ForegroundColor Gray
Write-Host "RÃ©pertoire de configuration des gestionnaires : $configRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "Gestionnaires dÃ©finis :" -ForegroundColor Gray
foreach ($manager in $managerStructure.Keys) {
    Write-Host "  - $manager" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Structure dÃ©finie avec succÃ¨s." -ForegroundColor Green

# Retourner un rÃ©sultat
return @{
    ManagersRoot = $managersRoot
    ConfigRoot = $configRoot
    ManagerStructure = $managerStructure
    Success = $true
}
