# Script de gestion de la roadmap
# Ce script permet d'accéder à toutes les fonctionnalités de gestion de la roadmap

param (
    [string]$RoadmapPath = "roadmap_perso.md",
    [switch]$Organize = $false,
    [switch]$Execute = $false,
    [switch]$Analyze = $false,
    [switch]$GitUpdate = $false,
    [switch]$Cleanup = $false,
    [switch]$FixScripts = $false,
    [switch]$Help = $false
)

# Configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$roadmapFolder = $scriptPath
$null = Split-Path -Parent $scriptPath # Utilisé pour la compatibilité avec d'autres scripts

# Définition des chemins des scripts
$scriptPaths = @{
    "RoadmapAdmin" = Join-Path -Path $roadmapFolder -ChildPath "RoadmapAdmin.ps1"
    "AugmentExecutor" = Join-Path -Path $roadmapFolder -ChildPath "AugmentExecutor.ps1"
    "RestartAugment" = Join-Path -Path $roadmapFolder -ChildPath "RestartAugment.ps1"
    "StartRoadmapExecution" = Join-Path -Path $roadmapFolder -ChildPath "StartRoadmapExecution.ps1"
    "RoadmapAnalyzer" = Join-Path -Path $roadmapFolder -ChildPath "RoadmapAnalyzer.ps1"
    "RoadmapGitUpdater" = Join-Path -Path $roadmapFolder -ChildPath "RoadmapGitUpdater.ps1"
    "CleanupRoadmapFiles" = Join-Path -Path $roadmapFolder -ChildPath "CleanupRoadmapFiles.ps1"
    "OrganizeRoadmapScripts" = Join-Path -Path $roadmapFolder -ChildPath "OrganizeRoadmapScripts.ps1"
    "FixRoadmapScripts" = Join-Path -Path $roadmapFolder -ChildPath "Fix-RoadmapScripts.ps1"
}

# Vérifier si le chemin de la roadmap est relatif ou absolu
if (-not [System.IO.Path]::IsPathRooted($RoadmapPath)) {
    $RoadmapPath = Join-Path -Path $roadmapFolder -ChildPath $RoadmapPath
}

# Fonction pour afficher l'aide
function Show-Help {
    Write-Host "RoadmapManager.ps1 - Script de gestion de la roadmap" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Paramètres :" -ForegroundColor Yellow
    Write-Host "  -RoadmapPath <chemin>  : Chemin vers le fichier roadmap (par défaut: roadmap_perso.md)"
    Write-Host "  -Organize              : Organiser les scripts de roadmap dans un dossier dédié"
    Write-Host "  -Execute               : Exécuter la roadmap automatiquement"
    Write-Host "  -Analyze               : Analyser la roadmap et générer des rapports"
    Write-Host "  -GitUpdate             : Mettre à jour la roadmap en fonction des commits Git"
    Write-Host "  -Cleanup               : Nettoyer et organiser les fichiers de roadmap"
    Write-Host "  -FixScripts            : Corriger les problèmes dans les scripts de la roadmap"
    Write-Host "  -Help                  : Afficher cette aide"
    Write-Host ""
    Write-Host "Exemples :" -ForegroundColor Yellow
    Write-Host "  .\RoadmapManager.ps1 -Organize"
    Write-Host "  .\RoadmapManager.ps1 -Execute"
    Write-Host "  .\RoadmapManager.ps1 -Analyze"
    Write-Host "  .\RoadmapManager.ps1 -GitUpdate"
    Write-Host "  .\RoadmapManager.ps1 -Cleanup"
    Write-Host "  .\RoadmapManager.ps1 -FixScripts"
    Write-Host ""
    Write-Host "Interface interactive :" -ForegroundColor Yellow
    Write-Host "  .\RoadmapManager.ps1"
    Write-Host ""
}

# Fonction pour afficher le menu
function Show-Menu {
    Clear-Host
    Write-Host "=== Gestionnaire de Roadmap ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Roadmap : $RoadmapPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Organiser les scripts de roadmap"
    Write-Host "2. Exécuter la roadmap automatiquement"
    Write-Host "3. Analyser la roadmap et générer des rapports"
    Write-Host "4. Mettre à jour la roadmap en fonction des commits Git"
    Write-Host "5. Visualiser les processus de la roadmap"
    Write-Host "6. Nettoyer et organiser les fichiers de roadmap"
    Write-Host "7. Corriger les problèmes dans les scripts de la roadmap"
    Write-Host "8. Changer le fichier roadmap"
    Write-Host ""
    Write-Host "0. Quitter"
    Write-Host ""

    $choice = Read-Host "Votre choix"

    switch ($choice) {
        "1" { Invoke-OrganizeScripts }
        "2" { Invoke-ExecuteRoadmap }
        "3" { Invoke-AnalyzeRoadmap }
        "4" { Invoke-GitUpdateRoadmap }
        "5" { Invoke-VisualizeProcesses }
        "6" { Invoke-CleanupRoadmap }
        "7" { Invoke-FixScripts }
        "8" {
            $newPath = Read-Host "Nouveau chemin vers le fichier roadmap"
            if (Test-Path -Path $newPath) {
                $script:RoadmapPath = $newPath
                Write-Host "Fichier roadmap changé : $RoadmapPath" -ForegroundColor Green
            }
            else {
                Write-Host "Le fichier n'existe pas : $newPath" -ForegroundColor Red
            }
            Pause
            Show-Menu
        }
        "0" { return }
        default {
            Write-Host "Choix invalide" -ForegroundColor Red
            Pause
            Show-Menu
        }
    }
}

