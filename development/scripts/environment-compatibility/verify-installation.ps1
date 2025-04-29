<#
.SYNOPSIS
    Script de vÃ©rification de l'installation du gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script vÃ©rifie que tous les composants nÃ©cessaires au fonctionnement du gestionnaire intÃ©grÃ©
    sont correctement installÃ©s et configurÃ©s.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json"

.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution.

.EXAMPLE
    .\verify-installation.ps1

.EXAMPLE
    .\verify-installation.ps1 -ConfigPath "my-config.json" -Verbose

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json"
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
Write-Host "VÃ©rification de l'installation du gestionnaire intÃ©grÃ©" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# VÃ©rifier que PowerShell est correctement installÃ©
$psVersion = $PSVersionTable.PSVersion
$psSuccess = $psVersion.Major -ge 5
Write-Result -Component "PowerShell" -Success $psSuccess -Details "Version $($psVersion.ToString())"

# VÃ©rifier que le module Pester est installÃ©
$pesterSuccess = $false
try {
    $pesterModule = Get-Module -Name Pester -ListAvailable
    $pesterSuccess = $null -ne $pesterModule
    $pesterDetails = if ($pesterSuccess) { "Version $($pesterModule[0].Version.ToString())" } else { "Non installÃ©" }
} catch {
    $pesterDetails = "Erreur lors de la vÃ©rification : $_"
}
Write-Result -Component "Module Pester" -Success $pesterSuccess -Details $pesterDetails

# VÃ©rifier que le fichier de configuration existe
$configSuccess = Test-Path -Path $ConfigPath
$configDetails = if ($configSuccess) { $ConfigPath } else { "Fichier introuvable : $ConfigPath" }
Write-Result -Component "Fichier de configuration" -Success $configSuccess -Details $configDetails

# VÃ©rifier que le fichier de configuration est valide
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

# VÃ©rifier que le gestionnaire intÃ©grÃ© existe
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1"
$integratedManagerSuccess = Test-Path -Path $integratedManagerPath
$integratedManagerDetails = if ($integratedManagerSuccess) { $integratedManagerPath } else { "Fichier introuvable : $integratedManagerPath" }
Write-Result -Component "Gestionnaire intÃ©grÃ©" -Success $integratedManagerSuccess -Details $integratedManagerDetails

