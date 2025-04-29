# Script d'aide pour utiliser roadmap_perso_fixed.md
# Ce script appelle roadmap-manager.ps1 avec le chemin vers roadmap_perso_fixed.md

param (
    [switch]$Organize,
    [switch]$Execute,
    [switch]$Analyze,
    [switch]$GitUpdate,
    [switch]$Cleanup,
    [switch]$Interactive,
    [switch]$Help
)

# Configuration
$fixedRoadmapPath = "Roadmap\roadmap_perso_fixed.md"
$scriptsFolder = "Roadmap\scripts"

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
    Write-Host "Utilisation de roadmap_perso_fixed.md" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ce script permet d'utiliser roadmap_perso_fixed.md avec roadmap-manager.ps1."
    Write-Host ""
    Write-Host "ParamÃ¨tres :" -ForegroundColor Yellow
    Write-Host "  -Organize     : Organiser les scripts de roadmap"
    Write-Host "  -Execute      : ExÃ©cuter la roadmap"
    Write-Host "  -Analyze      : Analyser la roadmap et gÃ©nÃ©rer des rapports"
    Write-Host "  -GitUpdate    : Mettre Ã  jour la roadmap en fonction des commits Git"
    Write-Host "  -Cleanup      : Nettoyer et organiser les fichiers liÃ©s Ã  la roadmap"
    Write-Host "  -Interactive  : Mode interactif (menu)"
    Write-Host "  -Help         : Afficher cette aide"
    Write-Host ""
    Write-Host "Exemples :" -ForegroundColor Yellow
    Write-Host "  .\UseFixedRoadmap.ps1 -Analyze"
    Write-Host "  .\UseFixedRoadmap.ps1 -GitUpdate"
    Write-Host "  .\UseFixedRoadmap.ps1 -Interactive"
    Write-Host ""
}

# Fonction pour vÃ©rifier si le fichier roadmap_perso_fixed.md existe
function Test-FixedRoadmapExists {
    if (-not (Test-Path -Path $fixedRoadmapPath)) {
        Write-Log -Message "Le fichier roadmap_perso_fixed.md n'existe pas." -Level "ERROR"
        Write-Log -Message "Veuillez crÃ©er ce fichier ou utiliser roadmap_perso.md Ã  la place." -Level "ERROR"
        return $false
    }
    return $true
}

# Fonction pour s'assurer que tous les scripts sont dans le bon dossier
function Ensure-ScriptsInCorrectFolder {
    Write-Log -Message "VÃ©rification de l'emplacement des scripts..." -Level "INFO"
    
    # Liste des scripts principaux
    $mainScripts = @(
        "roadmap-manager.ps1",
        "RoadmapAnalyzer.ps1",
        "RoadmapGitUpdater.ps1",
        "CleanupRoadmapFiles.ps1",
        "OrganizeRoadmapScripts.ps1",
        "UseFixedRoadmap.ps1",
        "README.md"
    )
    
    # VÃ©rifier si le dossier scripts existe
    if (-not (Test-Path -Path $scriptsFolder)) {
        New-Item -Path $scriptsFolder -ItemType Directory -Force | Out-Null
        Write-Log -Message "Dossier '$scriptsFolder' crÃ©Ã©." -Level "SUCCESS"
    }
    
    # DÃ©placer les scripts dans le bon dossier
    foreach ($script in $mainScripts) {
        $sourcePath = $script
        $destinationPath = Join-Path -Path $scriptsFolder -ChildPath $script
        
        # Si le script existe Ã  la racine mais pas dans le dossier scripts
        if ((Test-Path -Path $sourcePath) -and (-not (Test-Path -Path $destinationPath))) {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
            Write-Log -Message "Script '$script' copiÃ© vers '$destinationPath'." -Level "SUCCESS"
        }
    }
    
    # Supprimer les fichiers obsolÃ¨tes
    $obsoleteScripts = @(
        "CleanupRedundantRoadmapScripts.ps1",
        "CleanupRoadmapManagementScripts.ps1",
        "FixRoadmapEncoding.ps1"
    )
    
    foreach ($script in $obsoleteScripts) {
        $scriptPath = Join-Path -Path $scriptsFolder -ChildPath $script
        if (Test-Path -Path $scriptPath) {
            Remove-Item -Path $scriptPath -Force
            Write-Log -Message "Fichier obsolÃ¨te '$script' supprimÃ©." -Level "SUCCESS"
        }
    }
    
    Write-Log -Message "VÃ©rification terminÃ©e." -Level "SUCCESS"
}

# Fonction principale
function Main {
    # VÃ©rifier si l'aide est demandÃ©e
    if ($Help) {
        Show-Help
        return
    }
    
    # S'assurer que tous les scripts sont dans le bon dossier
    Ensure-ScriptsInCorrectFolder
    
    # VÃ©rifier si le fichier roadmap_perso_fixed.md existe
    if (-not (Test-FixedRoadmapExists)) {
        return
    }
    
    # Construire les arguments pour roadmap-manager.ps1
    $arguments = @("-RoadmapPath", "`"$fixedRoadmapPath`"")
    
    if ($Organize) {
        $arguments += "-Organize"
    }
    
    if ($Execute) {
        $arguments += "-Execute"
    }
    
    if ($Analyze) {
        $arguments += "-Analyze"
    }
    
    if ($GitUpdate) {
        $arguments += "-GitUpdate"
    }
    
    if ($Cleanup) {
        $arguments += "-Cleanup"
    }
    
    if ($Interactive) {
        $arguments += "-Interactive"
    }
    
    # Si aucun paramÃ¨tre n'est spÃ©cifiÃ©, utiliser le mode interactif
    if (-not ($Organize -or $Execute -or $Analyze -or $GitUpdate -or $Cleanup -or $Interactive -or $Help)) {
        $arguments += "-Interactive"
    }
    
    # Construire la commande
    $roadmap-managerPath = Join-Path -Path $scriptsFolder -ChildPath "roadmap-manager.ps1"
    $command = "& `"$roadmap-managerPath`" $($arguments -join ' ')"
    
    Write-Log -Message "ExÃ©cution de la commande : $command" -Level "INFO"
    
    # ExÃ©cuter la commande
    try {
        Invoke-Expression $command
    }
    catch {
        Write-Log -Message "Erreur lors de l'exÃ©cution de roadmap-manager.ps1 : $_" -Level "ERROR"
    }
}

# ExÃ©cuter la fonction principale
Main