# Fonction générique pour exécuter un script
function Invoke-RoadmapScript {
    param (
        [string]$ScriptName,
        [string]$Description,
        [hashtable]$Parameters = @{}
    )

    Write-Host "$Description..." -ForegroundColor Cyan

    $scriptPath = $scriptPaths[$ScriptName]

    if (Test-Path -Path $scriptPath) {
        # Construire la commande avec les paramètres
        $command = "& '$scriptPath'"

        foreach ($key in $Parameters.Keys) {
            $value = $Parameters[$key]

            if ($value -is [switch] -and $value) {
                $command += " -$key"
            }
            elseif ($value -is [string]) {
                $command += " -$key '$value'"
            }
            elseif ($value -is [int] -or $value -is [double]) {
                $command += " -$key $value"
            }
        }

        # Exécuter la commande
        Invoke-Expression $command
    }
    else {
        Write-Host "Le script $ScriptName.ps1 n'existe pas: $scriptPath" -ForegroundColor Red
    }

    Pause
    Show-Menu
}

# Fonction pour organiser les scripts
function Invoke-OrganizeScripts {
    Invoke-RoadmapScript -ScriptName "OrganizeRoadmapScripts" -Description "Organisation des scripts de roadmap"
}

# Fonction pour exécuter la roadmap
function Invoke-ExecuteRoadmap {
    Invoke-RoadmapScript -ScriptName "StartRoadmapExecution" -Description "Exécution de la roadmap" -Parameters @{
        RoadmapPath = $RoadmapPath
        AutoExecute = $true
        AutoUpdate = $true
    }
}

# Fonction pour analyser la roadmap
function Invoke-AnalyzeRoadmap {
    Invoke-RoadmapScript -ScriptName "RoadmapAnalyzer" -Description "Analyse de la roadmap" -Parameters @{
        RoadmapPath = $RoadmapPath
        GenerateHtml = $true
        GenerateJson = $true
        GenerateChart = $true
    }
}

# Fonction pour mettre à jour la roadmap en fonction des commits Git
function Invoke-GitUpdateRoadmap {
    Invoke-RoadmapScript -ScriptName "RoadmapGitUpdater" -Description "Mise à jour de la roadmap en fonction des commits Git" -Parameters @{
        RoadmapPath = $RoadmapPath
        AutoUpdate = $true
        GenerateReport = $true
    }
}

# Fonction pour nettoyer et organiser les fichiers de roadmap
function Invoke-CleanupRoadmap {
    Invoke-RoadmapScript -ScriptName "CleanupRoadmapFiles" -Description "Nettoyage et organisation des fichiers de roadmap"
}

# Fonction pour corriger les problèmes dans les scripts de la roadmap
function Invoke-FixScripts {
    Invoke-RoadmapScript -ScriptName "FixRoadmapScripts" -Description "Correction des problèmes dans les scripts de la roadmap"
}

# Fonction pour visualiser les processus
function Invoke-VisualizeProcesses {
    Write-Host "Visualisation des processus de la roadmap..." -ForegroundColor Cyan

    $visualizationPath = Join-Path -Path $roadmapFolder -ChildPath "RoadmapProcesses.html"

    if (Test-Path -Path $visualizationPath) {
        Start-Process $visualizationPath
    }
    else {
        Write-Host "Le fichier de visualisation n'existe pas : $visualizationPath" -ForegroundColor Red
        Write-Host "Exécutez d'abord l'option 'Organiser les scripts de roadmap'." -ForegroundColor Yellow
    }

    Pause
    Show-Menu
}

# Fonction pause
function Pause {
    Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Vérifier si les scripts nécessaires existent
function Test-RequiredScripts {
    $missingScripts = @()

    foreach ($key in $scriptPaths.Keys) {
        $scriptPath = $scriptPaths[$key]
        if (-not (Test-Path -Path $scriptPath)) {
            $missingScripts += "$key ($scriptPath)"
        }
    }

    if ($missingScripts.Count -gt 0) {
        Write-Host "Attention : Certains scripts nécessaires sont manquants :" -ForegroundColor Yellow
        foreach ($script in $missingScripts) {
            Write-Host "  - $script" -ForegroundColor Yellow
        }
        Write-Host "Certaines fonctionnalités pourraient ne pas fonctionner correctement." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    return $true
}

# Point d'entrée principal
if ($Help) {
    Show-Help
    exit 0
}

# Vérifier les scripts nécessaires
Test-RequiredScripts | Out-Null

if ($Organize) {
    Invoke-OrganizeScripts
    exit 0
}

if ($Execute) {
    Invoke-ExecuteRoadmap
    exit 0
}

if ($Analyze) {
    Invoke-AnalyzeRoadmap
    exit 0
}

if ($GitUpdate) {
    Invoke-GitUpdateRoadmap
    exit 0
}

if ($Cleanup) {
    Invoke-CleanupRoadmap
    exit 0
}

if ($FixScripts) {
    Invoke-FixScripts
    exit 0
}

# Afficher le menu interactif si aucun paramètre n'est spécifié
Show-Menu
