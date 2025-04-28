<#
.SYNOPSIS
    Script d'installation rapide du gestionnaire intégré.

.DESCRIPTION
    Ce script permet d'installer et de configurer rapidement le gestionnaire intégré.
    Il crée les répertoires nécessaires, configure les paramètres et installe les tâches planifiées.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json"

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap principal.
    Par défaut : "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

.PARAMETER InstallScheduledTasks
    Indique si les tâches planifiées doivent être installées.
    Par défaut : $true

.PARAMETER Force
    Indique si les fichiers existants doivent être remplacés.
    Par défaut : $false

.PARAMETER Verbose
    Affiche des informations détaillées sur l'exécution.

.EXAMPLE
    .\install-integrated-manager.ps1

.EXAMPLE
    .\install-integrated-manager.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md" -InstallScheduledTasks $false

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de création: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json",

    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet\roadmaps\Roadmap\roadmap_complete_converted.md",

    [Parameter(Mandatory = $false)]
    [bool]$InstallScheduledTasks = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force
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

if (-not [System.IO.Path]::IsPathRooted($RoadmapPath)) {
    $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $RoadmapPath
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
Write-Host "Installation rapide du gestionnaire intégré" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que PowerShell est correctement installé
$psVersion = $PSVersionTable.PSVersion
$psSuccess = $psVersion.Major -ge 5
Write-Result -Component "PowerShell" -Success $psSuccess -Details "Version $($psVersion.ToString())"

if (-not $psSuccess) {
    Write-Error "PowerShell 5.1 ou supérieur est requis pour installer le gestionnaire intégré."
    exit 1
}

# Installer le module Pester s'il n'est pas déjà installé
$pesterSuccess = $false
try {
    $pesterModule = Get-Module -Name Pester -ListAvailable
    $pesterSuccess = $null -ne $pesterModule
    
    if (-not $pesterSuccess) {
        Write-Host "Installation du module Pester..." -ForegroundColor Yellow
        
        if ($PSCmdlet.ShouldProcess("Module Pester", "Installer")) {
            Install-Module -Name Pester -Force -SkipPublisherCheck
            $pesterModule = Get-Module -Name Pester -ListAvailable
            $pesterSuccess = $null -ne $pesterModule
        }
    }
    
    $pesterDetails = if ($pesterSuccess) { "Version $($pesterModule[0].Version.ToString())" } else { "Non installé" }
} catch {
    $pesterDetails = "Erreur lors de l'installation : $_"
}
Write-Result -Component "Module Pester" -Success $pesterSuccess -Details $pesterDetails

# Créer les répertoires nécessaires
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
            if ($PSCmdlet.ShouldProcess($directoryPath, "Créer le répertoire")) {
                New-Item -Path $directoryPath -ItemType Directory -Force | Out-Null
                $directorySuccess = $true
                $directoryDetails = "Répertoire créé"
            } else {
                $directoryDetails = "Création simulée"
            }
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

# Créer un fichier de roadmap de test si nécessaire
$roadmapSuccess = Test-Path -Path $RoadmapPath
$roadmapDetails = ""

if (-not $roadmapSuccess) {
    # Créer le répertoire parent s'il n'existe pas
    $roadmapDir = Split-Path -Parent $RoadmapPath
    if (-not (Test-Path -Path $roadmapDir -PathType Container)) {
        try {
            if ($PSCmdlet.ShouldProcess($roadmapDir, "Créer le répertoire")) {
                New-Item -Path $roadmapDir -ItemType Directory -Force | Out-Null
            }
        } catch {
            $roadmapDetails = "Erreur lors de la création du répertoire : $_"
            Write-Result -Component "Roadmap" -Success $false -Details $roadmapDetails
        }
    }
    
    # Créer le fichier de roadmap
    try {
        if ($PSCmdlet.ShouldProcess($RoadmapPath, "Créer le fichier de roadmap")) {
            $roadmapContent = @"
# Roadmap du projet

## Tâche 1: Initialisation du projet

### Description
Cette tâche vise à initialiser le projet et à mettre en place les outils nécessaires.

### Sous-tâches
- [ ] **1.1** Configurer l'environnement de développement
- [ ] **1.2** Installer les dépendances
- [ ] **1.3** Créer la structure du projet
- [ ] **1.4** Configurer les outils de gestion de projet
- [ ] **1.5** Documenter le processus d'installation

## Tâche 2: Développement des fonctionnalités

### Description
Cette tâche vise à développer les fonctionnalités principales du projet.

### Sous-tâches
- [ ] **2.1** Développer la fonctionnalité A
- [ ] **2.2** Développer la fonctionnalité B
- [ ] **2.3** Développer la fonctionnalité C
- [ ] **2.4** Tester les fonctionnalités
- [ ] **2.5** Documenter les fonctionnalités

## Tâche 3: Déploiement

### Description
Cette tâche vise à déployer le projet en production.

### Sous-tâches
- [ ] **3.1** Préparer l'environnement de production
- [ ] **3.2** Configurer les serveurs
- [ ] **3.3** Déployer l'application
- [ ] **3.4** Tester le déploiement
- [ ] **3.5** Documenter le processus de déploiement
"@
            
            Set-Content -Path $RoadmapPath -Value $roadmapContent -Encoding UTF8
            $roadmapSuccess = $true
            $roadmapDetails = "Fichier créé"
        } else {
            $roadmapDetails = "Création simulée"
        }
    } catch {
        $roadmapDetails = "Erreur lors de la création : $_"
    }
} else {
    $roadmapDetails = "Fichier existant"
}

Write-Result -Component "Roadmap" -Success $roadmapSuccess -Details $roadmapDetails

# Créer ou mettre à jour le fichier de configuration
$configSuccess = $false
$configDetails = ""

try {
    if (Test-Path -Path $ConfigPath) {
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($ConfigPath, "Mettre à jour le fichier de configuration")) {
                $configContent = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
                
                # Mettre à jour les chemins
                $configContent.General.RoadmapPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                $configContent.General.ActiveDocumentPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                
                # Mettre à jour les modes
                if (-not $configContent.Modes.RoadmapSync) {
                    $configContent.Modes | Add-Member -MemberType NoteProperty -Name "RoadmapSync" -Value @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\roadmap-sync-mode.ps1"
                        DefaultSourceFormat = "Markdown"
                        DefaultTargetFormat = "JSON"
                        DefaultSourcePath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                        DefaultTargetPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace(".md", ".json").Replace("\", "\\")
                    }
                }
                
                if (-not $configContent.Modes.RoadmapReport) {
                    $configContent.Modes | Add-Member -MemberType NoteProperty -Name "RoadmapReport" -Value @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\roadmap-report-mode.ps1"
                        DefaultReportFormat = "HTML"
                        DefaultOutputPath = "projet\\roadmaps\\Reports"
                        IncludeCharts = $true
                        IncludeTrends = $true
                        IncludePredictions = $true
                        DaysToAnalyze = 30
                    }
                }
                
                if (-not $configContent.Modes.RoadmapPlan) {
                    $configContent.Modes | Add-Member -MemberType NoteProperty -Name "RoadmapPlan" -Value @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\roadmap-plan-mode.ps1"
                        DefaultOutputPath = "projet\\roadmaps\\Plans"
                        DaysToForecast = 30
                    }
                }
                
                # Mettre à jour les workflows
                if (-not $configContent.Workflows.RoadmapManagement) {
                    $configContent.Workflows | Add-Member -MemberType NoteProperty -Name "RoadmapManagement" -Value @{
                        Description = "Workflow de gestion de roadmap"
                        Modes = @("ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN")
                        AutoContinue = $true
                        StopOnError = $true
                    }
                }
                
                $configJson = ConvertTo-Json -InputObject $configContent -Depth 10
                Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
                $configSuccess = $true
                $configDetails = "Fichier mis à jour"
            } else {
                $configDetails = "Mise à jour simulée"
            }
        } else {
            $configSuccess = $true
            $configDetails = "Fichier existant (utilisez -Force pour le mettre à jour)"
        }
    } else {
        # Créer le répertoire parent s'il n'existe pas
        $configDir = Split-Path -Parent $ConfigPath
        if (-not (Test-Path -Path $configDir -PathType Container)) {
            try {
                if ($PSCmdlet.ShouldProcess($configDir, "Créer le répertoire")) {
                    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                }
            } catch {
                $configDetails = "Erreur lors de la création du répertoire : $_"
                Write-Result -Component "Configuration" -Success $false -Details $configDetails
            }
        }
        
        # Créer le fichier de configuration
        if ($PSCmdlet.ShouldProcess($ConfigPath, "Créer le fichier de configuration")) {
            $configContent = @{
                General = @{
                    RoadmapPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                    ActiveDocumentPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                    ReportPath = "projet\\roadmaps\\Reports"
                    LogPath = "projet\\roadmaps\\Logs"
                    DefaultLanguage = "fr-FR"
                    DefaultEncoding = "UTF8-BOM"
                    ProjectRoot = $projectRoot.Replace("\", "\\")
                }
                Modes = @{
                    Check = @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\check.ps1"
                        DefaultRoadmapFile = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                        DefaultActiveDocumentPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                        AutoUpdateRoadmap = $true
                        GenerateReport = $true
                        ReportPath = "projet\\roadmaps\\Reports"
                        AutoUpdateCheckboxes = $true
                        RequireFullTestCoverage = $true
                        SimulationModeDefault = $true
                    }
                    Gran = @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\gran-mode.ps1"
                        DefaultRoadmapFile = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                        MaxTaskSize = 5
                        MaxComplexity = 7
                        AutoIndent = $true
                        GenerateSubtasks = $true
                        UpdateInPlace = $true
                        IndentationStyle = "Spaces2"
                        CheckboxStyle = "GitHub"
                    }
                    RoadmapSync = @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\roadmap-sync-mode.ps1"
                        DefaultSourceFormat = "Markdown"
                        DefaultTargetFormat = "JSON"
                        DefaultSourcePath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                        DefaultTargetPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace(".md", ".json").Replace("\", "\\")
                    }
                    RoadmapReport = @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\roadmap-report-mode.ps1"
                        DefaultReportFormat = "HTML"
                        DefaultOutputPath = "projet\\roadmaps\\Reports"
                        IncludeCharts = $true
                        IncludeTrends = $true
                        IncludePredictions = $true
                        DaysToAnalyze = 30
                    }
                    RoadmapPlan = @{
                        Enabled = $true
                        ScriptPath = "development\\scripts\\maintenance\\modes\\roadmap-plan-mode.ps1"
                        DefaultOutputPath = "projet\\roadmaps\\Plans"
                        DaysToForecast = 30
                    }
                }
                Roadmaps = @{
                    Main = @{
                        Path = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                        Description = "Roadmap principale"
                        Format = "Markdown"
                        AutoUpdate = $true
                        GitIntegration = $false
                        ReportPath = "projet\\roadmaps\\Reports"
                    }
                }
                Workflows = @{
                    Development = @{
                        Description = "Workflow de développement complet"
                        Modes = @("GRAN", "DEV-R", "TEST", "CHECK")
                        AutoContinue = $true
                        StopOnError = $true
                    }
                    RoadmapManagement = @{
                        Description = "Workflow de gestion de roadmap"
                        Modes = @("ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN")
                        AutoContinue = $true
                        StopOnError = $true
                    }
                }
                Integration = @{
                    EnabledByDefault = $true
                    DefaultWorkflow = "RoadmapManagement"
                    DefaultRoadmap = "Main"
                    AutoSaveResults = $true
                    ResultsPath = "projet\\roadmaps\\Reports"
                    LogLevel = "Info"
                    NotifyOnCompletion = $true
                    MaxConcurrentTasks = 4
                }
            }
            
            $configJson = ConvertTo-Json -InputObject $configContent -Depth 10
            Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
            $configSuccess = $true
            $configDetails = "Fichier créé"
        } else {
            $configDetails = "Création simulée"
        }
    }
} catch {
    $configDetails = "Erreur lors de la création/mise à jour : $_"
}

