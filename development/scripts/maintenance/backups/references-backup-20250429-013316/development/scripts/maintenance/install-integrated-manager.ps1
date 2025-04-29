<#
.SYNOPSIS
    Script d'installation rapide du gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script permet d'installer et de configurer rapidement le gestionnaire intÃ©grÃ©.
    Il crÃ©e les rÃ©pertoires nÃ©cessaires, configure les paramÃ¨tres et installe les tÃ¢ches planifiÃ©es.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json"

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap principal.
    Par dÃ©faut : "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

.PARAMETER InstallScheduledTasks
    Indique si les tÃ¢ches planifiÃ©es doivent Ãªtre installÃ©es.
    Par dÃ©faut : $true

.PARAMETER Force
    Indique si les fichiers existants doivent Ãªtre remplacÃ©s.
    Par dÃ©faut : $false

.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution.

.EXAMPLE
    .\install-integrated-manager.ps1

.EXAMPLE
    .\install-integrated-manager.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md" -InstallScheduledTasks $false

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
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

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and 
       -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
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

# Fonction pour afficher les rÃ©sultats
function Write-Result {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Component,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [string]$Details = ""
    )
    
    $status = if ($Success) { "OK" } else { "Ã‰CHEC" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] " -ForegroundColor $color -NoNewline
    Write-Host "$Component" -NoNewline
    
    if ($Details) {
        Write-Host " - $Details"
    } else {
        Write-Host ""
    }
}

# Afficher l'en-tÃªte
Write-Host "Installation rapide du gestionnaire intÃ©grÃ©" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# VÃ©rifier que PowerShell est correctement installÃ©
$psVersion = $PSVersionTable.PSVersion
$psSuccess = $psVersion.Major -ge 5
Write-Result -Component "PowerShell" -Success $psSuccess -Details "Version $($psVersion.ToString())"

if (-not $psSuccess) {
    Write-Error "PowerShell 5.1 ou supÃ©rieur est requis pour installer le gestionnaire intÃ©grÃ©."
    exit 1
}

# Installer le module Pester s'il n'est pas dÃ©jÃ  installÃ©
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
    
    $pesterDetails = if ($pesterSuccess) { "Version $($pesterModule[0].Version.ToString())" } else { "Non installÃ©" }
} catch {
    $pesterDetails = "Erreur lors de l'installation : $_"
}
Write-Result -Component "Module Pester" -Success $pesterSuccess -Details $pesterDetails

# CrÃ©er les rÃ©pertoires nÃ©cessaires
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
        # CrÃ©er le rÃ©pertoire s'il n'existe pas
        try {
            if ($PSCmdlet.ShouldProcess($directoryPath, "CrÃ©er le rÃ©pertoire")) {
                New-Item -Path $directoryPath -ItemType Directory -Force | Out-Null
                $directorySuccess = $true
                $directoryDetails = "RÃ©pertoire crÃ©Ã©"
            } else {
                $directoryDetails = "CrÃ©ation simulÃ©e"
            }
        } catch {
            $directoryDetails = "Erreur lors de la crÃ©ation : $_"
        }
    } else {
        $directoryDetails = "RÃ©pertoire existant"
    }
    
    $directoriesSuccess = $directoriesSuccess -and $directorySuccess
    
    $directoryStatus = if ($directorySuccess) { "OK" } else { "Ã‰CHEC" }
    $directoryColor = if ($directorySuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$directoryStatus] " -ForegroundColor $directoryColor -NoNewline
    Write-Host "RÃ©pertoire $($directory.Name)" -NoNewline
    
    Write-Host " - $directoryDetails"
}

Write-Result -Component "RÃ©pertoires" -Success $directoriesSuccess -Details "$($directories.Count) rÃ©pertoires vÃ©rifiÃ©s"

# CrÃ©er un fichier de roadmap de test si nÃ©cessaire
$roadmapSuccess = Test-Path -Path $RoadmapPath
$roadmapDetails = ""

