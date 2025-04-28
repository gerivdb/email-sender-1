<#
.SYNOPSIS
    Script de vérification de l'installation du gestionnaire intégré.

.DESCRIPTION
    Ce script vérifie que tous les composants nécessaires au fonctionnement du gestionnaire intégré
    sont correctement installés et configurés.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json"

.PARAMETER Verbose
    Affiche des informations détaillées sur l'exécution.

.EXAMPLE
    .\verify-installation.ps1

.EXAMPLE
    .\verify-installation.ps1 -ConfigPath "my-config.json" -Verbose

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de création: 2023-06-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json"
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and 
       -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
}

# Fonction pour afficher les résultats
function Write-Result {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Component,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )
    
    $status = if ($Success) { "OK" } else { "ÉCHEC" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] " -ForegroundColor $color -NoNewline
    Write-Host "$Component" -NoNewline
    
    if ($Details) {
        Write-Host " - $Details"
    } else {
        Write-Host ""
    }
}

# Afficher l'en-tête
Write-Host "Vérification de l'installation du gestionnaire intégré" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que PowerShell est correctement installé
$psVersion = $PSVersionTable.PSVersion
$psSuccess = $psVersion.Major -ge 5
Write-Result -Component "PowerShell" -Success $psSuccess -Details "Version $($psVersion.ToString())"

# Vérifier que le module Pester est installé
$pesterSuccess = $false
try {
    $pesterModule = Get-Module -Name Pester -ListAvailable
    $pesterSuccess = $null -ne $pesterModule
    $pesterDetails = if ($pesterSuccess) { "Version $($pesterModule[0].Version.ToString())" } else { "Non installé" }
} catch {
    $pesterDetails = "Erreur lors de la vérification : $_"
}
Write-Result -Component "Module Pester" -Success $pesterSuccess -Details $pesterDetails

# Vérifier que le fichier de configuration existe
$configSuccess = Test-Path -Path $ConfigPath
$configDetails = if ($configSuccess) { $ConfigPath } else { "Fichier introuvable : $ConfigPath" }
Write-Result -Component "Fichier de configuration" -Success $configSuccess -Details $configDetails

# Vérifier que le fichier de configuration est valide
$configValidSuccess = $false
$config = $null
if ($configSuccess) {
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        $configValidSuccess = $null -ne $config
        $configValidDetails = if ($configValidSuccess) { "Format JSON valide" } else { "Format JSON invalide" }
    } catch {
        $configValidDetails = "Erreur lors de la lecture : $_"
    }
} else {
    $configValidDetails = "Fichier introuvable"
}
Write-Result -Component "Configuration valide" -Success $configValidSuccess -Details $configValidDetails

# Vérifier que le gestionnaire intégré existe
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"
$integratedManagerSuccess = Test-Path -Path $integratedManagerPath
$integratedManagerDetails = if ($integratedManagerSuccess) { $integratedManagerPath } else { "Fichier introuvable : $integratedManagerPath" }
Write-Result -Component "Gestionnaire intégré" -Success $integratedManagerSuccess -Details $integratedManagerDetails

# Vérifier que les modes existent
$modes = @(
    @{ Name = "CHECK"; Path = "development\scripts\maintenance\modes\check.ps1" },
    @{ Name = "GRAN"; Path = "development\scripts\maintenance\modes\gran-mode.ps1" },
    @{ Name = "ROADMAP-SYNC"; Path = "development\scripts\maintenance\modes\roadmap-sync-mode.ps1" },
    @{ Name = "ROADMAP-REPORT"; Path = "development\scripts\maintenance\modes\roadmap-report-mode.ps1" },
    @{ Name = "ROADMAP-PLAN"; Path = "development\scripts\maintenance\modes\roadmap-plan-mode.ps1" }
)

$modesSuccess = $true
$modesDetails = ""

