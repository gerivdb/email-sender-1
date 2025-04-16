# Script d'aide pour utiliser roadmap_perso_fixed.md
# Ce script appelle RoadmapManager.ps1 avec le chemin vers roadmap_perso_fixed.md

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
    Write-Host "Ce script permet d'utiliser roadmap_perso_fixed.md avec RoadmapManager.ps1."
    Write-Host ""
    Write-Host "Paramètres :" -ForegroundColor Yellow
    Write-Host "  -Organize     : Organiser les scripts de roadmap"
    Write-Host "  -Execute      : Exécuter la roadmap"
    Write-Host "  -Analyze      : Analyser la roadmap et générer des rapports"
    Write-Host "  -GitUpdate    : Mettre à jour la roadmap en fonction des commits Git"
    Write-Host "  -Cleanup      : Nettoyer et organiser les fichiers liés à la roadmap"
    Write-Host "  -Interactive  : Mode interactif (menu)"
    Write-Host "  -Help         : Afficher cette aide"
    Write-Host ""
    Write-Host "Exemples :" -ForegroundColor Yellow
    Write-Host "  .\UseFixedRoadmap.ps1 -Analyze"
    Write-Host "  .\UseFixedRoadmap.ps1 -GitUpdate"
    Write-Host "  .\UseFixedRoadmap.ps1 -Interactive"
    Write-Host ""
}

# Fonction pour vérifier si le fichier roadmap_perso_fixed.md existe
function Test-FixedRoadmapExists {
    if (-not (Test-Path -Path $fixedRoadmapPath)) {
        Write-Log -Message "Le fichier roadmap_perso_fixed.md n'existe pas." -Level "ERROR"
        Write-Log -Message "Veuillez créer ce fichier ou utiliser roadmap_perso.md à la place." -Level "ERROR"
        return $false
    }
    return $true
}

# Fonction pour s'assurer que tous les scripts sont dans le bon dossier
function Ensure-ScriptsInCorrectFolder {
    Write-Log -Message "Vérification de l'emplacement des scripts..." -Level "INFO"
    
    # Liste des scripts principaux
    $mainScripts = @(
        "RoadmapManager.ps1",
        "RoadmapAnalyzer.ps1",
        "RoadmapGitUpdater.ps1",
        "CleanupRoadmapFiles.ps1",
        "OrganizeRoadmapScripts.ps1",
        "UseFixedRoadmap.ps1",
        "README.md"
    )
    
    # Vérifier si le dossier scripts existe
    if (-not (Test-Path -Path $scriptsFolder)) {
        New-Item -Path $scriptsFolder -ItemType Directory -Force | Out-Null
        Write-Log -Message "Dossier '$scriptsFolder' créé." -Level "SUCCESS"
    }
    
    # Déplacer les scripts dans le bon dossier
    foreach ($script in $mainScripts) {
        $sourcePath = $script
        $destinationPath = Join-Path -Path $scriptsFolder -ChildPath $script
        
        # Si le script existe à la racine mais pas dans le dossier scripts
        if ((Test-Path -Path $sourcePath) -and (-not (Test-Path -Path $destinationPath))) {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
            Write-Log -Message "Script '$script' copié vers '$destinationPath'." -Level "SUCCESS"
        }
    }
    
    # Supprimer les fichiers obsolètes
    $obsoleteScripts = @(
        "CleanupRedundantRoadmapScripts.ps1",
        "CleanupRoadmapManagementScripts.ps1",
        "FixRoadmapEncoding.ps1"
    )
    
    foreach ($script in $obsoleteScripts) {
        $scriptPath = Join-Path -Path $scriptsFolder -ChildPath $script
        if (Test-Path -Path $scriptPath) {
            Remove-Item -Path $scriptPath -Force
            Write-Log -Message "Fichier obsolète '$script' supprimé." -Level "SUCCESS"
        }
    }
    
    Write-Log -Message "Vérification terminée." -Level "SUCCESS"
}

# Fonction principale
function Main {
    # Vérifier si l'aide est demandée
    if ($Help) {
        Show-Help
        return
    }
    
    # S'assurer que tous les scripts sont dans le bon dossier
    Ensure-ScriptsInCorrectFolder
    
    # Vérifier si le fichier roadmap_perso_fixed.md existe
    if (-not (Test-FixedRoadmapExists)) {
        return
    }
    
    # Construire les arguments pour RoadmapManager.ps1
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
    
    # Si aucun paramètre n'est spécifié, utiliser le mode interactif
    if (-not ($Organize -or $Execute -or $Analyze -or $GitUpdate -or $Cleanup -or $Interactive -or $Help)) {
        $arguments += "-Interactive"
    }
    
    # Construire la commande
    $roadmapManagerPath = Join-Path -Path $scriptsFolder -ChildPath "RoadmapManager.ps1"
    $command = "& `"$roadmapManagerPath`" $($arguments -join ' ')"
    
    Write-Log -Message "Exécution de la commande : $command" -Level "INFO"
    
    # Exécuter la commande
    try {
        Invoke-Expression $command
    }
    catch {
        Write-Log -Message "Erreur lors de l'exécution de RoadmapManager.ps1 : $_" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Main