Write-Result -Component "Configuration" -Success $configSuccess -Details $configDetails

# Installer les tâches planifiées si demandé
$scheduledTasksSuccess = $true
$scheduledTasksDetails = ""

if ($InstallScheduledTasks) {
    $installScheduledTasksPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\install-scheduled-tasks.ps1"
    
    if (Test-Path -Path $installScheduledTasksPath) {
        try {
            if ($PSCmdlet.ShouldProcess("Tâches planifiées", "Installer")) {
                Write-Host "Installation des tâches planifiées..." -ForegroundColor Yellow
                
                $params = @{}
                if ($Force) {
                    $params.Add("Force", $true)
                }
                
                & $installScheduledTasksPath @params
                
                $tasks = Get-ScheduledTask -TaskName "RoadmapManager-*" -ErrorAction SilentlyContinue
                $scheduledTasksSuccess = $null -ne $tasks -and $tasks.Count -gt 0
                $scheduledTasksDetails = if ($scheduledTasksSuccess) { "$($tasks.Count) tâches planifiées installées" } else { "Aucune tâche planifiée installée" }
            } else {
                $scheduledTasksDetails = "Installation simulée"
            }
        } catch {
            $scheduledTasksSuccess = $false
            $scheduledTasksDetails = "Erreur lors de l'installation : $_"
        }
    } else {
        $scheduledTasksSuccess = $false
        $scheduledTasksDetails = "Script d'installation introuvable : $installScheduledTasksPath"
    }
} else {
    $scheduledTasksDetails = "Installation ignorée (utilisez -InstallScheduledTasks `$true pour installer)"
}

