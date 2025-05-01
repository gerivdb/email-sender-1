<#
.SYNOPSIS
    Script pour optimiser les Memories d'Augment selon les conseils d'Augment Code.

.DESCRIPTION
    Ce script optimise les Memories d'Augment en suivant les conseils d'Augment Code,
    notamment en organisant les Memories par catégories fonctionnelles et en implémentant
    un système de sélection contextuelle des Memories basé sur le mode actif.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les Memories optimisées.
    Par défaut, utilise le chemin des Memories d'Augment dans VS Code.

.PARAMETER Mode
    Mode actif pour lequel optimiser les Memories.
    Valeurs possibles : ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut : "development\config\unified-config.json".

.EXAMPLE
    .\optimize-augment-memories.ps1
    # Optimise les Memories d'Augment avec les paramètres par défaut

.EXAMPLE
    .\optimize-augment-memories.ps1 -Mode GRAN -OutputPath "C:\temp\augment_memories.json"
    # Optimise les Memories d'Augment pour le mode GRAN et les enregistre dans le fichier spécifié

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [ValidateSet("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST", "ALL")]
    [string]$Mode = "ALL",

    [Parameter()]
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

# Importer le module AugmentMemoriesManager
$memoriesManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\AugmentMemoriesManager.ps1"
if (Test-Path -Path $memoriesManagerPath) {
    . $memoriesManagerPath
} else {
    Write-Error "Module AugmentMemoriesManager introuvable : $memoriesManagerPath"
    exit 1
}

# Charger la configuration unifiée
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    # Créer une configuration par défaut
    $config = [PSCustomObject]@{
        Augment = [PSCustomObject]@{
            Memories = [PSCustomObject]@{
                Enabled = $true
                UpdateFrequency = "Daily"
                MaxSizeKB = 5
                AutoSegmentation = $true
                VSCodeWorkspaceId = "224ad75ce65ce8cf2efd9efc61d3c988"
            }
        }
    }
}

# Définir le chemin de sortie par défaut si non spécifié
if (-not $OutputPath) {
    $workspaceId = if ($config.Augment.Memories.VSCodeWorkspaceId) { 
        $config.Augment.Memories.VSCodeWorkspaceId 
    } else { 
        "224ad75ce65ce8cf2efd9efc61d3c988" 
    }
    $OutputPath = "$env:APPDATA\Code\User\workspaceStorage\$workspaceId\Augment.vscode-augment\Augment-Memories"
}

