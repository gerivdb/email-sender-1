# Script principal de gestion de la roadmap
# Ce script permet d'accéder à toutes les fonctionnalités de gestion de la roadmap

# Paramètres
param (
    [string]$RoadmapPath = "Roadmap\roadmap_perso.md",
    [switch]$Organize,
    [switch]$Execute,
    [switch]$Analyze,
    [switch]$GitUpdate,
    [switch]$Cleanup,
    [switch]$FixScripts,
    [switch]$Help,
    [switch]$Interactive
)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# Fonction pour afficher l'aide
function Show-Help {
    Write-Host "Gestionnaire de roadmap" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ce script permet d'accéder à toutes les fonctionnalités de gestion de la roadmap."
    Write-Host ""
    Write-Host "Paramètres :" -ForegroundColor Yellow
    Write-Host "  -RoadmapPath    : Chemin du fichier roadmap (défaut: Roadmap\roadmap_perso.md)"
    Write-Host "  -Organize       : Organiser les scripts de roadmap"
    Write-Host "  -Execute        : Exécuter la roadmap"
    Write-Host "  -Analyze        : Analyser la roadmap et générer des rapports"
    Write-Host "  -GitUpdate      : Mettre à jour la roadmap en fonction des commits Git"
    Write-Host "  -Cleanup        : Nettoyer et organiser les fichiers liés à la roadmap"
    Write-Host "  -FixScripts     : Corriger les scripts de roadmap"
    Write-Host "  -Help           : Afficher cette aide"
    Write-Host "  -Interactive    : Mode interactif (menu)"
    Write-Host ""
    Write-Host "Exemples :" -ForegroundColor Yellow
    Write-Host "  .\RoadmapManager.ps1 -Analyze"
    Write-Host "  .\RoadmapManager.ps1 -GitUpdate -RoadmapPath 'chemin\vers\roadmap.md'"
    Write-Host "  .\RoadmapManager.ps1 -Interactive"
    Write-Host ""
}

# Fonction pour afficher le menu interactif
function Show-Menu {
    Clear-Host
    Write-Host "Gestionnaire de roadmap" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Organiser les scripts de roadmap"
    Write-Host "2. Exécuter la roadmap"
    Write-Host "3. Analyser la roadmap et générer des rapports"
    Write-Host "4. Mettre à jour la roadmap en fonction des commits Git"
    Write-Host "5. Nettoyer et organiser les fichiers liés à la roadmap"
    Write-Host "6. Corriger les scripts de roadmap"
    Write-Host "7. Quitter"
    Write-Host ""
    Write-Host "Sélectionnez une option (1-7) : " -NoNewline
    
    $choice = Read-Host
    
    switch ($choice) {
        "1" { Invoke-OrganizeScripts }
        "2" { Invoke-ExecuteRoadmap }
        "3" { Invoke-AnalyzeRoadmap }
        "4" { Invoke-GitUpdateRoadmap }
        "5" { Invoke-CleanupFiles }
        "6" { Invoke-FixScripts }
        "7" { return $false }
        default {
            Write-Host "Option invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $true
        }
    }
    
    Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $true
}

# Fonction pour organiser les scripts de roadmap
function Invoke-OrganizeScripts {
    Write-Log -Message "Organisation des scripts de roadmap..." -Level "INFO"
    
    try {
        & "$PSScriptRoot\OrganizeRoadmapScripts.ps1"
        Write-Log -Message "Organisation des scripts terminée." -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Erreur lors de l'organisation des scripts: $_" -Level "ERROR"
    }
}

# Fonction pour exécuter la roadmap
function Invoke-ExecuteRoadmap {
    Write-Log -Message "Exécution de la roadmap..." -Level "INFO"
    
    try {
        & "$PSScriptRoot\StartRoadmapExecution.ps1" -RoadmapPath $RoadmapPath
        Write-Log -Message "Exécution de la roadmap terminée." -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Erreur lors de l'exécution de la roadmap: $_" -Level "ERROR"
    }
}

# Fonction pour analyser la roadmap
function Invoke-AnalyzeRoadmap {
    Write-Log -Message "Analyse de la roadmap..." -Level "INFO"
    
    try {
        & "$PSScriptRoot\RoadmapAnalyzer.ps1" -RoadmapPath $RoadmapPath -GenerateHtml -GenerateJson -GenerateChart
        Write-Log -Message "Analyse de la roadmap terminée." -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Erreur lors de l'analyse de la roadmap: $_" -Level "ERROR"
    }
}

# Fonction pour mettre à jour la roadmap en fonction des commits Git
function Invoke-GitUpdateRoadmap {
    Write-Log -Message "Mise à jour de la roadmap en fonction des commits Git..." -Level "INFO"
    
    try {
        & "$PSScriptRoot\RoadmapGitUpdater.ps1" -RoadmapPath $RoadmapPath -AutoUpdate -GenerateReport
        Write-Log -Message "Mise à jour de la roadmap terminée." -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Erreur lors de la mise à jour de la roadmap: $_" -Level "ERROR"
    }
}

# Fonction pour nettoyer et organiser les fichiers liés à la roadmap
function Invoke-CleanupFiles {
    Write-Log -Message "Nettoyage et organisation des fichiers liés à la roadmap..." -Level "INFO"
    
    try {
        & "$PSScriptRoot\CleanupRoadmapFiles.ps1"
        Write-Log -Message "Nettoyage et organisation des fichiers terminés." -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Erreur lors du nettoyage et de l'organisation des fichiers: $_" -Level "ERROR"
    }
}

# Fonction pour corriger les scripts de roadmap
function Invoke-FixScripts {
    Write-Log -Message "Correction des scripts de roadmap..." -Level "INFO"
    
    try {
        # Vérifier l'encodage des fichiers
        $files = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | Select-Object -ExpandProperty FullName
        
        foreach ($file in $files) {
            $content = Get-Content -Path $file -Raw
            $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file, $content, $utf8NoBomEncoding)
            Write-Log -Message "Encodage du fichier corrigé: $file" -Level "SUCCESS"
        }
        
        Write-Log -Message "Correction des scripts terminée." -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Erreur lors de la correction des scripts: $_" -Level "ERROR"
    }
}

# Fonction principale
function Main {
    try {
        # Vérifier si l'aide est demandée
        if ($Help) {
            Show-Help
            return
        }
        
        # Mode interactif
        if ($Interactive) {
            $continue = $true
            while ($continue) {
                $continue = Show-Menu
            }
            return
        }
        
        # Exécuter les fonctions en fonction des paramètres
        if ($Organize) {
            Invoke-OrganizeScripts
        }
        
        if ($Execute) {
            Invoke-ExecuteRoadmap
        }
        
        if ($Analyze) {
            Invoke-AnalyzeRoadmap
        }
        
        if ($GitUpdate) {
            Invoke-GitUpdateRoadmap
        }
        
        if ($Cleanup) {
            Invoke-CleanupFiles
        }
        
        if ($FixScripts) {
            Invoke-FixScripts
        }
        
        # Si aucun paramètre n'est spécifié, afficher l'aide
        if (-not ($Organize -or $Execute -or $Analyze -or $GitUpdate -or $Cleanup -or $FixScripts -or $Help -or $Interactive)) {
            Show-Help
        }
    }
    catch {
        Write-Log -Message "Une erreur critique s'est produite: $_" -Level "ERROR"
        exit 1
    }
}

# Exécuter la fonction principale
Main
