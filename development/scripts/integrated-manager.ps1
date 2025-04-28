<#
.SYNOPSIS
    Script d'intégration entre le mode manager et le roadmap manager.

.DESCRIPTION
    Ce script permet d'intégrer les fonctionnalités du mode manager et du roadmap manager
    pour offrir une interface unifiée pour la gestion des roadmaps et des modes opérationnels.

.PARAMETER Mode
    Le mode à exécuter. Valeurs possibles : ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, ROADMAP-PLAN, ROADMAP-REPORT, ROADMAP-SYNC, TEST.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à traiter (ex: "1.2.3").

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut, utilise le fichier de configuration unifié.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.

.PARAMETER ListModes
    Affiche la liste des modes disponibles et leurs descriptions.

.PARAMETER ListRoadmaps
    Affiche la liste des roadmaps disponibles.

.PARAMETER Analyze
    Analyse la roadmap et génère des rapports.

.PARAMETER GitUpdate
    Met à jour la roadmap en fonction des commits Git.

.PARAMETER Workflow
    Nom du workflow à exécuter. Les workflows sont définis dans le fichier de configuration.

.EXAMPLE
    .\integrated-manager.ps1 -Mode CHECK -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force
    Exécute le mode CHECK sur la tâche 1.2.3 du fichier spécifié avec l'option Force.

.EXAMPLE
    .\integrated-manager.ps1 -Workflow "Development" -RoadmapPath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
    Exécute le workflow de développement sur la tâche 1.2.3 du fichier spécifié.
#>

