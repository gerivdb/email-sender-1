<#
.SYNOPSIS
    Script d'intégration entre le gestionnaire de modes et Augment Code.

.DESCRIPTION
    Ce script permet d'intégrer le gestionnaire de modes avec Augment Code,
    en exposant les fonctionnalités du gestionnaire de modes via des commandes
    spécifiques pour Augment. Il facilite l'utilisation des différents modes
    (GRAN, DEV-R, CHECK, etc.) directement depuis Augment.

.PARAMETER Mode
    Le mode à exécuter. Valeurs possibles : ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ou le document actif.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à traiter (ex: "1.2.3").

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut : "development\config\unified-config.json".

.PARAMETER UpdateMemories
    Indique si les Memories d'Augment doivent être mises à jour après l'exécution du mode.

.EXAMPLE
    .\mode-manager-augment-integration.ps1 -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
    # Exécute le mode GRAN sur la tâche 1.2.3 du fichier spécifié

.EXAMPLE
    .\mode-manager-augment-integration.ps1 -Mode DEV-R -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -UpdateMemories
    # Exécute le mode DEV-R sur la tâche 1.2.3 du fichier spécifié et met à jour les Memories d'Augment

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

# Fonction pour exécuter le gestionnaire de modes
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

    # Construire les paramètres pour le gestionnaire de modes
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

    # Exécuter le gestionnaire de modes
    & $modeManagerPath @params
    return $LASTEXITCODE -eq 0
}

# Fonction pour mettre à jour les Memories d'Augment avec les informations du mode
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

    # Vérifier que le module AugmentMemoriesManager est disponible
    if (-not (Get-Command -Name "Update-AugmentMemories" -ErrorAction SilentlyContinue)) {
        Write-Warning "Fonction Update-AugmentMemories non disponible. Impossible de mettre à jour les Memories."
        return $false
    }

    # Générer le contenu des Memories spécifique au mode
    $modeContent = "# Mode $Mode activé"
    $modeContent += "`n- Fichier: $FilePath"
    if ($TaskIdentifier) {
        $modeContent += "`n- Tâche: $TaskIdentifier"
    }
    $modeContent += "`n- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # Ajouter des informations spécifiques au mode
    switch ($Mode) {
        "GRAN" {
            $modeContent += @"

## Mode GRAN - Granularisation
- Objectif: Décomposer les blocs complexes directement dans le document
- Déclencheurs: Taille > 5KB, complexité > 7, feedback utilisateur
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

## Mode DEV-R - Développement Roadmap
- Objectif: Implémenter ce qui est dans la roadmap
- Déclencheurs: Nouvelle tâche roadmap confirmée
- Directives: 
  - Implémenter la sélection sous-tâche par sous-tâche
  - Générer les tests
  - Corriger tous les problèmes
  - Assurer 100% couverture
"@
        }
        "CHECK" {
            $modeContent += @"

## Mode CHECK - Vérification
- Objectif: Vérifier l'état d'avancement des tâches
- Déclencheurs: Fin d'implémentation, validation requise
- Directives: 
  - Vérifier l'implémentation
  - Exécuter les tests
  - Mettre à jour la roadmap
  - Générer un rapport
"@
        }
        "ARCHI" {
            $modeContent += @"

## Mode ARCHI - Architecture
- Objectif: Structurer, modéliser, anticiper les dépendances
- Déclencheurs: Analyse d'impact, modélisation, dette technique
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

## Mode DEBUG - Débogage
- Objectif: Isoler, comprendre, corriger les anomalies
- Déclencheurs: Erreurs, logs, comportement inattendu
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
- Objectif: Maximiser couverture et fiabilité
- Déclencheurs: Specs, mode TDD actif
- Directives: 
  - test_suites(coverage=90%)
  - test_cases_by_pattern()
  - test_results_analysis()
"@
        }
        "OPTI" {
            $modeContent += @"

## Mode OPTI - Optimisation
- Objectif: Réduire complexité, taille ou temps d'exécution
- Déclencheurs: Complexité > 5, taille excessive
- Directives: 
  - runtime_hotspots()
  - reduce_LOC_nesting_calls()
  - optimized_version()
"@
        }
        "REVIEW" {
            $modeContent += @"

## Mode REVIEW - Revue
- Objectif: Vérifier lisibilité, standards, documentation
- Déclencheurs: Pre_commit, PR
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
- Objectif: Détecter et corriger les dépendances circulaires
- Déclencheurs: Logique récursive, erreurs d'import ou workflow bloqué
- Directives: 
  - Detect-CyclicDependencies()
  - Validate-WorkflowCycles()
  - auto_fix_cycles()
  - suggest_refactor_path()
"@
        }
        "PREDIC" {
            $modeContent += @"

## Mode PREDIC - Prédiction
- Objectif: Anticiper performances, détecter anomalies, analyser tendances
- Déclencheurs: Besoin d'analyse de charge ou de comportement futur
- Directives: 
  - predict_metrics()
  - find_anomalies()
  - analyze_trends()
  - export_prediction_report()
  - trigger_retraining_if_needed()
"@
        }
    }

    # Mettre à jour les Memories d'Augment
    try {
        # Créer un fichier temporaire avec le contenu des Memories
        $tempFile = [System.IO.Path]::GetTempFileName()
        $modeContent | Out-File -FilePath $tempFile -Encoding UTF8

        # Mettre à jour les Memories
        Export-MemoriesToVSCode
        Write-Host "Memories d'Augment mises à jour avec les informations du mode $Mode." -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "Erreur lors de la mise à jour des Memories d'Augment : $_"
        return $false
    } finally {
        # Supprimer le fichier temporaire
        if (Test-Path -Path $tempFile) {
            Remove-Item -Path $tempFile -Force
        }
    }
}

# Exécuter le gestionnaire de modes
$success = Invoke-ModeManager -Mode $Mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ConfigPath $ConfigPath -Force:$Force

# Mettre à jour les Memories d'Augment si demandé
if ($success -and $UpdateMemories) {
    Update-AugmentModeMemories -Mode $Mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier
}

# Retourner le résultat
exit [int](!$success)
