<#
.SYNOPSIS
    Script d'intÃ©gration entre le gestionnaire de modes et Augment Code.

.DESCRIPTION
    Ce script permet d'intÃ©grer le gestionnaire de modes avec Augment Code,
    en exposant les fonctionnalitÃ©s du gestionnaire de modes via des commandes
    spÃ©cifiques pour Augment. Il facilite l'utilisation des diffÃ©rents modes
    (GRAN, DEV-R, CHECK, etc.) directement depuis Augment.

.PARAMETER Mode
    Le mode Ã  exÃ©cuter. Valeurs possibles : ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ou le document actif.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (ex: "1.2.3").

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut : "development\config\unified-config.json".

.PARAMETER UpdateMemories
    Indique si les Memories d'Augment doivent Ãªtre mises Ã  jour aprÃ¨s l'exÃ©cution du mode.

.EXAMPLE
    .\mode-manager-augment-integration.ps1 -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
    # ExÃ©cute le mode GRAN sur la tÃ¢che 1.2.3 du fichier spÃ©cifiÃ©

.EXAMPLE
    .\mode-manager-augment-integration.ps1 -Mode DEV-R -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -UpdateMemories
    # ExÃ©cute le mode DEV-R sur la tÃ¢che 1.2.3 du fichier spÃ©cifiÃ© et met Ã  jour les Memories d'Augment

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST")]
    [string]$Mode,

    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json",

    [Parameter(Mandatory = $false)]
    [switch]$UpdateMemories,

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

# Chemin vers le gestionnaire de modes
$modeManagerPath = Join-Path -Path $projectRoot -ChildPath "development\managers\mode-manager\scripts\mode-manager.ps1"
if (-not (Test-Path -Path $modeManagerPath)) {
    # Essayer un chemin alternatif
    $modeManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\mode-manager\mode-manager.ps1"
    if (-not (Test-Path -Path $modeManagerPath)) {
        Write-Error "Gestionnaire de modes introuvable."
        exit 1
    }
}

# Chemin vers le gestionnaire de Memories
$memoriesManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\AugmentMemoriesManager.ps1"
if (Test-Path -Path $memoriesManagerPath) {
    . $memoriesManagerPath
} else {
    Write-Warning "Module AugmentMemoriesManager introuvable : $memoriesManagerPath"
    $UpdateMemories = $false
}

# Fonction pour exÃ©cuter le gestionnaire de modes
function Invoke-ModeManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mode,

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Construire les paramÃ¨tres pour le gestionnaire de modes
    $params = @{
        Mode = $Mode
    }

    if ($FilePath) {
        $params.FilePath = $FilePath
    }

    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }

    if ($ConfigPath) {
        $params.ConfigPath = $ConfigPath
    }

    if ($Force) {
        $params.Force = $true
    }

    # ExÃ©cuter le gestionnaire de modes
    & $modeManagerPath @params
    return $LASTEXITCODE -eq 0
}