[CmdletBinding(DefaultParameterSetName = "Execute")]
param (
    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [ValidateSet("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "ROADMAP-PLAN", "ROADMAP-REPORT", "ROADMAP-SYNC", "TEST")]
    [string]$Mode,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [Parameter(Mandatory = $false, ParameterSetName = "Roadmap")]
    [Parameter(Mandatory = $false, ParameterSetName = "Workflow")]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [Parameter(Mandatory = $false, ParameterSetName = "Roadmap")]
    [Parameter(Mandatory = $false, ParameterSetName = "Workflow")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [Parameter(Mandatory = $false, ParameterSetName = "Roadmap")]
    [Parameter(Mandatory = $false, ParameterSetName = "Workflow")]
    [Parameter(Mandatory = $false, ParameterSetName = "List")]
    [string]$ConfigPath = "development\config\unified-config.json",

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [Parameter(Mandatory = $false, ParameterSetName = "Roadmap")]
    [Parameter(Mandatory = $false, ParameterSetName = "Workflow")]
    [switch]$Force,

    [Parameter(Mandatory = $true, ParameterSetName = "ListModes")]
    [switch]$ListModes,

    [Parameter(Mandatory = $true, ParameterSetName = "ListWorkflows")]
    [switch]$ListWorkflows,

    [Parameter(Mandatory = $true, ParameterSetName = "ListRoadmaps")]
    [switch]$ListRoadmaps,

    [Parameter(Mandatory = $true, ParameterSetName = "Roadmap")]
    [switch]$Analyze,

    [Parameter(Mandatory = $true, ParameterSetName = "Roadmap")]
    [switch]$GitUpdate,

    [Parameter(Mandatory = $true, ParameterSetName = "Workflow")]
    [string]$Workflow,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [Parameter(Mandatory = $false, ParameterSetName = "Roadmap")]
    [Parameter(Mandatory = $false, ParameterSetName = "Workflow")]
    [Parameter(Mandatory = $false, ParameterSetName = "List")]
    [switch]$Interactive
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

# Chemins des scripts
$modeManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$roadmapManagerPath = Join-Path -Path $projectRoot -ChildPath "projet\roadmaps\scripts\RoadmapManager.ps1"
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath

# Vérifier que les scripts existent
if (-not (Test-Path -Path $modeManagerPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable à l'emplacement : $modeManagerPath"
    exit 1
}

if (-not (Test-Path -Path $roadmapManagerPath)) {
    Write-Error "Le script RoadmapManager.ps1 est introuvable à l'emplacement : $roadmapManagerPath"
    exit 1
}

# Fonction pour charger la configuration unifiée
function Get-UnifiedConfiguration {
    param (
        [string]$ConfigPath
    )

    if (Test-Path -Path $ConfigPath) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration : $_"
        }
    } else {
        Write-Warning "Fichier de configuration introuvable : $ConfigPath"
    }

    # Configuration par défaut
    return [PSCustomObject]@{
        General        = [PSCustomObject]@{
            RoadmapPath        = "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath         = "reports"
            LogPath            = "logs"
            DefaultLanguage    = "fr-FR"
            DefaultEncoding    = "UTF8-BOM"
            ProjectRoot        = $projectRoot
        }
        Modes          = [PSCustomObject]@{
            # Configuration des modes...
        }
        Roadmaps       = [PSCustomObject]@{
            # Configuration des roadmaps...
        }
        RoadmapManager = [PSCustomObject]@{
            DefaultRoadmapPath = "projet\roadmaps\Roadmap\roadmap_perso.md"
            ReportsFolder      = "projet\roadmaps\Reports"
            GitRepo            = "."
            DaysToAnalyze      = 7
            AutoUpdate         = $true
            GenerateReport     = $true
            JournalPath        = "projet\roadmaps\journal"
            LogFile            = "projet\roadmaps\logs\RoadmapManager.log"
            BackupFolder       = "projet\roadmaps\backup"
            Scripts            = [PSCustomObject]@{
                Manager    = "projet\roadmaps\scripts\RoadmapManager.ps1"
                Analyzer   = "projet\roadmaps\scripts\RoadmapAnalyzer.ps1"
                GitUpdater = "projet\roadmaps\scripts\RoadmapGitUpdater.ps1"
                Cleanup    = "projet\roadmaps\scripts\CleanupRoadmapFiles.ps1"
                Organize   = "projet\roadmaps\scripts\OrganizeRoadmapScripts.ps1"
                Execute    = "projet\roadmaps\scripts\StartRoadmapExecution.ps1"
                Sync       = "projet\roadmaps\scripts\Sync-RoadmapWithJournal.ps1"
            }
        }
        Workflows      = [PSCustomObject]@{
            Development  = [PSCustomObject]@{
                Description  = "Workflow de développement complet"
                Modes        = @("GRAN", "DEV-R", "TEST", "CHECK")
                AutoContinue = $true
                StopOnError  = $true
            }
            Optimization = [PSCustomObject]@{
                Description  = "Workflow d'optimisation"
                Modes        = @("REVIEW", "OPTI", "TEST", "CHECK")
                AutoContinue = $true
                StopOnError  = $true
            }
            Debugging    = [PSCustomObject]@{
                Description  = "Workflow de débogage"
                Modes        = @("DEBUG", "TEST", "CHECK")
                AutoContinue = $true
                StopOnError  = $true
            }
        }
        Integration    = [PSCustomObject]@{
            EnabledByDefault   = $true
            DefaultWorkflow    = "Development"
            DefaultRoadmap     = "Main"
            AutoSaveResults    = $true
            ResultsPath        = "reports\integration"
            LogLevel           = "Info"
            NotifyOnCompletion = $true
            MaxConcurrentTasks = 4
        }
    }
}

# Charger la configuration unifiée
$config = Get-UnifiedConfiguration -ConfigPath $configPath

# Fonction pour exécuter un mode
function Invoke-IntegratedMode {
    param (
        [string]$Mode,
        [string]$RoadmapPath,
        [string]$TaskIdentifier,
        [switch]$Force
    )

    Write-Host "Exécution du mode $Mode sur la roadmap $RoadmapPath (tâche $TaskIdentifier)..." -ForegroundColor Cyan

    # Exécuter le mode via le mode manager
    & $modeManagerPath -Mode $Mode -FilePath $RoadmapPath -TaskIdentifier $TaskIdentifier -ConfigPath $configPath -Force:$Force

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erreur lors de l'exécution du mode $Mode."
        return $false
    }

    return $true
}

# Fonction pour exécuter un workflow
function Invoke-IntegratedWorkflow {
    param (
        [string]$WorkflowName,
        [string]$RoadmapPath,
        [string]$TaskIdentifier,
        [switch]$Force
    )

    Write-Host "Exécution du workflow $WorkflowName sur la roadmap $RoadmapPath (tâche $TaskIdentifier)..." -ForegroundColor Cyan

    # Vérifier que le workflow existe
    if (-not $config.Workflows.$WorkflowName) {
        Write-Error "Le workflow $WorkflowName n'existe pas dans la configuration."
        return $false
    }

    # Récupérer les modes du workflow
    $modes = $config.Workflows.$WorkflowName.Modes

    # Exécuter chaque mode du workflow
    foreach ($mode in $modes) {
        $success = Invoke-IntegratedMode -Mode $mode -RoadmapPath $RoadmapPath -TaskIdentifier $TaskIdentifier -Force:$Force

        if (-not $success) {
            Write-Error "Erreur lors de l'exécution du mode $mode dans le workflow $WorkflowName."

            if ($config.Workflows.$WorkflowName.StopOnError) {
                return $false
            }
        }

        if (-not $config.Workflows.$WorkflowName.AutoContinue) {
            $continue = Read-Host "Continuer avec le mode suivant ? (O/N)"
            if ($continue -ne "O" -and $continue -ne "o") {
                Write-Host "Workflow interrompu par l'utilisateur." -ForegroundColor Yellow
                return $false
            }
        }
    }

    return $true
}

# Fonction pour analyser une roadmap
function Invoke-RoadmapAnalysis {
    param (
        [string]$RoadmapPath
    )

    Write-Host "Analyse de la roadmap $RoadmapPath..." -ForegroundColor Cyan

    # Exécuter l'analyse via le roadmap manager
    $analyzerPath = Join-Path -Path $projectRoot -ChildPath $config.RoadmapManager.Scripts.Analyzer

    if (-not (Test-Path -Path $analyzerPath)) {
        Write-Error "Le script d'analyse est introuvable à l'emplacement : $analyzerPath"
        return $false
    }

    & $analyzerPath -RoadmapPath $RoadmapPath -GenerateHtml -GenerateJson -GenerateChart

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erreur lors de l'analyse de la roadmap $RoadmapPath."
        return $false
    }

    return $true
}

# Fonction pour mettre à jour une roadmap avec Git
function Invoke-RoadmapGitUpdate {
    param (
        [string]$RoadmapPath
    )

    Write-Host "Mise à jour de la roadmap $RoadmapPath avec Git..." -ForegroundColor Cyan

    # Exécuter la mise à jour via le roadmap manager
    $gitUpdaterPath = Join-Path -Path $projectRoot -ChildPath $config.RoadmapManager.Scripts.GitUpdater

    if (-not (Test-Path -Path $gitUpdaterPath)) {
        Write-Error "Le script de mise à jour Git est introuvable à l'emplacement : $gitUpdaterPath"
        return $false
    }

    & $gitUpdaterPath -RoadmapPath $RoadmapPath -AutoUpdate -GenerateReport

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erreur lors de la mise à jour de la roadmap $RoadmapPath avec Git."
        return $false
    }

    return $true
}

