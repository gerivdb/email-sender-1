<#
.SYNOPSIS
    Définit une structure de répertoires standard pour les gestionnaires.

.DESCRIPTION
    Ce script définit une structure de répertoires standard pour les gestionnaires
    et crée les répertoires nécessaires.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire parent du répertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exécutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exécution du script sans demander de confirmation.

.EXAMPLE
    .\define-manager-structure.ps1
    Définit une structure de répertoires standard pour les gestionnaires.

.EXAMPLE
    .\define-manager-structure.ps1 -WhatIf
    Affiche ce qui se passerait si le script s'exécutait sans effectuer de modifications.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2023-06-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# Définir les chemins des répertoires
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers"

# Définir la structure des gestionnaires
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

# Créer le répertoire racine des gestionnaires
if (-not (Test-Path -Path $managersRoot -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($managersRoot, "Créer le répertoire racine des gestionnaires")) {
        New-Item -Path $managersRoot -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire créé : $managersRoot" -ForegroundColor Green
    }
}

# Créer le répertoire de configuration des gestionnaires
if (-not (Test-Path -Path $configRoot -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($configRoot, "Créer le répertoire de configuration des gestionnaires")) {
        New-Item -Path $configRoot -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire créé : $configRoot" -ForegroundColor Green
    }
}

# Créer les répertoires pour chaque gestionnaire
foreach ($manager in $managerStructure.Keys) {
    $managerPath = $managerStructure[$manager].Path
    
    # Créer le répertoire du gestionnaire
    if (-not (Test-Path -Path $managerPath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($managerPath, "Créer le répertoire du gestionnaire $manager")) {
            New-Item -Path $managerPath -ItemType Directory -Force | Out-Null
            Write-Host "Répertoire créé : $managerPath" -ForegroundColor Green
        }
    }
    
    # Créer les sous-répertoires du gestionnaire
    foreach ($subdir in $managerStructure[$manager].Subdirectories) {
        $subdirPath = Join-Path -Path $managerPath -ChildPath $subdir
        
        if (-not (Test-Path -Path $subdirPath -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($subdirPath, "Créer le sous-répertoire $subdir pour le gestionnaire $manager")) {
                New-Item -Path $subdirPath -ItemType Directory -Force | Out-Null
                Write-Host "Répertoire créé : $subdirPath" -ForegroundColor Green
            }
        }
    }
    
    # Créer le répertoire de configuration du gestionnaire
    $managerConfigPath = Join-Path -Path $configRoot -ChildPath $manager
    
    if (-not (Test-Path -Path $managerConfigPath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($managerConfigPath, "Créer le répertoire de configuration du gestionnaire $manager")) {
            New-Item -Path $managerConfigPath -ItemType Directory -Force | Out-Null
            Write-Host "Répertoire créé : $managerConfigPath" -ForegroundColor Green
        }
    }
}

# Créer un fichier README.md dans le répertoire racine des gestionnaires
$readmePath = Join-Path -Path $managersRoot -ChildPath "README.md"

if (-not (Test-Path -Path $readmePath -PathType Leaf)) {
    if ($PSCmdlet.ShouldProcess($readmePath, "Créer le fichier README.md")) {
        $readmeContent = @"
# Gestionnaires

Ce répertoire contient tous les gestionnaires du projet.

## Structure

Chaque gestionnaire est organisé selon la structure suivante :

- `<gestionnaire>/config` : Fichiers de configuration spécifiques au gestionnaire
- `<gestionnaire>/scripts` : Scripts PowerShell du gestionnaire
- `<gestionnaire>/modules` : Modules PowerShell du gestionnaire
- `<gestionnaire>/tests` : Tests unitaires et d'intégration du gestionnaire

## Gestionnaires disponibles

- `integrated-manager` : Gestionnaire intégré qui coordonne tous les autres gestionnaires
- `mode-manager` : Gestionnaire des modes opérationnels
- `roadmap-manager` : Gestionnaire de la roadmap
- `mcp-manager` : Gestionnaire MCP
- `script-manager` : Gestionnaire de scripts
- `error-manager` : Gestionnaire d'erreurs
- `n8n-manager` : Gestionnaire n8n

## Configuration

Les fichiers de configuration des gestionnaires sont centralisés dans le répertoire `projet/config/managers`.
"@
        
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Host "Fichier créé : $readmePath" -ForegroundColor Green
    }
}

# Créer un fichier README.md dans le répertoire de configuration des gestionnaires
$configReadmePath = Join-Path -Path $configRoot -ChildPath "README.md"

if (-not (Test-Path -Path $configReadmePath -PathType Leaf)) {
    if ($PSCmdlet.ShouldProcess($configReadmePath, "Créer le fichier README.md")) {
        $configReadmeContent = @"
# Configuration des gestionnaires

Ce répertoire contient les fichiers de configuration de tous les gestionnaires du projet.

## Structure

Chaque gestionnaire a son propre répertoire de configuration :

- `integrated-manager` : Configuration du gestionnaire intégré
- `mode-manager` : Configuration du gestionnaire des modes opérationnels
- `roadmap-manager` : Configuration du gestionnaire de la roadmap
- `mcp-manager` : Configuration du gestionnaire MCP
- `script-manager` : Configuration du gestionnaire de scripts
- `error-manager` : Configuration du gestionnaire d'erreurs
- `n8n-manager` : Configuration du gestionnaire n8n

## Format

Les fichiers de configuration sont au format JSON et suivent la convention de nommage `<gestionnaire>.config.json`.
"@
        
        Set-Content -Path $configReadmePath -Value $configReadmeContent -Encoding UTF8
        Write-Host "Fichier créé : $configReadmePath" -ForegroundColor Green
    }
}

# Afficher un résumé
Write-Host ""
Write-Host "Résumé de la structure des gestionnaires" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Répertoire racine des gestionnaires : $managersRoot" -ForegroundColor Gray
Write-Host "Répertoire de configuration des gestionnaires : $configRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "Gestionnaires définis :" -ForegroundColor Gray
foreach ($manager in $managerStructure.Keys) {
    Write-Host "  - $manager" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Structure définie avec succès." -ForegroundColor Green

# Retourner un résultat
return @{
    ManagersRoot = $managersRoot
    ConfigRoot = $configRoot
    ManagerStructure = $managerStructure
    Success = $true
}