foreach ($mode in $modes) {
    $modePath = Join-Path -Path $projectRoot -ChildPath $mode.Path
    $modeSuccess = Test-Path -Path $modePath
    $modesSuccess = $modesSuccess -and $modeSuccess
    
    $modeStatus = if ($modeSuccess) { "OK" } else { "ÉCHEC" }
    $modeColor = if ($modeSuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$modeStatus] " -ForegroundColor $modeColor -NoNewline
    Write-Host "Mode $($mode.Name)" -NoNewline
    
    if (-not $modeSuccess) {
        Write-Host " - Fichier introuvable : $modePath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Modes" -Success $modesSuccess -Details "$($modes.Count) modes vérifiés"

# Vérifier que les workflows existent
$workflows = @(
    @{ Name = "Quotidien"; Path = "development\scripts\workflows\workflow-quotidien.ps1" },
    @{ Name = "Hebdomadaire"; Path = "development\scripts\workflows\workflow-hebdomadaire.ps1" },
    @{ Name = "Mensuel"; Path = "development\scripts\workflows\workflow-mensuel.ps1" },
    @{ Name = "Installation des tâches planifiées"; Path = "development\scripts\workflows\install-scheduled-tasks.ps1" }
)

$workflowsSuccess = $true
$workflowsDetails = ""

foreach ($workflow in $workflows) {
    $workflowPath = Join-Path -Path $projectRoot -ChildPath $workflow.Path
    $workflowSuccess = Test-Path -Path $workflowPath
    $workflowsSuccess = $workflowsSuccess -and $workflowSuccess
    
    $workflowStatus = if ($workflowSuccess) { "OK" } else { "ÉCHEC" }
    $workflowColor = if ($workflowSuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$workflowStatus] " -ForegroundColor $workflowColor -NoNewline
    Write-Host "Workflow $($workflow.Name)" -NoNewline
    
    if (-not $workflowSuccess) {
        Write-Host " - Fichier introuvable : $workflowPath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Workflows" -Success $workflowsSuccess -Details "$($workflows.Count) workflows vérifiés"

# Vérifier que la documentation existe
$docs = @(
    @{ Name = "Guide d'utilisation"; Path = "development\docs\guides\user-guides\integrated-manager-guide.md" },
    @{ Name = "Guide de démarrage rapide"; Path = "development\docs\guides\user-guides\integrated-manager-quickstart.md" },
    @{ Name = "Référence des paramètres"; Path = "development\docs\guides\reference\integrated-manager-parameters.md" },
    @{ Name = "Exemples d'utilisation"; Path = "development\docs\guides\examples\roadmap-modes-examples.md" },
    @{ Name = "Bonnes pratiques"; Path = "development\docs\guides\best-practices\roadmap-management.md" },
    @{ Name = "Workflows automatisés"; Path = "development\docs\guides\automation\roadmap-workflows.md" }
)

$docsSuccess = $true
$docsDetails = ""

foreach ($doc in $docs) {
    $docPath = Join-Path -Path $projectRoot -ChildPath $doc.Path
    $docSuccess = Test-Path -Path $docPath
    $docsSuccess = $docsSuccess -and $docSuccess
    
    $docStatus = if ($docSuccess) { "OK" } else { "ÉCHEC" }
    $docColor = if ($docSuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$docStatus] " -ForegroundColor $docColor -NoNewline
    Write-Host "Documentation $($doc.Name)" -NoNewline
    
    if (-not $docSuccess) {
        Write-Host " - Fichier introuvable : $docPath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Documentation" -Success $docsSuccess -Details "$($docs.Count) documents vérifiés"

# Vérifier que les répertoires nécessaires existent
$directories = @(
    @{ Name = "Roadmaps"; Path = "projet\roadmaps" },
    @{ Name = "Rapports"; Path = "projet\roadmaps\Reports" },
    @{ Name = "Plans"; Path = "projet\roadmaps\Plans" },
    @{ Name = "Logs"; Path = "projet\roadmaps\Logs" }
)

$directoriesSuccess = $true
$directoriesDetails = ""

foreach ($directory in $directories) {
    $directoryPath = Join-Path -Path $projectRoot -ChildPath $directory.Path
    $directorySuccess = Test-Path -Path $directoryPath -PathType Container
    
    if (-not $directorySuccess) {
        # Créer le répertoire s'il n'existe pas
        try {
            New-Item -Path $directoryPath -ItemType Directory -Force | Out-Null
            $directorySuccess = $true
            $directoryDetails = "Répertoire créé"
        } catch {
            $directoryDetails = "Erreur lors de la création : $_"
        }
    } else {
        $directoryDetails = "Répertoire existant"
    }
    
    $directoriesSuccess = $directoriesSuccess -and $directorySuccess
    
    $directoryStatus = if ($directorySuccess) { "OK" } else { "ÉCHEC" }
    $directoryColor = if ($directorySuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$directoryStatus] " -ForegroundColor $directoryColor -NoNewline
    Write-Host "Répertoire $($directory.Name)" -NoNewline
    
    Write-Host " - $directoryDetails"
}

Write-Result -Component "Répertoires" -Success $directoriesSuccess -Details "$($directories.Count) répertoires vérifiés"

# Vérifier que les tâches planifiées sont installées
$scheduledTasksSuccess = $false
$scheduledTasksDetails = ""

try {
    $tasks = Get-ScheduledTask -TaskName "RoadmapManager-*" -ErrorAction SilentlyContinue
    $scheduledTasksSuccess = $null -ne $tasks -and $tasks.Count -gt 0
    $scheduledTasksDetails = if ($scheduledTasksSuccess) { "$($tasks.Count) tâches planifiées trouvées" } else { "Aucune tâche planifiée trouvée" }
} catch {
    $scheduledTasksDetails = "Erreur lors de la vérification : $_"
}

Write-Result -Component "Tâches planifiées" -Success $scheduledTasksSuccess -Details $scheduledTasksDetails

# Afficher le résumé
Write-Host ""
Write-Host "Résumé de la vérification" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

$totalSuccess = $psSuccess -and $pesterSuccess -and $configSuccess -and $configValidSuccess -and $integratedManagerSuccess -and $modesSuccess -and $workflowsSuccess -and $docsSuccess -and $directoriesSuccess
$totalStatus = if ($totalSuccess) { "SUCCÈS" } else { "ÉCHEC" }
$totalColor = if ($totalSuccess) { "Green" } else { "Red" }

Write-Host "Résultat global : " -NoNewline
Write-Host "[$totalStatus]" -ForegroundColor $totalColor

if (-not $totalSuccess) {
    Write-Host ""
    Write-Host "Actions recommandées :" -ForegroundColor Yellow
    
    if (-not $psSuccess) {
        Write-Host "- Mettre à jour PowerShell vers la version 5.1 ou supérieure"
    }
    
    if (-not $pesterSuccess) {
        Write-Host "- Installer le module Pester : Install-Module -Name Pester -Force -SkipPublisherCheck"
    }
    
    if (-not $configSuccess) {
        Write-Host "- Créer le fichier de configuration : $ConfigPath"
    } elseif (-not $configValidSuccess) {
        Write-Host "- Corriger le format du fichier de configuration : $ConfigPath"
    }
    
    if (-not $integratedManagerSuccess) {
        Write-Host "- Créer le gestionnaire intégré : $integratedManagerPath"
    }
    
    if (-not $modesSuccess) {
        Write-Host "- Créer les modes manquants dans le répertoire development\scripts\maintenance\modes\"
    }
    
    if (-not $workflowsSuccess) {
        Write-Host "- Créer les workflows manquants dans le répertoire development\scripts\workflows\"
    }
    
    if (-not $docsSuccess) {
        Write-Host "- Créer la documentation manquante dans le répertoire development\docs\guides\"
    }
    
    if (-not $scheduledTasksSuccess) {
        Write-Host "- Installer les tâches planifiées : .\development\scripts\workflows\install-scheduled-tasks.ps1"
    }
} else {
    Write-Host ""
    Write-Host "Toutes les vérifications ont réussi. Le gestionnaire intégré est correctement installé et configuré." -ForegroundColor Green
}

# Retourner un résultat
return @{
    Success = $totalSuccess
    PowerShell = @{ Success = $psSuccess; Details = $psVersion.ToString() }
    Pester = @{ Success = $pesterSuccess; Details = $pesterDetails }
    Config = @{ Success = $configSuccess -and $configValidSuccess; Details = $ConfigPath }
    IntegratedManager = @{ Success = $integratedManagerSuccess; Details = $integratedManagerPath }
    Modes = @{ Success = $modesSuccess; Details = "$($modes.Count) modes vérifiés" }
    Workflows = @{ Success = $workflowsSuccess; Details = "$($workflows.Count) workflows vérifiés" }
    Documentation = @{ Success = $docsSuccess; Details = "$($docs.Count) documents vérifiés" }
    Directories = @{ Success = $directoriesSuccess; Details = "$($directories.Count) répertoires vérifiés" }
    ScheduledTasks = @{ Success = $scheduledTasksSuccess; Details = $scheduledTasksDetails }
}