# Fonction pour afficher la liste des modes
function Show-AvailableModes {
    Write-Host "Affichage de la liste des modes disponibles..." -ForegroundColor Cyan

    # Afficher la liste des modes via le mode manager
    & $modeManagerPath -ListModes
}

# Fonction pour afficher la liste des roadmaps
function Show-AvailableRoadmaps {
    Write-Host "Affichage de la liste des roadmaps disponibles..." -ForegroundColor Cyan

    # Récupérer la liste des roadmaps depuis la configuration
    Write-Host "Roadmaps disponibles :" -ForegroundColor Yellow

    foreach ($roadmap in $config.Roadmaps.PSObject.Properties) {
        $roadmapPath = Join-Path -Path $projectRoot -ChildPath $roadmap.Value.Path
        $exists = Test-Path -Path $roadmapPath
        $status = if ($exists) { "Existe" } else { "N'existe pas" }
        $color = if ($exists) { "Green" } else { "Red" }

        Write-Host "  - $($roadmap.Name): $($roadmap.Value.Description)" -ForegroundColor Gray
        Write-Host "    Chemin: $($roadmap.Value.Path) [$status]" -ForegroundColor $color
    }

    # Rechercher également d'autres roadmaps dans le projet
    $roadmapFiles = Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath "projet\roadmaps") -Recurse -Filter "*.md" | Where-Object { $_.Name -like "*roadmap*" }

    if ($roadmapFiles.Count -gt 0) {
        Write-Host "`nAutres roadmaps trouvées :" -ForegroundColor Yellow
        foreach ($roadmap in $roadmapFiles) {
            $relativePath = $roadmap.FullName.Replace($projectRoot + "\", "")
            Write-Host "  - $relativePath" -ForegroundColor Gray
        }
    }
}