if (-not $roadmapSuccess) {
    # CrÃ©er le rÃ©pertoire parent s'il n'existe pas
    $roadmapDir = Split-Path -Parent $RoadmapPath
    if (-not (Test-Path -Path $roadmapDir -PathType Container)) {
        try {
            if ($PSCmdlet.ShouldProcess($roadmapDir, "CrÃ©er le rÃ©pertoire")) {
                New-Item -Path $roadmapDir -ItemType Directory -Force | Out-Null
            }
        } catch {
            $roadmapDetails = "Erreur lors de la crÃ©ation du rÃ©pertoire : $_"
            Write-Result -Component "Roadmap" -Success $false -Details $roadmapDetails
        }
    }
    
    # CrÃ©er le fichier de roadmap
    try {
        if ($PSCmdlet.ShouldProcess($RoadmapPath, "CrÃ©er le fichier de roadmap")) {
            $roadmapContent = @"
# Roadmap du projet

## TÃ¢che 1: Initialisation du projet

### Description
Cette tÃ¢che vise Ã  initialiser le projet et Ã  mettre en place les outils nÃ©cessaires.

### Sous-tÃ¢ches
- [ ] **1.1** Configurer l'environnement de dÃ©veloppement
- [ ] **1.2** Installer les dÃ©pendances
- [ ] **1.3** CrÃ©er la structure du projet
- [ ] **1.4** Configurer les outils de gestion de projet
- [ ] **1.5** Documenter le processus d'installation

## TÃ¢che 2: DÃ©veloppement des fonctionnalitÃ©s

### Description
Cette tÃ¢che vise Ã  dÃ©velopper les fonctionnalitÃ©s principales du projet.

### Sous-tÃ¢ches
- [ ] **2.1** DÃ©velopper la fonctionnalitÃ© A
- [ ] **2.2** DÃ©velopper la fonctionnalitÃ© B
- [ ] **2.3** DÃ©velopper la fonctionnalitÃ© C
- [ ] **2.4** Tester les fonctionnalitÃ©s
- [ ] **2.5** Documenter les fonctionnalitÃ©s

## TÃ¢che 3: DÃ©ploiement

### Description
Cette tÃ¢che vise Ã  dÃ©ployer le projet en production.

### Sous-tÃ¢ches
- [ ] **3.1** PrÃ©parer l'environnement de production
- [ ] **3.2** Configurer les serveurs
- [ ] **3.3** DÃ©ployer l'application
- [ ] **3.4** Tester le dÃ©ploiement
- [ ] **3.5** Documenter le processus de dÃ©ploiement
"@
            
            Set-Content -Path $RoadmapPath -Value $roadmapContent -Encoding UTF8
            $roadmapSuccess = $true
            $roadmapDetails = "Fichier crÃ©Ã©"
        } else {
            $roadmapDetails = "CrÃ©ation simulÃ©e"
        }
    } catch {
        $roadmapDetails = "Erreur lors de la crÃ©ation : $_"
    }
} else {
    $roadmapDetails = "Fichier existant"
}

Write-Result -Component "Roadmap" -Success $roadmapSuccess -Details $roadmapDetails

# CrÃ©er ou mettre Ã  jour le fichier de configuration
$configSuccess = $false
$configDetails = ""

try {
    if (Test-Path -Path $ConfigPath) {
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($ConfigPath, "Mettre Ã  jour le fichier de configuration")) {
                $configContent = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
                
                # Mettre Ã  jour les chemins
                $configContent.General.RoadmapPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                $configContent.General.ActiveDocumentPath = $RoadmapPath.Replace($projectRoot + "\", "").Replace("\", "\\")
                
                # Mettre Ã  jour les modes
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
                
                # Mettre Ã  jour les workflows
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
                $configDetails = "Fichier mis Ã  jour"
            } else {
                $configDetails = "Mise Ã  jour simulÃ©e"
            }
        } else {
            $configSuccess = $true
            $configDetails = "Fichier existant (utilisez -Force pour le mettre Ã  jour)"
        }
    } else {
        # CrÃ©er le rÃ©pertoire parent s'il n'existe pas
        $configDir = Split-Path -Parent $ConfigPath
        if (-not (Test-Path -Path $configDir -PathType Container)) {
            try {
                if ($PSCmdlet.ShouldProcess($configDir, "CrÃ©er le rÃ©pertoire")) {
                    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                }
            } catch {
                $configDetails = "Erreur lors de la crÃ©ation du rÃ©pertoire : $_"
                Write-Result -Component "Configuration" -Success $false -Details $configDetails
            }
        }
        
        # CrÃ©er le fichier de configuration
        if ($PSCmdlet.ShouldProcess($ConfigPath, "CrÃ©er le fichier de configuration")) {
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
                        Description = "Workflow de dÃ©veloppement complet"
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
            $configDetails = "Fichier crÃ©Ã©"
        } else {
            $configDetails = "CrÃ©ation simulÃ©e"
        }
    }
} catch {
    $configDetails = "Erreur lors de la crÃ©ation/mise Ã  jour : $_"
}