# VÃ©rifier que les modes existent
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
    
    $modeStatus = if ($modeSuccess) { "OK" } else { "Ã‰CHEC" }
    $modeColor = if ($modeSuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$modeStatus] " -ForegroundColor $modeColor -NoNewline
    Write-Host "Mode $($mode.Name)" -NoNewline
    
    if (-not $modeSuccess) {
        Write-Host " - Fichier introuvable : $modePath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Modes" -Success $modesSuccess -Details "$($modes.Count) modes vÃ©rifiÃ©s"

# VÃ©rifier que les workflows existent
$workflows = @(
    @{ Name = "Quotidien"; Path = "development\scripts\workflows\workflow-quotidien.ps1" },
    @{ Name = "Hebdomadaire"; Path = "development\scripts\workflows\workflow-hebdomadaire.ps1" },
    @{ Name = "Mensuel"; Path = "development\scripts\workflows\workflow-mensuel.ps1" },
    @{ Name = "Installation des tÃ¢ches planifiÃ©es"; Path = "development\scripts\workflows\install-scheduled-tasks.ps1" }
)

$workflowsSuccess = $true
$workflowsDetails = ""

foreach ($workflow in $workflows) {
    $workflowPath = Join-Path -Path $projectRoot -ChildPath $workflow.Path
    $workflowSuccess = Test-Path -Path $workflowPath
    $workflowsSuccess = $workflowsSuccess -and $workflowSuccess
    
    $workflowStatus = if ($workflowSuccess) { "OK" } else { "Ã‰CHEC" }
    $workflowColor = if ($workflowSuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$workflowStatus] " -ForegroundColor $workflowColor -NoNewline
    Write-Host "Workflow $($workflow.Name)" -NoNewline
    
    if (-not $workflowSuccess) {
        Write-Host " - Fichier introuvable : $workflowPath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Workflows" -Success $workflowsSuccess -Details "$($workflows.Count) workflows vÃ©rifiÃ©s"

# VÃ©rifier que la documentation existe
$docs = @(
    @{ Name = "Guide d'utilisation"; Path = "development\docs\guides\user-guides\integrated-manager-guide.md" },
    @{ Name = "Guide de dÃ©marrage rapide"; Path = "development\docs\guides\user-guides\integrated-manager-quickstart.md" },
    @{ Name = "RÃ©fÃ©rence des paramÃ¨tres"; Path = "development\docs\guides\reference\integrated-manager-parameters.md" },
    @{ Name = "Exemples d'utilisation"; Path = "development\docs\guides\examples\roadmap-modes-examples.md" },
    @{ Name = "Bonnes pratiques"; Path = "development\docs\guides\best-practices\roadmap-management.md" },
    @{ Name = "Workflows automatisÃ©s"; Path = "development\docs\guides\automation\roadmap-workflows.md" }
)

$docsSuccess = $true
$docsDetails = ""

foreach ($doc in $docs) {
    $docPath = Join-Path -Path $projectRoot -ChildPath $doc.Path
    $docSuccess = Test-Path -Path $docPath
    $docsSuccess = $docsSuccess -and $docSuccess
    
    $docStatus = if ($docSuccess) { "OK" } else { "Ã‰CHEC" }
    $docColor = if ($docSuccess) { "Green" } else { "Red" }
    
    Write-Host "  [$docStatus] " -ForegroundColor $docColor -NoNewline
    Write-Host "Documentation $($doc.Name)" -NoNewline
    
    if (-not $docSuccess) {
        Write-Host " - Fichier introuvable : $docPath"
    } else {
        Write-Host ""
    }
}

Write-Result -Component "Documentation" -Success $docsSuccess -Details "$($docs.Count) documents vÃ©rifiÃ©s"

# VÃ©rifier que les rÃ©pertoires nÃ©cessaires existent
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
            New-Item -Path $directoryPath -ItemType Directory -Force | Out-Null
            $directorySuccess = $true
            $directoryDetails = "RÃ©pertoire crÃ©Ã©"
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

# VÃ©rifier que les tÃ¢ches planifiÃ©es sont installÃ©es
$scheduledTasksSuccess = $false
$scheduledTasksDetails = ""

try {
    $tasks = Get-ScheduledTask -TaskName "roadmap-manager-*" -ErrorAction SilentlyContinue
    $scheduledTasksSuccess = $null -ne $tasks -and $tasks.Count -gt 0
    $scheduledTasksDetails = if ($scheduledTasksSuccess) { "$($tasks.Count) tÃ¢ches planifiÃ©es trouvÃ©es" } else { "Aucune tÃ¢che planifiÃ©e trouvÃ©e" }
} catch {
    $scheduledTasksDetails = "Erreur lors de la vÃ©rification : $_"
}

Write-Result -Component "TÃ¢ches planifiÃ©es" -Success $scheduledTasksSuccess -Details $scheduledTasksDetails

# Afficher le rÃ©sumÃ©
Write-Host ""
Write-Host "RÃ©sumÃ© de la vÃ©rification" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

$totalSuccess = $psSuccess -and $pesterSuccess -and $configSuccess -and $configValidSuccess -and $integratedManagerSuccess -and $modesSuccess -and $workflowsSuccess -and $docsSuccess -and $directoriesSuccess
$totalStatus = if ($totalSuccess) { "SUCCÃˆS" } else { "Ã‰CHEC" }
$totalColor = if ($totalSuccess) { "Green" } else { "Red" }

Write-Host "RÃ©sultat global : " -NoNewline
Write-Host "[$totalStatus]" -ForegroundColor $totalColor

if (-not $totalSuccess) {
    Write-Host ""
    Write-Host "Actions recommandÃ©es :" -ForegroundColor Yellow
    
    if (-not $psSuccess) {
        Write-Host "- Mettre Ã  jour PowerShell vers la version 5.1 ou supÃ©rieure"
    }
    
    if (-not $pesterSuccess) {
        Write-Host "- Installer le module Pester : Install-Module -Name Pester -Force -SkipPublisherCheck"
    }
    
    if (-not $configSuccess) {
        Write-Host "- CrÃ©er le fichier de configuration : $ConfigPath"
    } elseif (-not $configValidSuccess) {
        Write-Host "- Corriger le format du fichier de configuration : $ConfigPath"
    }
    
    if (-not $integratedManagerSuccess) {
        Write-Host "- CrÃ©er le gestionnaire intÃ©grÃ© : $integratedManagerPath"
    }
    
    if (-not $modesSuccess) {
        Write-Host "- CrÃ©er les modes manquants dans le rÃ©pertoire development\scripts\maintenance\modes\"
    }
    
    if (-not $workflowsSuccess) {
        Write-Host "- CrÃ©er les workflows manquants dans le rÃ©pertoire development\scripts\workflows\"
    }
    
    if (-not $docsSuccess) {
        Write-Host "- CrÃ©er la documentation manquante dans le rÃ©pertoire development\docs\guides\"
    }
    
    if (-not $scheduledTasksSuccess) {
        Write-Host "- Installer les tÃ¢ches planifiÃ©es : .\development\scripts\workflows\install-scheduled-tasks.ps1"
    }
} else {
    Write-Host ""
    Write-Host "Toutes les vÃ©rifications ont rÃ©ussi. Le gestionnaire intÃ©grÃ© est correctement installÃ© et configurÃ©." -ForegroundColor Green
}

# Retourner un rÃ©sultat
return @{
    Success = $totalSuccess
    PowerShell = @{ Success = $psSuccess; Details = $psVersion.ToString() }
    Pester = @{ Success = $pesterSuccess; Details = $pesterDetails }
    Config = @{ Success = $configSuccess -and $configValidSuccess; Details = $ConfigPath }
    IntegratedManager = @{ Success = $integratedManagerSuccess; Details = $integratedManagerPath }
    Modes = @{ Success = $modesSuccess; Details = "$($modes.Count) modes vÃ©rifiÃ©s" }
    Workflows = @{ Success = $workflowsSuccess; Details = "$($workflows.Count) workflows vÃ©rifiÃ©s" }
    Documentation = @{ Success = $docsSuccess; Details = "$($docs.Count) documents vÃ©rifiÃ©s" }
    Directories = @{ Success = $directoriesSuccess; Details = "$($directories.Count) rÃ©pertoires vÃ©rifiÃ©s" }
    ScheduledTasks = @{ Success = $scheduledTasksSuccess; Details = $scheduledTasksDetails }
}