Write-Result -Component "Tâches planifiées" -Success $scheduledTasksSuccess -Details $scheduledTasksDetails

# Vérifier l'installation
$verifyInstallationPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\verify-installation.ps1"

if (Test-Path -Path $verifyInstallationPath) {
    try {
        if ($PSCmdlet.ShouldProcess("Installation", "Vérifier")) {
            Write-Host ""
            Write-Host "Vérification de l'installation..." -ForegroundColor Yellow
            
            & $verifyInstallationPath -ConfigPath $ConfigPath
        }
    } catch {
        Write-Error "Erreur lors de la vérification de l'installation : $_"
    }
} else {
    Write-Warning "Script de vérification introuvable : $verifyInstallationPath"
}

# Afficher les prochaines étapes
Write-Host ""
Write-Host "Installation terminée. Prochaines étapes :" -ForegroundColor Cyan
Write-Host "1. Exécuter le gestionnaire intégré : .\development\scripts\integrated-manager.ps1 -ListModes" -ForegroundColor Gray
Write-Host "2. Exécuter un workflow : .\development\scripts\integrated-manager.ps1 -Workflow RoadmapManagement -RoadmapPath `"$RoadmapPath`"" -ForegroundColor Gray
Write-Host "3. Consulter la documentation : .\development\docs\guides\user-guides\integrated-manager-quickstart.md" -ForegroundColor Gray

# Retourner un résultat
return @{
    Success = $directoriesSuccess -and $roadmapSuccess -and $configSuccess -and $scheduledTasksSuccess
    Directories = @{ Success = $directoriesSuccess; Details = "$($directories.Count) répertoires vérifiés" }
    Roadmap = @{ Success = $roadmapSuccess; Details = $roadmapDetails }
    Config = @{ Success = $configSuccess; Details = $configDetails }
    ScheduledTasks = @{ Success = $scheduledTasksSuccess; Details = $scheduledTasksDetails }
}