# Fonction pour générer les Memories optimisées
function Get-OptimizedMemories {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Mode = "ALL"
    )

    # Définir les sections communes à tous les modes
    $commonSections = @(
        @{
            "name"    = "PROJECT STRUCTURE"
            "content" = @"
- Root: `D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1` with fewer folders at root level
- Scripts organized in `development/scripts/<module>` with subdirectories by domain
- Consolidate redundant directories (roadmap folders, analysis/analytics, etc.)
- Organize documentation in `docs/guides/` with thematic subfolders
- Roadmap files should be in the projet directory
- Templates directory in development folder, config directory in projet folder
- Clear distinction between development/scripts (executable scripts) and development/tools (reusable utilities)
- Use Hygen, pre-commit hooks, and MCP Desktop Commander for organization
"@
        },
        @{
            "name"    = "DEVELOPMENT STANDARDS"
            "content" = @"
- Encoding: UTF-8-BOM
- Input Size: 5KB limit per input, 4KB recommended per tool call
- PowerShell: approved verbs, `$null -eq $var`, ShouldProcess with ShouldContinue, PS 5.1/7 compatibility
- Python: src layout, black/pytest/pylint, typing, Flask factory pattern, SQLAlchemy ORM
- Global: YAML/JSON config, Markdown/JSON logs, SOLID/DRY/KISS principles
- Performance measurement: execution time, memory usage, operation counting
- Reporting formats: Text, HTML, JSON, CSV with configurable alert thresholds
"@
        },
        @{
            "name"    = "ROADMAP & TESTING PRINCIPLES"
            "content" = @"
- Roadmap: `Roadmap/roadmap_complete_converted.md` with hierarchical numbering system
- Tasks broken into "yocto-tasks" with checkbox tracking
- Tasks complete only when fully implemented, tested, and fixed (100% success rate)
- Unit tests required for each sub-task with zero failures
- Progressive approach to test development, starting simple and gradually improving
- CHECK mode to automatically verify and mark completed tasks in the roadmap
"@
        },
        @{
            "name"    = "OPERATIONAL MODES"
            "content" = @"
- GRAN mode: granularizes tasks directly in active document, adapting to complexity
- DEV-R mode: implements tasks sequentially with minimal explanations
- CHECK mode: verifies implementation status and updates roadmap
- User prefers working sequence: GRAN → DEV-R → CHECK
- Mode manager system needed for coherent switching between operational modes
"@
        },
        @{
            "name"    = "TOOLS & STACK"
            "content" = @"
- PowerShell: Pester, Runspace Pools, ForEach-Object -Parallel
- Python: pytest, pytest-cov, multiprocessing, pandas
- QA: TestOmnibus, Allure, SonarQube, unstable test detection
- Stack: n8n (localhost:5678), crewAI, Notion, MCP
- VS Code: 4096MB memory, 10k scroll lines, GPU on, UTF-8 (fr)
- Augment Code: 5KB input limit, 200,000 token context window
- AI API Integrations: User prefers using OpenRouter with Qwen3 model and provided an API key (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).
"@
        },
        @{
            "name"    = "USER PREFERENCES"
            "content" = @"
- Language: French (parle français)
- Git: email `gerivonderbitsh+dev@gmail.com`, uses `git add commit push --no-verify`
- Communication: concise responses (SILENT_DEVELOPMENT mode), small precise prompts
- Implementation: detailed plans before coding, thorough testing before completion
- Prefers "mode absolu" without emojis, filler, hype, or conversational elements
- Prefers smaller, more granular inputs when implementing functionality
"@
        }
    )

    # Définir les sections spécifiques à chaque mode
    $modeSections = @{
        "GRAN" = @(
            @{
                "name"    = "GRAN MODE"
                "content" = @"
## Mode GRAN - Granularisation
- Objectif: Décomposer les blocs complexes directement dans le document
- Déclencheurs: Taille > 5KB, complexité > 7, feedback utilisateur
- Directives: 
  - split_by_responsibility()
  - detect_concatenated_tasks()
  - isolate_subtasks()
  - extract_functions()
  - granular_unit_set()
- Extensions: utilise `SEGMENTOR` pour des données structurées ou volumineuses
"@
            },
            @{
                "name"    = "GRAN IMPLEMENTATION"
                "content" = @"
- Script principal: `development\scripts\maintenance\modes\gran-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Gran
- Paramètres clés:
  - FilePath: Chemin vers le fichier de roadmap à modifier
  - TaskIdentifier: Identifiant de la tâche à décomposer (ex: "1.2.3")
  - ComplexityLevel: Niveau de complexité (Simple, Medium, Complex, Auto)
  - Domain: Domaine de la tâche pour la génération de sous-tâches spécifiques
  - UseAI: Utiliser l'IA pour générer des sous-tâches adaptées
"@
            }
        ),
        "DEV-R" = @(
            @{
                "name"    = "DEV-R MODE"
                "content" = @"
## Mode DEV-R - Développement Roadmap
- Objectif: Implémenter ce qui est dans la roadmap
- Déclencheurs: Nouvelle tâche roadmap confirmée
- Directives: 
  - Implémenter la sélection sous-tâche par sous-tâche
  - Générer les tests
  - Corriger tous les problèmes
  - Assurer 100% couverture
"@
            },
            @{
                "name"    = "DEV-R IMPLEMENTATION"
                "content" = @"
- Script principal: `development\roadmap\parser\modes\dev-r\dev-r-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.DevR
- Paramètres clés:
  - FilePath: Chemin vers le fichier de roadmap
  - TaskIdentifier: Identifiant de la tâche à implémenter
  - ProjectPath: Chemin vers le répertoire du projet
  - TestsPath: Chemin vers le répertoire des tests
  - GenerateTests: Générer automatiquement des tests
  - UpdateRoadmap: Mettre à jour la roadmap après implémentation
"@
            }
        ),
        "CHECK" = @(
            @{
                "name"    = "CHECK MODE"
                "content" = @"
## Mode CHECK - Vérification
- Objectif: Vérifier l'état d'avancement des tâches
- Déclencheurs: Fin d'implémentation, validation requise
- Directives: 
  - Vérifier l'implémentation
  - Exécuter les tests
  - Mettre à jour la roadmap
  - Générer un rapport
"@
            },
            @{
                "name"    = "CHECK IMPLEMENTATION"
                "content" = @"
- Script principal: `development\scripts\maintenance\modes\check.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Check
- Paramètres clés:
  - FilePath: Chemin vers le fichier de roadmap
  - TaskIdentifier: Identifiant de la tâche à vérifier
  - GenerateReport: Générer un rapport de vérification
  - AutoUpdateRoadmap: Mettre à jour automatiquement la roadmap
  - RequireFullTestCoverage: Exiger une couverture de test complète
"@
            }
        ),
        "ARCHI" = @(
            @{
                "name"    = "ARCHI MODE"
                "content" = @"
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
            },
            @{
                "name"    = "ARCHI IMPLEMENTATION"
                "content" = @"
- Script principal: `development\scripts\maintenance\modes\archi-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Archi
- Paramètres clés:
  - FilePath: Chemin vers le fichier de roadmap
  - OutputPath: Chemin vers le répertoire de sortie des diagrammes
  - DiagramFormat: Format des diagrammes (PlantUML, Mermaid, Graphviz)
  - IncludeComponents: Inclure les composants dans les diagrammes
  - IncludeInterfaces: Inclure les interfaces dans les diagrammes
"@
            }
        ),
        "DEBUG" = @(
            @{
                "name"    = "DEBUG MODE"
                "content" = @"
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
            },
            @{
                "name"    = "DEBUG IMPLEMENTATION"
                "content" = @"
- Script principal: `development\roadmap\parser\modes\debug\debug-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Debug
- Paramètres clés:
  - FilePath: Chemin vers le fichier contenant l'erreur
  - ErrorLog: Chemin vers le fichier de log d'erreurs
  - GeneratePatch: Générer un patch correctif
  - IncludeStackTrace: Inclure la trace d'appel dans l'analyse
  - AnalyzePerformance: Analyser les performances
"@
            }
        ),
        "TEST" = @(
            @{
                "name"    = "TEST MODE"
                "content" = @"
## Mode TEST - Tests
- Objectif: Maximiser couverture et fiabilité
- Déclencheurs: Specs, mode TDD actif
- Directives: 
  - test_suites(coverage=90%)
  - test_cases_by_pattern()
  - test_results_analysis()
"@
            },
            @{
                "name"    = "TEST IMPLEMENTATION"
                "content" = @"
- Script principal: `development\roadmap\parser\modes\test\test-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Test
- Paramètres clés:
  - FilePath: Chemin vers le fichier à tester
  - TestsPath: Chemin vers le répertoire des tests
  - CoveragePath: Chemin vers le répertoire des rapports de couverture
  - TestFramework: Framework de test à utiliser (Pester, pytest)
  - GenerateReport: Générer un rapport de test
"@
            }
        ),
        "OPTI" = @(
            @{
                "name"    = "OPTI MODE"
                "content" = @"
## Mode OPTI - Optimisation
- Objectif: Réduire complexité, taille ou temps d'exécution
- Déclencheurs: Complexité > 5, taille excessive
- Directives: 
  - runtime_hotspots()
  - reduce_LOC_nesting_calls()
  - optimized_version()
- Extensions: inclut `PARALLELIZER` pour optimiser les traitements lourds, `CACHE_MGR` pour accélérer les accès et prédictions
"@
            },
            @{
                "name"    = "OPTI IMPLEMENTATION"
                "content" = @"
- Script principal: `development\scripts\maintenance\modes\opti-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Opti
- Paramètres clés:
  - FilePath: Chemin vers le fichier à optimiser
  - OptimizationTarget: Cible de l'optimisation (All, Memory, CPU, Size)
  - ProfileDepth: Profondeur de profilage
  - MemoryThreshold: Seuil de mémoire pour déclencher l'optimisation
  - TimeThreshold: Seuil de temps pour déclencher l'optimisation
"@
            }
        ),
        "REVIEW" = @(
            @{
                "name"    = "REVIEW MODE"
                "content" = @"
## Mode REVIEW - Revue
- Objectif: Vérifier lisibilité, standards, documentation
- Déclencheurs: Pre_commit, PR
- Directives: 
  - check_SOLID_KISS_DRY()
  - doc_ratio()
  - cyclomatic_score()
  - review_report()
"@
            },
            @{
                "name"    = "REVIEW IMPLEMENTATION"
                "content" = @"
- Script principal: `development\scripts\maintenance\modes\review-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Review
- Paramètres clés:
  - FilePath: Chemin vers le fichier à réviser
  - CodeStyle: Style de code à vérifier
  - DocRatio: Ratio de documentation requis
  - MaxCyclomaticComplexity: Complexité cyclomatique maximale autorisée
  - GenerateReport: Générer un rapport de revue
"@
            }
        ),
        "C-BREAK" = @(
            @{
                "name"    = "C-BREAK MODE"
                "content" = @"
## Mode C-BREAK - Cycle Break
- Objectif: Détecter et corriger les dépendances circulaires
- Déclencheurs: Logique récursive, erreurs d'import ou workflow bloqué
- Directives: 
  - Detect-CyclicDependencies()
  - Validate-WorkflowCycles()
  - auto_fix_cycles()
  - suggest_refactor_path()
"@
            },
            @{
                "name"    = "C-BREAK IMPLEMENTATION"
                "content" = @"
- Script principal: `development\scripts\maintenance\modes\c-break-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.CBreak
- Paramètres clés:
  - FilePath: Chemin vers le fichier à analyser
  - MaxRecursionDepth: Profondeur maximale de récursion
  - AnalyzeImports: Analyser les imports
  - AnalyzeReferences: Analyser les références
  - GenerateGraph: Générer un graphe des dépendances
"@
            }
        ),
        "PREDIC" = @(
            @{
                "name"    = "PREDIC MODE"
                "content" = @"
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
            },
            @{
                "name"    = "PREDIC IMPLEMENTATION"
                "content" = @"
- Script principal: `development\scripts\maintenance\modes\predic-mode.ps1`
- Configuration: `development\config\unified-config.json` section Modes.Predic
- Paramètres clés:
  - FilePath: Chemin vers le fichier à analyser
  - PredictionHorizon: Horizon de prédiction
  - AnomalyDetection: Activer la détection d'anomalies
  - TrendAnalysis: Activer l'analyse de tendances
  - AlertThreshold: Seuil d'alerte
"@
            }
        )
    }

    # Définir les sections d'optimisation communes
    $optimizationSections = @(
        @{
            "name"    = "MÉTHODO"
            "content" = @"
- **ANALYZE** : `decompose(tasks)`, `auto_complexity()`
- **LEARN** : `extract_patterns(existing_code)`
- **EXPLORE** : `ToT(3)`, `select_best()`
- **REASON** : `ReAct(1)` = analyze→execute→adjust
- **CODE** : `implement(functional_unit ≤ 5KB)`
- **PROGRESS** : `sequential(no_confirmation)`
- **ADAPT** : `granularity(detected_complexity)`
- **SEGMENT** : `divide_if(complex)`
"@
        },
        @{
            "name"    = "STANDARDS"
            "content" = @"
- **SOLID** : `auto_check()`
- **TDD** : `generate_tests(before_code)`
- **MEASURE** : `metrics(cyclomatic, input_size)`
- **DOCUMENT** : `auto(doc_ratio=20%)`
- **VALIDATE** : `pre_check(code)`
"@
        },
        @{
            "name"    = "INPUT_OPTIM"
            "content" = @"
- **PREVALIDATE** : `UTF8ByteCount(input), strict_limit=5KB`
- **SEGMENT** : `if(size>5KB) → split_by_function`
- **COMPRESS** : `strip(comments, spaces)` if needed
- **DETECT** : `byte_counter(auto)`
- **PREVENT** : `max_4KB/tool_call`
- **INCREMENTAL** : `if(multiple_funcs) → implement_one_by_one`
"@
        },
        @{
            "name"    = "AUTONOMIE"
            "content" = @"
- **PROGRESSION** : `chain_tasks(no_break, follow_roadmap)`
- **DECISION** : `resolve(heuristics_only)`
- **RESILIENCE** : `error_recovery(log=min)`
- **ESTIMATION** : `complexity(LOC, deps, patterns)`
- **RECOVERY** : `resume(last_stable_point)`
"@
        },
        @{
            "name"    = "COMMUNICATION"
            "content" = @"
- **FORMAT** : `predefined_struct(max_ratio=info/verbosity)`
- **SYNTHESIS** : `only(important_diffs, key_decisions)`
- **METADATA** : `attach(complete%, complexity_score)`
- **LANGUAGE** : `fr_concis(algonotation_opt)`
- **FEEDBACK** : `input_size, validation_status=visible`
"@
        }
    )

    # Créer l'objet des Memories
    $memories = @{
        "version"     = "2.0.0"
        "lastUpdated" = (Get-Date).ToString("o")
        "sections"    = @()
    }

    # Ajouter les sections communes
    $memories.sections += $commonSections

    # Ajouter les sections d'optimisation communes
    $memories.sections += $optimizationSections

    # Ajouter les sections spécifiques au mode
    if ($Mode -ne "ALL") {
        if ($modeSections.ContainsKey($Mode)) {
            $memories.sections += $modeSections[$Mode]
        }
    } else {
        # Ajouter une section résumée pour chaque mode
        $modesSummary = @{
            "name"    = "MODES SUMMARY"
            "content" = @"
- **ARCHI** : Structurer, modéliser, anticiper les dépendances
- **CHECK** : Vérifier l'état d'avancement des tâches
- **C-BREAK** : Détecter et résoudre les dépendances circulaires
- **DEBUG** : Isoler, comprendre, corriger les anomalies
- **DEV-R** : Implémenter ce qui est dans la roadmap
- **GRAN** : Décomposer les blocs complexes
- **OPTI** : Réduire complexité, taille ou temps d'exécution
- **PREDIC** : Anticiper performances, détecter anomalies, analyser tendances
- **REVIEW** : Vérifier lisibilité, standards, documentation
- **TEST** : Maximiser couverture et fiabilité
"@
        }
        $memories.sections += $modesSummary
    }

    return $memories
}

# Générer les Memories optimisées
$memories = Get-OptimizedMemories -Mode $Mode

# Enregistrer les Memories optimisées
try {
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir -PathType Container)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer les Memories
    $memories | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Memories optimisées enregistrées dans : $OutputPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors de l'enregistrement des Memories optimisées : $_"
    exit 1
}