Write-Result -Component "Configuration" -Success $configSuccess -Details $configDetails

# Installer les tÃ¢ches planifiÃ©es si demandÃ©
$scheduledTasksSuccess = $true
$scheduledTasksDetails = ""

if ($InstallScheduledTasks) {
    $installScheduledTasksPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\install-scheduled-tasks.ps1"
    
    if (Test-Path -Path $installScheduledTasksPath) {
        try {
            if ($PSCmdlet.ShouldProcess("TÃ¢ches planifiÃ©es", "Installer")) {
                Write-Host "Installation des tÃ¢ches planifiÃ©es..." -ForegroundColor Yellow
                
                $params = @{}
                if ($Force) {
                    $params.Add("Force", $true)
                }
                
                & $installScheduledTasksPath @params
                
                $tasks = Get-ScheduledTask -TaskName "roadmap-manager-*" -ErrorAction SilentlyContinue
                $scheduledTasksSuccess = $null -ne $tasks -and $tasks.Count -gt 0
                $scheduledTasksDetails = if ($scheduledTasksSuccess) { "$($tasks.Count) tÃ¢ches planifiÃ©es installÃ©es" } else { "Aucune tÃ¢che planifiÃ©e installÃ©e" }
            } else {
                $scheduledTasksDetails = "Installation simulÃ©e"
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
    $scheduledTasksDetails = "Installation ignorÃ©e (utilisez -InstallScheduledTasks `$true pour installer)"
}

Write-Result -Component "TÃ¢ches planifiÃ©es" -Success $scheduledTasksSuccess -Details $scheduledTasksDetails

# VÃ©rifier l'installation
$verifyInstallationPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\verify-installation.ps1"

if (Test-Path -Path $verifyInstallationPath) {
    try {
        if ($PSCmdlet.ShouldProcess("Installation", "VÃ©rifier")) {
            Write-Host ""
            Write-Host "VÃ©rification de l'installation..." -ForegroundColor Yellow
            
            & $verifyInstallationPath -ConfigPath $ConfigPath
        }
    } catch {
        Write-Error "Erreur lors de la vÃ©rification de l'installation : $_"
    }
} else {
    Write-Warning "Script de vÃ©rification introuvable : $verifyInstallationPath"
}

# Afficher les prochaines Ã©tapes
Write-Host ""
Write-Host "Installation terminÃ©e. Prochaines Ã©tapes :" -ForegroundColor Cyan
Write-Host "1. ExÃ©cuter le gestionnaire intÃ©grÃ© : .\development\scripts\integrated-manager.ps1 -ListModes" -ForegroundColor Gray
Write-Host "2. ExÃ©cuter un workflow : .\development\scripts\integrated-manager.ps1 -Workflow RoadmapManagement -RoadmapPath `"$RoadmapPath`"" -ForegroundColor Gray
Write-Host "3. Consulter la documentation : .\development\docs\guides\user-guides\integrated-manager-quickstart.md" -ForegroundColor Gray

# Retourner un rÃ©sultat
return @{
    Success = $directoriesSuccess -and $roadmapSuccess -and $configSuccess -and $scheduledTasksSuccess
    Directories = @{ Success = $directoriesSuccess; Details = "$($directories.Count) rÃ©pertoires vÃ©rifiÃ©s" }
    Roadmap = @{ Success = $roadmapSuccess; Details = $roadmapDetails }
    Config = @{ Success = $configSuccess; Details = $configDetails }
    ScheduledTasks = @{ Success = $scheduledTasksSuccess; Details = $scheduledTasksDetails }
}

