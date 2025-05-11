# Start-RestoreUI.ps1
# Script d'entrée pour lancer l'interface utilisateur de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer le module d'interface utilisateur
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiPath = Join-Path -Path $scriptPath -ChildPath "RestoreUI.ps1"

if (Test-Path -Path $uiPath) {
    . $uiPath
} else {
    Write-Error "Le fichier RestoreUI.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher l'en-tête
function Show-Header {
    Clear-Host
    
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "                INTERFACE DE RESTAURATION               " -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "Version: 1.0                                           " -ForegroundColor DarkGray
    Write-Host "Date: 2025-05-15                                       " -ForegroundColor DarkGray
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Fonction pour vérifier les dépendances
function Test-Dependencies {
    $dependencies = @(
        @{
            Path = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\search\ArchiveSearch.ps1"
            Name = "Module de recherche d'archives"
        },
        @{
            Path = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\search\MetadataSearch.ps1"
            Name = "Module de recherche par métadonnées"
        },
        @{
            Path = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\path\PathResolver.ps1"
            Name = "Module de résolution des chemins"
        },
        @{
            Path = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\extract\ExtractManager.ps1"
            Name = "Module d'extraction"
        },
        @{
            Path = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "archive\index\restore\RestoreManager.ps1"
            Name = "Module de restauration"
        }
    )
    
    $allDependenciesFound = $true
    
    foreach ($dependency in $dependencies) {
        if (-not (Test-Path -Path $dependency.Path)) {
            Write-Host "Dépendance manquante: $($dependency.Name) ($($dependency.Path))" -ForegroundColor Red
            $allDependenciesFound = $false
        }
    }
    
    return $allDependenciesFound
}

# Fonction pour initialiser l'environnement
function Initialize-Environment {
    # Vérifier si le répertoire d'archives par défaut existe
    $defaultArchivePath = "$env:USERPROFILE\Documents\Archives"
    
    if (-not (Test-Path -Path $defaultArchivePath -PathType Container)) {
        Write-Host "Le répertoire d'archives par défaut n'existe pas: $defaultArchivePath" -ForegroundColor Yellow
        Write-Host "Création du répertoire..." -ForegroundColor Yellow
        
        try {
            New-Item -Path $defaultArchivePath -ItemType Directory -Force | Out-Null
            Write-Host "Répertoire créé avec succès." -ForegroundColor Green
        } catch {
            Write-Host "Erreur lors de la création du répertoire: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    
    # Initialiser le cache
    try {
        Initialize-ArchiveCache | Out-Null
    } catch {
        Write-Host "Erreur lors de l'initialisation du cache: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "L'application continuera sans utiliser le cache." -ForegroundColor Yellow
    }
    
    return $true
}

# Fonction principale
function Start-RestoreUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives"
    )
    
    # Afficher l'en-tête
    Show-Header
    
    # Vérifier les dépendances
    Write-Host "Vérification des dépendances..." -ForegroundColor White
    $dependenciesOK = Test-Dependencies
    
    if (-not $dependenciesOK) {
        Write-Host "Certaines dépendances sont manquantes. L'application ne peut pas démarrer." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour quitter"
        return
    }
    
    Write-Host "Toutes les dépendances sont présentes." -ForegroundColor Green
    
    # Initialiser l'environnement
    Write-Host "Initialisation de l'environnement..." -ForegroundColor White
    $environmentOK = Initialize-Environment
    
    if (-not $environmentOK) {
        Write-Host "Erreur lors de l'initialisation de l'environnement. L'application ne peut pas démarrer." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour quitter"
        return
    }
    
    Write-Host "Environnement initialisé avec succès." -ForegroundColor Green
    Write-Host "Démarrage de l'interface utilisateur..." -ForegroundColor White
    
    Start-Sleep -Seconds 1
    
    # Lancer l'interface utilisateur
    Show-RestoreMainMenu -ArchivePath $ArchivePath
}

# Démarrer l'interface utilisateur
Start-RestoreUI