# Fonction pour afficher le menu interactif
function Show-InteractiveMenu {
    Clear-Host
    Write-Host "Gestionnaire intégré" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Exécuter un mode"
    Write-Host "2. Exécuter un workflow"
    Write-Host "3. Analyser une roadmap"
    Write-Host "4. Mettre à jour une roadmap avec Git"
    Write-Host "5. Afficher la liste des modes"
    Write-Host "6. Afficher la liste des roadmaps"
    Write-Host "7. Quitter"
    Write-Host ""
    Write-Host "Sélectionnez une option (1-7) : " -NoNewline

    $choice = Read-Host

    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host "Exécuter un mode" -ForegroundColor Cyan
            Write-Host "================" -ForegroundColor Cyan
            Write-Host ""

            # Afficher la liste des modes
            $modes = @("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "ROADMAP-PLAN", "ROADMAP-REPORT", "ROADMAP-SYNC", "TEST")
            for ($i = 0; $i -lt $modes.Count; $i++) {
                Write-Host "$($i+1). $($modes[$i])"
            }

            Write-Host ""
            Write-Host "Sélectionnez un mode (1-$($modes.Count)) : " -NoNewline
            $modeChoice = Read-Host

            if ($modeChoice -match '^\d+$' -and [int]$modeChoice -ge 1 -and [int]$modeChoice -le $modes.Count) {
                $selectedMode = $modes[[int]$modeChoice - 1]

                Write-Host ""
                Write-Host "Chemin de la roadmap : " -NoNewline
                $roadmapPath = Read-Host

                Write-Host "Identifiant de la tâche : " -NoNewline
                $taskId = Read-Host

                Write-Host "Forcer l'exécution ? (O/N) : " -NoNewline
                $forceChoice = Read-Host
                $forceExecution = $forceChoice -eq "O" -or $forceChoice -eq "o"

                Invoke-IntegratedMode -Mode $selectedMode -RoadmapPath $roadmapPath -TaskIdentifier $taskId -Force:$forceExecution
            } else {
                Write-Host "Choix invalide." -ForegroundColor Red
            }

            return $true
        }
        "2" {
            Clear-Host
            Write-Host "Exécuter un workflow" -ForegroundColor Cyan
            Write-Host "===================" -ForegroundColor Cyan
            Write-Host ""

            # Afficher la liste des workflows
            $workflows = $config.Workflows.PSObject.Properties.Name
            for ($i = 0; $i -lt $workflows.Count; $i++) {
                Write-Host "$($i+1). $($workflows[$i]) - $($config.Workflows.$($workflows[$i]).Description)"
            }

            Write-Host ""
            Write-Host "Sélectionnez un workflow (1-$($workflows.Count)) : " -NoNewline
            $workflowChoice = Read-Host

            if ($workflowChoice -match '^\d+$' -and [int]$workflowChoice -ge 1 -and [int]$workflowChoice -le $workflows.Count) {
                $selectedWorkflow = $workflows[[int]$workflowChoice - 1]

                Write-Host ""
                Write-Host "Chemin de la roadmap : " -NoNewline
                $roadmapPath = Read-Host

                Write-Host "Identifiant de la tâche : " -NoNewline
                $taskId = Read-Host

                Write-Host "Forcer l'exécution ? (O/N) : " -NoNewline
                $forceChoice = Read-Host
                $forceExecution = $forceChoice -eq "O" -or $forceChoice -eq "o"

                Invoke-IntegratedWorkflow -WorkflowName $selectedWorkflow -RoadmapPath $roadmapPath -TaskIdentifier $taskId -Force:$forceExecution
            } else {
                Write-Host "Choix invalide." -ForegroundColor Red
            }

            return $true
        }
        "3" {
            Clear-Host
            Write-Host "Analyser une roadmap" -ForegroundColor Cyan
            Write-Host "===================" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "Chemin de la roadmap : " -NoNewline
            $roadmapPath = Read-Host

            Invoke-RoadmapAnalysis -RoadmapPath $roadmapPath

            return $true
        }
        "4" {
            Clear-Host
            Write-Host "Mettre à jour une roadmap avec Git" -ForegroundColor Cyan
            Write-Host "===============================" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "Chemin de la roadmap : " -NoNewline
            $roadmapPath = Read-Host

            Invoke-RoadmapGitUpdate -RoadmapPath $roadmapPath

            return $true
        }
        "5" {
            Clear-Host
            Show-AvailableModes

            Write-Host ""
            Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            return $true
        }
        "6" {
            Clear-Host
            Show-AvailableRoadmaps

            Write-Host ""
            Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            return $true
        }
        "7" {
            return $false
        }
        default {
            Write-Host "Option invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $true
        }
    }
}