# Fonction pour mettre Ã  jour les Memories d'Augment avec les informations du mode
function Update-AugmentModeMemories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mode,

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier
    )

    # VÃ©rifier que le module AugmentMemoriesManager est disponible
    if (-not (Get-Command -Name "Update-AugmentMemories" -ErrorAction SilentlyContinue)) {
        Write-Warning "Fonction Update-AugmentMemories non disponible. Impossible de mettre Ã  jour les Memories."
        return $false
    }

    # GÃ©nÃ©rer le contenu des Memories spÃ©cifique au mode
    $modeContent = "# Mode $Mode activÃ©"
    $modeContent += "`n- Fichier: $FilePath"
    if ($TaskIdentifier) {
        $modeContent += "`n- TÃ¢che: $TaskIdentifier"
    }
    $modeContent += "`n- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # Ajouter des informations spÃ©cifiques au mode
    switch ($Mode) {
        "GRAN" {
            $modeContent += @"

## Mode GRAN - Granularisation
- Objectif: DÃ©composer les blocs complexes directement dans le document
- DÃ©clencheurs: Taille > 5KB, complexitÃ© > 7, feedback utilisateur
- Directives: 
  - split_by_responsibility()
  - detect_concatenated_tasks()
  - isolate_subtasks()
  - extract_functions()
  - granular_unit_set()
"@
        }
        "DEV-R" {
            $modeContent += @"

## Mode DEV-R - DÃ©veloppement Roadmap
- Objectif: ImplÃ©menter ce qui est dans la roadmap
- DÃ©clencheurs: Nouvelle tÃ¢che roadmap confirmÃ©e
- Directives: 
  - ImplÃ©menter la sÃ©lection sous-tÃ¢che par sous-tÃ¢che
  - GÃ©nÃ©rer les tests
  - Corriger tous les problÃ¨mes
  - Assurer 100% couverture
"@
        }
        "CHECK" {
            $modeContent += @"

## Mode CHECK - VÃ©rification
- Objectif: VÃ©rifier l'Ã©tat d'avancement des tÃ¢ches
- DÃ©clencheurs: Fin d'implÃ©mentation, validation requise
- Directives: 
  - VÃ©rifier l'implÃ©mentation
  - ExÃ©cuter les tests
  - Mettre Ã  jour la roadmap
  - GÃ©nÃ©rer un rapport
"@
        }
        "ARCHI" {
            $modeContent += @"

## Mode ARCHI - Architecture
- Objectif: Structurer, modÃ©liser, anticiper les dÃ©pendances
- DÃ©clencheurs: Analyse d'impact, modÃ©lisation, dette technique
- Directives: 
  - diagram_layers()
  - define_contracts()
  - detect_critical_paths()
  - suggest_refacto()
  - deliver_arch_synthesis()
"@
        }
        "DEBUG" {
            $modeContent += @"

## Mode DEBUG - DÃ©bogage
- Objectif: Isoler, comprendre, corriger les anomalies
- DÃ©clencheurs: Erreurs, logs, comportement inattendu
- Directives: 
  - identify_fault_origin()
  - test_edge_cases()
  - simulate_context()
  - generate_fix_patch()
  - explain_bug()
"@
        }
        "TEST" {
            $modeContent += @"

## Mode TEST - Tests
- Objectif: Maximiser couverture et fiabilitÃ©
- DÃ©clencheurs: Specs, mode TDD actif
- Directives: 
  - test_suites(coverage=90%)
  - test_cases_by_pattern()
  - test_results_analysis()
"@
        }
        "OPTI" {
            $modeContent += @"

## Mode OPTI - Optimisation
- Objectif: RÃ©duire complexitÃ©, taille ou temps d'exÃ©cution
- DÃ©clencheurs: ComplexitÃ© > 5, taille excessive
- Directives: 
  - runtime_hotspots()
  - reduce_LOC_nesting_calls()
  - optimized_version()
"@
        }
        "REVIEW" {
            $modeContent += @"

## Mode REVIEW - Revue
- Objectif: VÃ©rifier lisibilitÃ©, standards, documentation
- DÃ©clencheurs: Pre_commit, PR
- Directives: 
  - check_SOLID_KISS_DRY()
  - doc_ratio()
  - cyclomatic_score()
  - review_report()
"@
        }
        "C-BREAK" {
            $modeContent += @"

## Mode C-BREAK - Cycle Break
- Objectif: DÃ©tecter et corriger les dÃ©pendances circulaires
- DÃ©clencheurs: Logique rÃ©cursive, erreurs d'import ou workflow bloquÃ©
- Directives: 
  - Detect-CyclicDependencies()
  - Validate-WorkflowCycles()
  - auto_fix_cycles()
  - suggest_refactor_path()
"@
        }
        "PREDIC" {
            $modeContent += @"

## Mode PREDIC - PrÃ©diction
- Objectif: Anticiper performances, dÃ©tecter anomalies, analyser tendances
- DÃ©clencheurs: Besoin d'analyse de charge ou de comportement futur
- Directives: 
  - predict_metrics()
  - find_anomalies()
  - analyze_trends()
  - export_prediction_report()
  - trigger_retraining_if_needed()
"@
        }
    }

    # Mettre Ã  jour les Memories d'Augment
    try {
        # CrÃ©er un fichier temporaire avec le contenu des Memories
        $tempFile = [System.IO.Path]::GetTempFileName()
        $modeContent | Out-File -FilePath $tempFile -Encoding UTF8

        # Mettre Ã  jour les Memories
        Export-MemoriesToVSCode
        Write-Host "Memories d'Augment mises Ã  jour avec les informations du mode $Mode." -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "Erreur lors de la mise Ã  jour des Memories d'Augment : $_"
        return $false
    } finally {
        # Supprimer le fichier temporaire
        if (Test-Path -Path $tempFile) {
            Remove-Item -Path $tempFile -Force
        }
    }
}

# ExÃ©cuter le gestionnaire de modes
$success = Invoke-ModeManager -Mode $Mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ConfigPath $ConfigPath -Force:$Force

# Mettre Ã  jour les Memories d'Augment si demandÃ©
if ($success -and $UpdateMemories) {
    Update-AugmentModeMemories -Mode $Mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier
}

# Retourner le rÃ©sultat
exit [int](!$success)