# Exécuter la fonction appropriée en fonction des paramètres
if ($Interactive) {
    $continue = $true
    while ($continue) {
        $continue = Show-InteractiveMenu
    }
} elseif ($ListModes) {
    Show-AvailableModes
} elseif ($ListWorkflows) {
    # Afficher la liste des workflows
    Write-Host "Affichage de la liste des workflows disponibles..." -ForegroundColor Cyan

    Write-Host "Workflows disponibles :" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow

    foreach ($workflow in $config.Workflows.PSObject.Properties) {
        Write-Host "$($workflow.Name): $($workflow.Value.Description)" -ForegroundColor Gray
        Write-Host "  Modes: $($workflow.Value.Modes -join ", ")" -ForegroundColor Gray
        Write-Host "  AutoContinue: $($workflow.Value.AutoContinue)" -ForegroundColor Gray
        Write-Host "  StopOnError: $($workflow.Value.StopOnError)" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "Exemples d'utilisation :" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow
    Write-Host ".\integrated-manager.ps1 -Workflow Development -RoadmapPath `"projet\roadmaps\Roadmap\roadmap_complete_converted.md`" -TaskIdentifier `"1.2.3`"" -ForegroundColor Gray
    Write-Host ".\integrated-manager.ps1 -Workflow RoadmapManagement -RoadmapPath `"projet\roadmaps\Roadmap\roadmap_complete_converted.md`"" -ForegroundColor Gray
} elseif ($ListRoadmaps) {
    Show-AvailableRoadmaps
} elseif ($Analyze) {
    if (-not $RoadmapPath) {
        $RoadmapPath = $config.General.RoadmapPath
    }
    Invoke-RoadmapAnalysis -RoadmapPath $RoadmapPath
} elseif ($GitUpdate) {
    if (-not $RoadmapPath) {
        $RoadmapPath = $config.General.RoadmapPath
    }
    Invoke-RoadmapGitUpdate -RoadmapPath $RoadmapPath
} elseif ($Workflow) {
    if (-not $RoadmapPath) {
        $RoadmapPath = $config.General.RoadmapPath
    }
    Invoke-IntegratedWorkflow -WorkflowName $Workflow -RoadmapPath $RoadmapPath -TaskIdentifier $TaskIdentifier -Force:$Force
} elseif ($Mode) {
    if (-not $RoadmapPath) {
        $RoadmapPath = $config.General.RoadmapPath
    }
    Invoke-IntegratedMode -Mode $Mode -RoadmapPath $RoadmapPath -TaskIdentifier $TaskIdentifier -Force:$Force
} else {
    Write-Host "Aucune action spécifiée. Utilisez -Mode, -Workflow, -Analyze, -GitUpdate, -ListModes, -ListRoadmaps ou -Interactive." -ForegroundColor Yellow

    # Afficher l'aide
    Get-Help $MyInvocation.MyCommand.Definition
}
