#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise la taille de lot pour un script parallÃƒÂ¨le en testant diffÃƒÂ©rentes valeurs et critÃƒÂ¨res.
.DESCRIPTION
    Ce script orchestre l'exÃƒÂ©cution d'un script de benchmark parallÃƒÂ¨le (`Test-ParallelPerformance.ps1`)
    avec diffÃƒÂ©rentes tailles de lot spÃƒÂ©cifiÃƒÂ©es (`BatchSizes`). Pour chaque taille, il exÃƒÂ©cute le benchmark
    plusieurs fois (`Iterations`) pour collecter des mÃƒÂ©triques de performance fiables (temps, CPU, mÃƒÂ©moire, taux de succÃƒÂ¨s).
    Il analyse ensuite ces rÃƒÂ©sultats agrÃƒÂ©gÃƒÂ©s pour identifier la taille de lot "optimale" selon un critÃƒÂ¨re
    configurable (`OptimizationMetric`).
    Finalement, il gÃƒÂ©nÃƒÂ¨re un rapport comparatif dÃƒÂ©taillÃƒÂ© au format JSON et, optionnellement, un rapport HTML
    interactif avec graphiques et recommandations dans un sous-rÃƒÂ©pertoire de sortie unique.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell ÃƒÂ  exÃƒÂ©cuter par `Test-ParallelPerformance.ps1`.
    Ce bloc doit typiquement appeler le script parallÃƒÂ¨le cible en utilisant le splatting
    avec les paramÃƒÂ¨tres reÃƒÂ§us. Exemple:
    {
        param($params) # ReÃƒÂ§oit la fusion de BaseParameters et du paramÃƒÂ¨tre de lot courant
        & "C:\Path\To\Your\ParallelScript.ps1" @params
    }
.PARAMETER BaseParameters
    Table de hachage contenant les paramÃƒÂ¨tres constants ÃƒÂ  passer au ScriptBlock (et donc au script cible)
    pour chaque test. Ces paramÃƒÂ¨tres ne varient pas avec la taille du lot.
.PARAMETER BatchSizeParameterName
    Nom exact (sensible ÃƒÂ  la casse) du paramÃƒÂ¨tre dans le script cible (via ScriptBlock/BaseParameters)
    qui contrÃƒÂ´le la taille du lot. Ex: 'BatchSize', 'ChunkSize', 'ItemsPerBatch'.
    Ce script injectera/modifiera cette clÃƒÂ© dans la table de hachage passÃƒÂ©e au ScriptBlock.
.PARAMETER BatchSizes
    Tableau d'entiers reprÃƒÂ©sentant les diffÃƒÂ©rentes tailles de lot ÃƒÂ  ÃƒÂ©valuer.
    Exemple: @(10, 20, 50, 100, 200)
.PARAMETER OutputPath
    Chemin du rÃƒÂ©pertoire racine oÃƒÂ¹ les rÃƒÂ©sultats seront stockÃƒÂ©s. Un sous-rÃƒÂ©pertoire unique
    (basÃƒÂ© sur le timestamp) sera crÃƒÂ©ÃƒÂ© pour contenir les sorties de cette exÃƒÂ©cution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un rÃƒÂ©pertoire contenant des donnÃƒÂ©es de test prÃƒÂ©-existantes.
    Si fourni et valide, ce chemin sera utilisÃƒÂ© (et potentiellement injectÃƒÂ© dans les BaseParameters
    via TestDataTargetParameterName). Sinon, si 'New-TestData.ps1' est trouvÃƒÂ©, il sera utilisÃƒÂ©
    pour gÃƒÂ©nÃƒÂ©rer des donnÃƒÂ©es dans le sous-rÃƒÂ©pertoire de sortie.
.PARAMETER TestDataTargetParameterName
    [Optionnel] Nom du paramÃƒÂ¨tre dans `BaseParameters` qui doit recevoir le chemin des donnÃƒÂ©es de test
    (`$actualTestDataPath`) si des donnÃƒÂ©es sont utilisÃƒÂ©es/gÃƒÂ©nÃƒÂ©rÃƒÂ©es. Utile si le script cible
    n'utilise pas 'ScriptsPath' pour ses donnÃƒÂ©es d'entrÃƒÂ©e.
    DÃƒÂ©faut: 'ScriptsPath'.
.PARAMETER Iterations
    Nombre de fois oÃƒÂ¹ `Test-ParallelPerformance.ps1` doit exÃƒÂ©cuter le `ScriptBlock` pour *chaque*
    taille de lot afin de calculer des moyennes et statistiques fiables. DÃƒÂ©faut: 3.
.PARAMETER OptimizationMetric
    [Optionnel] CritÃƒÂ¨re utilisÃƒÂ© pour dÃƒÂ©terminer la taille de lot "optimale" parmi les rÃƒÂ©sultats.
    Options:
      - 'FastestSuccessful' (DÃƒÂ©faut): SÃƒÂ©lectionne la taille de lot la plus rapide (temps ÃƒÂ©coulÃƒÂ© moyen le plus bas) parmi celles ayant atteint 100% de succÃƒÂ¨s.
      - 'LowestMemorySuccessful': SÃƒÂ©lectionne la taille de lot avec la consommation mÃƒÂ©moire privÃƒÂ©e moyenne la plus basse parmi celles ayant atteint 100% de succÃƒÂ¨s.
      - 'BestSuccessRate': SÃƒÂ©lectionne la taille de lot avec le taux de succÃƒÂ¨s le plus ÃƒÂ©levÃƒÂ©. En cas d'ÃƒÂ©galitÃƒÂ©, choisit la plus rapide parmi elles. Utile si aucune n'atteint 100%.
.PARAMETER GenerateReport
    Si spÃƒÂ©cifiÃƒÂ© ($true), gÃƒÂ©nÃƒÂ¨re un rapport HTML comparatif dÃƒÂ©taillÃƒÂ© incluant des graphiques interactifs
    et des recommandations basÃƒÂ©es sur le critÃƒÂ¨re d'optimisation.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es via 'New-TestData.ps1' est applicable, force la suppression
    et la regÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es mÃƒÂªme si elles existent dÃƒÂ©jÃƒÂ  dans le rÃƒÂ©pertoire de sortie.
.EXAMPLE
    # Optimisation standard pour Analyze-Scripts.ps1, focus sur la vitesse
    $targetScript = ".\development\scripts\analysis\Analyze-Scripts.ps1"
    $baseParams = @{ MaxWorkers = 8; Recurse = $true } # Analyze-Scripts.ps1 utilise -ScriptsPath implicitement
    $batchSizes = 10, 20, 50, 100, 200
    .\Optimize-ParallelBatchSize.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -BaseParameters $baseParams `
        -BatchSizeParameterName "BatchSize" `
        -BatchSizes $batchSizes `
        -OutputPath "C:\PerfReports\BatchOpt" `
        -TestDataPath "C:\SourceScripts" `
        -TestDataTargetParameterName "ScriptsPath" `
        -Iterations 5 `
        -GenerateReport `
        -OptimizationMetric FastestSuccessful `
        -Verbose

.EXAMPLE
    # Optimisation pour un script de traitement, focus sur la mÃƒÂ©moire, avec gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es
    $targetScript = ".\development\scripts\processing\Process-Data.ps1"
    # Process-Data.ps1 attend les donnÃƒÂ©es dans -InputFolder
    $baseParams = @{ MaxWorkers = 4; OutputFolder = "C:\ProcessedData" }
    $batchSizes = 50, 100, 250, 500
    .\Optimize-ParallelBatchSize.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -BaseParameters $baseParams `
        -BatchSizeParameterName "ItemsPerBatch" `
        -BatchSizes $batchSizes `
        -OutputPath "C:\PerfReports\MemOpt" `
        -TestDataTargetParameterName "InputFolder" ` # Injecter le chemin gÃƒÂ©nÃƒÂ©rÃƒÂ© ici
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration `
        -OptimizationMetric LowestMemorySuccessful

.NOTES
    Auteur     : Votre Nom/Ãƒâ€°quipe
    Version    : 2.1
    Date       : 2023-10-27
    DÃƒÂ©pendances:
        - Test-ParallelPerformance.ps1 (Requis, doit ÃƒÂªtre dans le mÃƒÂªme rÃƒÂ©pertoire ou chemin connu)
        - New-TestData.ps1 (Optionnel, pour gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es, mÃƒÂªme rÃƒÂ©pertoire)
        - Chart.js (via CDN pour le rapport HTML)

    Important:
    - Le script `Test-ParallelPerformance.ps1` est essentiel et doit retourner un PSCustomObject avec les mÃƒÂ©triques attendues (AverageExecutionTimeS, SuccessRatePercent, etc.).
    - Le `-ScriptBlock` doit ÃƒÂªtre correctement formulÃƒÂ© pour recevoir les paramÃƒÂ¨tres fusionnÃƒÂ©s (`BaseParameters` + le paramÃƒÂ¨tre de lot dynamique) et les passer au script cible via splatting (`@params` ou `@p`).
    - La gestion des donnÃƒÂ©es de test (`-TestDataPath`, `-TestDataTargetParameterName`, `-ForceTestDataGeneration`) permet une certaine flexibilitÃƒÂ© mais dÃƒÂ©pend de la capacitÃƒÂ© du script cible ÃƒÂ  utiliser le chemin fourni.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell qui exÃƒÂ©cute le script parallÃƒÂ¨le ÃƒÂ  tester, acceptant les paramÃƒÂ¨tres via splatting.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $false, HelpMessage = "ParamÃƒÂ¨tres constants passÃƒÂ©s au ScriptBlock pour chaque test.")]
    [hashtable]$BaseParameters = @{},

    [Parameter(Mandatory = $true, HelpMessage = "Nom du paramÃƒÂ¨tre dans le script cible contrÃƒÂ´lant la taille du lot.")]
    [ValidateNotNullOrEmpty()]
    [string]$BatchSizeParameterName,

    [Parameter(Mandatory = $true, HelpMessage = "Tableau des tailles de lot entiÃƒÂ¨res ÃƒÂ  ÃƒÂ©valuer.")]
    [ValidateNotNullOrEmpty()]
    [int[]]$BatchSizes,

    [Parameter(Mandatory = $true, HelpMessage = "RÃƒÂ©pertoire racine oÃƒÂ¹ le sous-dossier des rÃƒÂ©sultats sera crÃƒÂ©ÃƒÂ©.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les donnÃƒÂ©es de test prÃƒÂ©-existantes.")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nom du paramÃƒÂ¨tre dans BaseParameters oÃƒÂ¹ injecter le chemin des donnÃƒÂ©es. DÃƒÂ©faut: 'ScriptsPath'.")]
    [string]$TestDataTargetParameterName = 'ScriptsPath',

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'itÃƒÂ©rations du benchmark par taille de lot.")]
    [ValidateRange(1, 100)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false, HelpMessage = "CritÃƒÂ¨re pour dÃƒÂ©terminer la taille de lot optimale.")]
    [ValidateSet('FastestSuccessful', 'LowestMemorySuccessful', 'BestSuccessRate')]
    [string]$OptimizationMetric = 'FastestSuccessful',

    [Parameter(Mandatory = $false, HelpMessage = "GÃƒÂ©nÃƒÂ©rer un rapport HTML comparatif dÃƒÂ©taillÃƒÂ©.")]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false, HelpMessage = "Forcer la gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es de test via New-TestData.ps1 (si applicable).")]
    [switch]$ForceTestDataGeneration
)

#region Global Variables and Helper Functions
$startTimestamp = Get-Date

# --- Helper pour la validation des chemins et crÃƒÂ©ation de dossiers ---
function New-DirectoryIfNotExists {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([string]$Path, [string]$Purpose)
    $resolvedPath = $null
    try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if ($resolvedPath -and (Test-Path $resolvedPath -PathType Container)) {
            Write-Verbose "RÃƒÂ©pertoire existant trouvÃƒÂ© pour '$Purpose': $resolvedPath"
            return $resolvedPath.Path
        } elseif ($resolvedPath) {
            Write-Error "Le chemin '$Path' pour '$Purpose' existe mais n'est pas un rÃƒÂ©pertoire."
            return $null
        } else {
            # Le chemin n'existe pas, tenter de le crÃƒÂ©er
            if ($PSCmdlet.ShouldProcess($Path, "CrÃƒÂ©er le rÃƒÂ©pertoire pour '$Purpose'")) {
                $created = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
                Write-Verbose "RÃƒÂ©pertoire crÃƒÂ©ÃƒÂ© pour '$Purpose': $($created.FullName)"
                return $created.FullName
            } else {
                Write-Warning "CrÃƒÂ©ation du rÃƒÂ©pertoire pour '$Purpose' annulÃƒÂ©e."
                return $null
            }
        }
    } catch {
        Write-Error "Impossible de crÃƒÂ©er ou valider le rÃƒÂ©pertoire pour '$Purpose' ÃƒÂ  '$Path'. Erreur: $($_.Exception.Message)"
        return $null
    }
}

# --- Helper pour prÃƒÂ©parer les donnÃƒÂ©es JS pour le rapport HTML ---
function ConvertTo-JavaScriptData {
    param([object]$Data)
    return ($Data | ConvertTo-Json -Compress -Depth 5)
}

#endregion

#region Initialisation et Validation Strictes
Write-Host "=== Initialisation Optimisation Taille de Lot ($BatchSizeParameterName) ===" -ForegroundColor White -BackgroundColor DarkBlue

# 1. Valider le script de benchmark dÃƒÂ©pendant
$benchmarkScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ParallelPerformance.ps1"
if (-not (Test-Path $benchmarkScriptPath -PathType Leaf)) {
    Write-Error "Script dÃƒÂ©pendant crucial 'Test-ParallelPerformance.ps1' introuvable dans '$PSScriptRoot'. Ce script est requis pour exÃƒÂ©cuter les mesures. ArrÃƒÂªt."
    return # ArrÃƒÂªt immÃƒÂ©diat
}
Write-Verbose "Script de benchmark dÃƒÂ©pendant trouvÃƒÂ© : $benchmarkScriptPath"

# 2. CrÃƒÂ©er le rÃƒÂ©pertoire de sortie racine si nÃƒÂ©cessaire
$resolvedOutputPath = New-DirectoryIfNotExists -Path $OutputPath -Purpose "RÃƒÂ©sultats Globaux"
if (-not $resolvedOutputPath) { return }

# 3. CrÃƒÂ©er le sous-rÃƒÂ©pertoire unique pour cette exÃƒÂ©cution
$timestamp = $startTimestamp.ToString('yyyyMMddHHmmss')
$optimizationRunOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath "BatchOpt_$(($BatchSizeParameterName -replace '[^a-zA-Z0-9]','_'))_$timestamp"
$optimizationRunOutputPath = New-DirectoryIfNotExists -Path $optimizationRunOutputPath -Purpose "RÃƒÂ©sultats de cette ExÃƒÂ©cution d'Optimisation"
if (-not $optimizationRunOutputPath) { return }

Write-Host "RÃƒÂ©pertoire de sortie pour cette exÃƒÂ©cution : $optimizationRunOutputPath" -ForegroundColor Green

# 4. Gestion des donnÃƒÂ©es de test
$actualTestDataPath = $null # Chemin effectif qui sera utilisÃƒÂ©/injectÃƒÂ©
$testDataStatus = "Non applicable"

# 4a. VÃƒÂ©rifier le chemin explicite fourni
if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des donnÃƒÂ©es fournies : $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'est pas valide. Tentative de gÃƒÂ©nÃƒÂ©ration si New-TestData.ps1 existe."
    }
}

# 4b. Tenter la gÃƒÂ©nÃƒÂ©ration si pas de chemin valide fourni OU si on force la gÃƒÂ©nÃƒÂ©ration
if (-not $actualTestDataPath -or $ForceTestDataGeneration) {
    $testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
    if (Test-Path $testDataScriptPath -PathType Leaf) {
        $targetGeneratedDataPath = Join-Path -Path $optimizationRunOutputPath -ChildPath "generated_test_data"
        $generate = $false
        if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
            $generate = $true
            Write-Verbose "Le rÃƒÂ©pertoire de donnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es '$targetGeneratedDataPath' n'existe pas, gÃƒÂ©nÃƒÂ©ration planifiÃƒÂ©e."
        } elseif ($ForceTestDataGeneration) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et RegÃƒÂ©nÃƒÂ©rer les donnÃƒÂ©es de test (option -ForceTestDataGeneration)")) {
                Write-Verbose "ForÃƒÂ§age de la regÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test."
                try { Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop } catch { Write-Warning "Impossible de supprimer l'ancien dossier de donnÃƒÂ©es '$targetGeneratedDataPath': $($_.Exception.Message)" }
                $generate = $true
            } else {
                Write-Warning "RegÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test annulÃƒÂ©e par l'utilisateur. Utilisation des donnÃƒÂ©es existantes."
                $actualTestDataPath = $targetGeneratedDataPath # Utiliser l'existant si annulation
                $testDataStatus = "Utilisation des donnÃƒÂ©es existantes (regÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e): $actualTestDataPath"
            }
        } else {
            # Le dossier existe et on ne force pas -> utiliser l'existant
            $actualTestDataPath = $targetGeneratedDataPath
            $testDataStatus = "RÃƒÂ©utilisation des donnÃƒÂ©es prÃƒÂ©cÃƒÂ©demment gÃƒÂ©nÃƒÂ©rÃƒÂ©es: $actualTestDataPath"
            Write-Verbose $testDataStatus
        }

        if ($generate) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "GÃƒÂ©nÃƒÂ©rer les donnÃƒÂ©es de test via $testDataScriptPath")) {
                Write-Host "GÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
                try {
                    $genParams = @{ OutputPath = $targetGeneratedDataPath; ErrorAction = 'Stop' }
                    if ($ForceTestDataGeneration) { $genParams.Force = $true }
                    $generatedPath = & $testDataScriptPath @genParams

                    if ($generatedPath -and (Test-Path $generatedPath -PathType Container)) {
                        $actualTestDataPath = $generatedPath # Mise ÃƒÂ  jour du chemin effectif
                        $testDataStatus = "DonnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es avec succÃƒÂ¨s: $actualTestDataPath"
                        Write-Host $testDataStatus -ForegroundColor Green
                    } else {
                        Write-Error "La gÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test via New-TestData.ps1 a ÃƒÂ©chouÃƒÂ© ou n'a pas retournÃƒÂ© de chemin valide."
                        $testDataStatus = "Ãƒâ€°chec de la gÃƒÂ©nÃƒÂ©ration."
                        $actualTestDataPath = $null # Assurer qu'on n'utilise pas un chemin invalide
                    }
                } catch {
                    Write-Error "Erreur critique lors de l'appel ÃƒÂ  New-TestData.ps1: $($_.Exception.Message)"
                    $testDataStatus = "Ãƒâ€°chec critique de la gÃƒÂ©nÃƒÂ©ration."
                    $actualTestDataPath = $null
                }
            } else {
                Write-Warning "GÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test annulÃƒÂ©e par l'utilisateur."
                $testDataStatus = "GÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e."
                # Si le dossier existait avant l'annulation, s'assurer qu'on l'utilise
                if ($actualTestDataPath -eq $targetGeneratedDataPath) { $testDataStatus += " Utilisation des donnÃƒÂ©es prÃƒÂ©-existantes." }
                else { $actualTestDataPath = $null } # Si on a annulÃƒÂ© la crÃƒÂ©ation initiale
            }
        }
    } elseif (-not $actualTestDataPath) { # Si pas de chemin explicite et pas de New-TestData.ps1
        $testDataStatus = "Non requis/gÃƒÂ©rÃƒÂ© (TestDataPath non fourni/valide et New-TestData.ps1 non trouvÃƒÂ©)."
        Write-Verbose $testDataStatus
    }
}

# 4c. Injecter le chemin des donnÃƒÂ©es effectif dans BaseParameters si applicable
if ($actualTestDataPath -and $BaseParameters) {
    if ($BaseParameters.ContainsKey($TestDataTargetParameterName)) {
        Write-Verbose "Mise ÃƒÂ  jour de BaseParameters['$TestDataTargetParameterName'] avec '$actualTestDataPath'"
        $BaseParameters[$TestDataTargetParameterName] = $actualTestDataPath
    } else {
        Write-Warning "Le chemin des donnÃƒÂ©es '$actualTestDataPath' a ÃƒÂ©tÃƒÂ© dÃƒÂ©terminÃƒÂ©, mais le paramÃƒÂ¨tre cible '$TestDataTargetParameterName' n'existe pas dans BaseParameters. Le ScriptBlock devra gÃƒÂ©rer l'accÃƒÂ¨s aux donnÃƒÂ©es autrement."
    }
}

# 5. Afficher le contexte d'exÃƒÂ©cution
Write-Host "Contexte d'exÃƒÂ©cution :"
Write-Host "  - Script de Benchmark : $benchmarkScriptPath"
Write-Host "  - Tailles de Lot      : $($BatchSizes -join ', ')"
Write-Host "  - ItÃƒÂ©rations par Taille: $Iterations"
Write-Host "  - CritÃƒÂ¨re Optimisation: $OptimizationMetric"
Write-Host "  - GÃƒÂ©nÃƒÂ©ration Rapport HTML: $($GenerateReport.IsPresent)"
Write-Host "  - Statut DonnÃƒÂ©es Test : $testDataStatus"
Write-Verbose "  - ParamÃƒÂ¨tres de Base (-BaseParameters):"
Write-Verbose ($BaseParameters | Out-String)

Write-Verbose "Validation et Initialisation terminÃƒÂ©es."
#endregion

#region Fonction de GÃƒÂ©nÃƒÂ©ration du Rapport HTML (AdaptÃƒÂ©e)

function New-BatchSizeHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [array]$AllBatchResults,
        [Parameter(Mandatory = $true)] [string]$ReportPath,
        [Parameter(Mandatory = $false)] [PSCustomObject]$OptimalBatchInfo,
        [Parameter(Mandatory = $false)] [string]$OptimizationReason,
        [Parameter(Mandatory = $false)] [hashtable]$BaseParametersUsed,
        [Parameter(Mandatory = $false)] [string]$BatchSizeParamName,
        [Parameter(Mandatory = $false)] [int]$IterationsPerBatch,
        [Parameter(Mandatory = $false)] [string]$TestDataInfo,
        [Parameter(Mandatory = $false)] [string]$OutputDirectory
    )

    Write-Host "GÃƒÂ©nÃƒÂ©ration du rapport HTML comparatif : $ReportPath" -ForegroundColor Cyan

    $validResults = $AllBatchResults | Where-Object { $null -ne $_ -and $null -ne $_.PSObject.Properties['AverageExecutionTimeS'] -and $_.AverageExecutionTimeS -ge 0 }
    if ($validResults.Count -eq 0) {
        Write-Warning "Aucune donnÃƒÂ©e de rÃƒÂ©sultat valide pour gÃƒÂ©nÃƒÂ©rer les graphiques du rapport HTML."
        # Potentiellement crÃƒÂ©er un rapport minimal ici
        return
    }

    # Trier les rÃƒÂ©sultats valides par taille de lot pour les graphiques/tableaux
    $sortedResults = $validResults | Sort-Object BatchSize

    # PrÃƒÂ©parer les donnÃƒÂ©es pour JS
    $jsLabels = ConvertTo-JavaScriptData ($sortedResults.BatchSize)
    $jsAvgTimes = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageExecutionTimeS, 3) })
    $jsAvgCpu = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageProcessorTimeS, 3) })
    $jsAvgWS = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageWorkingSetMB, 2) })
    $jsAvgPM = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AveragePrivateMemoryMB, 2) })
    $jsSuccessRates = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.SuccessRatePercent, 1) })

    $paramsHtml = "<i>Aucun paramÃƒÂ¨tre de base spÃƒÂ©cifiÃƒÂ©</i>"
    if ($BaseParametersUsed -and $BaseParametersUsed.Count -gt 0) {
        $paramsHtml = ($BaseParametersUsed.GetEnumerator() | ForEach-Object { "<li><strong>$($_.Name):</strong> <span class='param-value'>$($_.Value | Out-String -Width 100)</span></li>" }) -join ""
        $paramsHtml = "<ul>$paramsHtml</ul>"
    }
    $dataInfoHtml = if (-not [string]::IsNullOrEmpty($TestDataInfo)) { "<p><span class='metric-label'>Statut DonnÃƒÂ©es Test:</span> $TestDataInfo</p>" } else { "" }

    # Section Optimale
    $optimalSectionHtml = ""
    if ($OptimalBatchInfo) {
        $optimalSectionHtml = @"
<div class="section optimal" id="optimal-result">
    <h2>Ã°Å¸Ââ€  Taille de Lot RecommandÃƒÂ©e (CritÃƒÂ¨re: $OptimizationReason)</h2>
    <p><span class="metric-label">Taille de Lot Optimale:</span> <span class="optimal-value">$($OptimalBatchInfo.BatchSize)</span></p>
    <p><span class="metric-label tooltip">Temps Moyen Ãƒâ€°coulÃƒÂ©:<span class="tooltiptext">DurÃƒÂ©e totale moyenne pour cette taille de lot. Plus bas est mieux.</span></span> $($OptimalBatchInfo.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label tooltip">Temps CPU Moyen:<span class="tooltiptext">Temps processeur moyen consommÃƒÂ©.</span></span> $($OptimalBatchInfo.AverageProcessorTimeS.ToString('F3')) s</p>
    <p><span class="metric-label tooltip">Working Set Moyen:<span class="tooltiptext">MÃƒÂ©moire physique moyenne utilisÃƒÂ©e.</span></span> $($OptimalBatchInfo.AverageWorkingSetMB.ToString('F2')) MB</p>
    <p><span class="metric-label tooltip">MÃƒÂ©moire PrivÃƒÂ©e Moyenne:<span class="tooltiptext">MÃƒÂ©moire non partagÃƒÂ©e moyenne allouÃƒÂ©e. Indicateur clÃƒÂ©.</span></span> $($OptimalBatchInfo.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Taux de SuccÃƒÂ¨s:</span> $($OptimalBatchInfo.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    } else {
        $optimalSectionHtml = @"
<div class="section warning" id="optimal-result">
    <h2>Ã¢Å¡Â Ã¯Â¸Â Taille de Lot Optimale Non TrouvÃƒÂ©e</h2>
    <p>Aucune taille de lot n'a satisfait le critÃƒÂ¨re d'optimisation '$OptimizationReason' (par exemple, aucune n'a atteint 100% de succÃƒÂ¨s si requis).</p>
    <p>Consultez les rÃƒÂ©sultats dÃƒÂ©taillÃƒÂ©s et les graphiques pour identifier le meilleur compromis pour vos besoins.</p>
</div>
"@
    }

    # Section Recommandations Alternatives (si applicable)
    $recommendationsHtml = ""
    $fastestOverall = $AllBatchResults | Where-Object { $_.AverageExecutionTimeS -ge 0 } | Sort-Object AverageExecutionTimeS | Select-Object -First 1
    $lowestMemOverall = $AllBatchResults | Where-Object { $_.AveragePrivateMemoryMB -ge 0 } | Sort-Object AveragePrivateMemoryMB | Select-Object -First 1
    $bestSuccessOverall = $AllBatchResults | Sort-Object -Property @{Expression = 'SuccessRatePercent'; Descending = $true}, 'AverageExecutionTimeS' | Select-Object -First 1

    $recoItems = @()
    if ($fastestOverall -and $OptimalBatchInfo -and $fastestOverall.BatchSize -ne $OptimalBatchInfo.BatchSize) {
        $recoItems += "<li>La taille de lot <strong>$($fastestOverall.BatchSize)</strong> ÃƒÂ©tait la plus rapide globalement ({$($fastestOverall.AverageExecutionTimeS.ToString('F3'))}s) mais n'a peut-ÃƒÂªtre pas atteint 100% de succÃƒÂ¨s ({$($fastestOverall.SuccessRatePercent.ToString('F1'))}%).</li>"
    }
    if ($lowestMemOverall -and $OptimalBatchInfo -and $lowestMemOverall.BatchSize -ne $OptimalBatchInfo.BatchSize) {
         $recoItems += "<li>La taille de lot <strong>$($lowestMemOverall.BatchSize)</strong> utilisait le moins de mÃƒÂ©moire privÃƒÂ©e ({$($lowestMemOverall.AveragePrivateMemoryMB.ToString('F2'))}MB) avec un temps moyen de {$($lowestMemOverall.AverageExecutionTimeS.ToString('F3'))}s et {$($lowestMemOverall.SuccessRatePercent.ToString('F1'))}% de succÃƒÂ¨s.</li>"
    }
     if ($bestSuccessOverall -and $OptimalBatchInfo -and $bestSuccessOverall.BatchSize -ne $OptimalBatchInfo.BatchSize -and $bestSuccessOverall.SuccessRatePercent -gt $OptimalBatchInfo.SuccessRatePercent) {
         $recoItems += "<li>La taille de lot <strong>$($bestSuccessOverall.BatchSize)</strong> avait le meilleur taux de succÃƒÂ¨s ({$($bestSuccessOverall.SuccessRatePercent.ToString('F1'))}%) avec un temps moyen de {$($bestSuccessOverall.AverageExecutionTimeS.ToString('F3'))}s.</li>"
    }

    if ($recoItems.Count -gt 0) {
        $recommendationsHtml = @"
<div class="section" id="recommendations">
    <h3>Autres Observations Pertinentes</h3>
    <ul>$($recoItems -join '')</ul>
</div>
"@
    }

    # Table des dÃƒÂ©tails (gÃƒÂ©nÃƒÂ©rÃƒÂ©e via boucle pour meilleur contrÃƒÂ´le)
    $detailsTableRows = $AllBatchResults | ForEach-Object {
        $avgExecTimeStr = if($_.AverageExecutionTimeS -ge 0) { $_.AverageExecutionTimeS.ToString('F3') } else { 'N/A' }
        $minExecTimeStr = if($_.MinExecutionTimeS -ge 0) { $_.MinExecutionTimeS.ToString('F3') } else { 'N/A' }
        $maxExecTimeStr = if($_.MaxExecutionTimeS -ge 0) { $_.MaxExecutionTimeS.ToString('F3') } else { 'N/A' }
        $avgCpuStr = if($_.AverageProcessorTimeS -ge 0) { $_.AverageProcessorTimeS.ToString('F3') } else { 'N/A' }
        $avgWsStr = if($_.AverageWorkingSetMB -ge 0) { $_.AverageWorkingSetMB.ToString('F2') } else { 'N/A' }
        $avgPmStr = if($_.AveragePrivateMemoryMB -ge 0) { $_.AveragePrivateMemoryMB.ToString('F2') } else { 'N/A' }
        $statusClass = ""
        if($_.Status -eq 'FailedOrIncomplete') { $statusClass = "class='status-failed'" } elseif ($_.SuccessRatePercent -eq 100) { $statusClass = "class='status-success'" }

        @"
        <tr $statusClass>
            <td class='number'>$($_.BatchSize)</td>
            <td class='number'>$($_.SuccessRatePercent.ToString('F1'))</td>
            <td class='number'>$avgExecTimeStr</td>
            <td class='number'>$minExecTimeStr</td>
            <td class='number'>$maxExecTimeStr</td>
            <td class='number'>$avgCpuStr</td>
            <td class='number'>$avgWsStr</td>
            <td class='number'>$avgPmStr</td>
        </tr>
"@
    }
    $detailsTableHtml = @"
<table class='details-table'>
    <thead><tr><th>Taille Lot</th><th>Taux SuccÃƒÂ¨s (%)</th><th>Temps Moyen (s)</th><th>Temps Min (s)</th><th>Temps Max (s)</th><th>CPU Moyen (s)</th><th>WS Moyen (MB)</th><th>PM Moyen (MB)</th></tr></thead>
    <tbody>$($detailsTableRows -join '')</tbody>
</table>
"@


    # --- Assemblage Final HTML ---
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport Optimisation Taille de Lot: $BatchSizeParamName</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
    <style>/* CSS Similaire ÃƒÂ  Test-ParallelPerformance */
        :root { --success-color: #28a745; --failure-color: #dc3545; --warning-color: #ffc107; --primary-color: #0056b3; --secondary-color: #007bff; --light-gray: #f8f9fa; --medium-gray: #e9ecef; --dark-gray: #343a40; --border-color: #dee2e6; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; line-height: 1.6; margin: 20px; background-color: var(--light-gray); color: var(--dark-gray); }
        .container { max-width: 1300px; margin: auto; background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 6px 12px rgba(0,0,0,0.1); }
        h1, h2, h3 { color: var(--primary-color); border-bottom: 2px solid var(--border-color); padding-bottom: 10px; margin-top: 30px; margin-bottom: 20px; font-weight: 600; }
        h1 { font-size: 2em; } h2 { font-size: 1.6em; } h3 { font-size: 1.3em; border-bottom: none; color: var(--secondary-color); }
        .section { background-color: var(--light-gray); padding: 20px; border: 1px solid var(--medium-gray); border-radius: 6px; margin-bottom: 25px; }
        .optimal { border-left: 6px solid var(--success-color); background-color: #e9f7ef; }
        .warning { border-left: 6px solid var(--warning-color); background-color: #fff8e1; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 0.95em; table-layout: fixed; }
        th, td { padding: 12px 15px; text-align: left; border: 1px solid var(--border-color); vertical-align: middle; word-wrap: break-word; }
        th { background-color: var(--secondary-color); color: white; font-weight: 600; white-space: normal; }
        tr:nth-child(even) { background-color: #ffffff; } tr:hover { background-color: var(--medium-gray); }
        .details-table td, .details-table th { text-align: right; }
        .details-table th:first-child, .details-table td:first-child { text-align: left; } /* Align first col left */
        .metric-label { font-weight: 600; color: var(--dark-gray); display: inline-block; min-width: 190px;}
        .chart-container { width: 100%; max-width: 900px; height: 450px; margin: 40px auto; border: 1px solid var(--border-color); padding: 20px; border-radius: 6px; background: white; box-shadow: 0 4px 8px rgba(0,0,0,0.05); }
        ul { padding-left: 20px; margin-top: 5px; } li { margin-bottom: 8px; }
        .param-value, code { font-family: 'Consolas', 'Menlo', 'Courier New', monospace; background-color: var(--medium-gray); padding: 3px 6px; border-radius: 4px; font-size: 0.9em; border: 1px solid #ced4da; display: inline-block; max-width: 95%; overflow-x: auto; vertical-align: middle; }
        .optimal-value { font-weight: bold; color: var(--success-color); font-size: 1.1em; }
        .tooltip { position: relative; display: inline-block; border-bottom: 1px dotted black; cursor: help; }
        .tooltip .tooltiptext { visibility: hidden; width: 250px; background-color: #333; color: #fff; text-align: center; border-radius: 6px; padding: 8px; position: absolute; z-index: 1; bottom: 130%; left: 50%; margin-left: -125px; opacity: 0; transition: opacity 0.3s; font-size: 0.9em; }
        .tooltip:hover .tooltiptext { visibility: visible; opacity: 1; }
        .status-failed td { background-color: #fdeeee; color: var(--failure-color); }
        .status-success td { background-color: #e9f7ef; }
    </style>
</head>
<body>
<div class="container">
    <h1>Rapport d'Optimisation de Taille de Lot (<code class='param-value'>$BatchSizeParamName</code>)</h1>
    <div class="section" id="context">
        <h2>Contexte de l'ExÃƒÂ©cution</h2>
        <p><span class="metric-label">GÃƒÂ©nÃƒÂ©rÃƒÂ© le:</span> $(Get-Date -Format "yyyy-MM-dd 'ÃƒÂ ' HH:mm:ss")</p>
        <p><span class="metric-label">ItÃƒÂ©rations par Taille:</span> $IterationsPerBatch</p>
        <p><span class="metric-label">CritÃƒÂ¨re d'Optimisation:</span> $OptimizationMetric</p>
        $dataInfoHtml
        <p><span class="metric-label">RÃƒÂ©pertoire des RÃƒÂ©sultats:</span> <code>$OutputDirectory</code></p>
        <h3>ParamÃƒÂ¨tres de Base UtilisÃƒÂ©s :</h3>
        $paramsHtml
    </div>

    $optimalSectionHtml
    $recommendationsHtml

    <div class="section" id="detailed-results">
        <h2>RÃƒÂ©sultats Comparatifs DÃƒÂ©taillÃƒÂ©s par Taille de Lot</h2>
        $detailsTableHtml
        <p class="notes"><i>Les mÃƒÂ©triques sont moyennÃƒÂ©es sur $IterationsPerBatch exÃƒÂ©cutions pour chaque taille de lot.</i></p>
    </div>

    <div class="section" id="charts">
        <h2>Graphiques Comparatifs</h2>
        <div class="chart-container"><canvas id="timeChart"></canvas></div>
        <div class="chart-container"><canvas id="memoryChart"></canvas></div>
        <div class="chart-container"><canvas id="successRateChart"></canvas></div>
    </div>
<script>
    const batchSizeLabels = $jsLabels;
    const commonChartOptions = {
        scales: { x: { title: { display: true, text: 'Taille de Lot ($BatchSizeParamName)', font: { size: 14 } } }, y: { beginAtZero: true, title: { display: true, font: { size: 14 } } } },
        responsive: true, maintainAspectRatio: false, interaction: { intersect: false, mode: 'index' },
        plugins: { legend: { position: 'top', labels: { font: { size: 13 } } }, title: { display: true, font: { size: 18, weight: 'bold' } } }
    };
    const createChart = (canvasId, config) => { if (document.getElementById(canvasId)) { new Chart(document.getElementById(canvasId).getContext('2d'), config); }};

    // Time Chart
    createChart('timeChart', { type: 'line', data: { labels: batchSizeLabels, datasets: [
        { label: 'Temps Ãƒâ€°coulÃƒÂ© Moyen (s)', data: $jsAvgTimes, borderColor: 'rgb(220, 53, 69)', backgroundColor: 'rgba(220, 53, 69, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 },
        { label: 'Temps CPU Moyen (s)', data: $jsAvgCpu, borderColor: 'rgb(13, 110, 253)', backgroundColor: 'rgba(13, 110, 253, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Performance Temps vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, yTime: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'line', data: { labels: batchSizeLabels, datasets: [
        { label: 'Working Set Moyen (MB)', data: $jsAvgWS, borderColor: 'rgb(25, 135, 84)', backgroundColor: 'rgba(25, 135, 84, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 },
        { label: 'MÃƒÂ©moire PrivÃƒÂ©e Moyenne (MB)', data: $jsAvgPM, borderColor: 'rgb(108, 117, 125)', backgroundColor: 'rgba(108, 117, 125, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Utilisation MÃƒÂ©moire vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, yMemory: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'MB'}}} }
    });

    // Success Rate Chart
    createChart('successRateChart', { type: 'bar', data: { labels: batchSizeLabels, datasets: [{ label: 'Taux de SuccÃƒÂ¨s (%)', data: $jsSuccessRates, backgroundColor: 'rgba(255, 193, 7, 0.7)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1 }] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Taux de SuccÃƒÂ¨s vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, y: { ...commonChartOptions.scales.y, min: 0, max: 100, title: { ...commonChartOptions.scales.y.title, text: '%' } } } }
    });
</script>
</div> <!-- /container -->
</body>
</html>
"@

    # Sauvegarder le rapport HTML
    try {
        $htmlContent | Out-File -FilePath $ReportPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML comparatif gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s : $ReportPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur critique lors de la sauvegarde du rapport HTML '$ReportPath': $($_.Exception.Message)"
        # Ne pas arrÃƒÂªter le script principal pour une erreur de rapport, juste notifier.
    }
}

#endregion

#region ExÃƒÂ©cution Principale du Benchmarking

Write-Host "`n=== DÃƒÂ©marrage des Tests par Taille de Lot ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan
Write-Host "CritÃƒÂ¨re d'Optimisation : $OptimizationMetric"

$allBatchSummaryResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalBatchSizes = $BatchSizes.Count
$currentBatchIndex = 0

# Boucle sur chaque taille de lot ÃƒÂ  tester
foreach ($batchSize in $BatchSizes) {
    $currentBatchIndex++
    $progressParams = @{
        Activity = "Optimisation Taille de Lot: $BatchSizeParameterName"
        Status   = "Test BatchSize $batchSize ($currentBatchIndex/$totalBatchSizes)"
        PercentComplete = (($currentBatchIndex -1) / $totalBatchSizes) * 100 # Start at 0%
        CurrentOperation = "PrÃƒÂ©paration..."
    }
    Write-Progress @progressParams

    Write-Host "`n--- Test BatchSize = $batchSize ($currentBatchIndex/$totalBatchSizes) ---" -ForegroundColor Yellow

    # PrÃƒÂ©parer les paramÃƒÂ¨tres spÃƒÂ©cifiques pour cette taille de lot
    $currentCombinedParameters = $BaseParameters.Clone() # Cloner pour isoler
    try {
        $currentCombinedParameters[$BatchSizeParameterName] = $batchSize
    } catch {
         Write-Error "Impossible d'ajouter/modifier le paramÃƒÂ¨tre '$BatchSizeParameterName' dans les paramÃƒÂ¨tres. VÃƒÂ©rifiez le nom et la structure de BaseParameters. Erreur: $($_.Exception.Message)"
         # Ajouter un rÃƒÂ©sultat d'ÃƒÂ©chec pour cette taille de lot et continuer
         $allBatchSummaryResults.Add([PSCustomObject]@{ BatchSize=$batchSize; Status='SetupError'; ErrorMessage=$_.Exception.Message; SuccessRatePercent=0; AverageExecutionTimeS=-1; AveragePrivateMemoryMB=-1 })
         continue # Passer ÃƒÂ  la taille de lot suivante
    }

    Write-Verbose "ParamÃƒÂ¨tres combinÃƒÂ©s pour le ScriptBlock (BatchSize $batchSize):"
    Write-Verbose ($currentCombinedParameters | Out-String)

    # Nom unique pour le test de performance sous-jacent
    $benchmarkTestName = "BatchSize_$($batchSize)_$(Get-Date -Format 'HHmmssfff')" # Plus de prÃƒÂ©cision pour unicitÃƒÂ©

    # ParamÃƒÂ¨tres pour Test-ParallelPerformance.ps1
    $benchmarkParams = @{
        ScriptBlock             = $ScriptBlock                # Le bloc qui appelle le script cible
        Parameters              = $currentCombinedParameters   # Params pour le ScriptBlock
        TestName                = $benchmarkTestName          # Nom pour les logs/rapports de CE test
        OutputPath              = $optimizationRunOutputPath  # Sortie DANS le dossier de l'optimisation
        Iterations              = $Iterations                 # RÃƒÂ©pÃƒÂ©titions pour cette taille
        GenerateReport          = $false # Ne pas gÃƒÂ©nÃƒÂ©rer de rapport HTML pour chaque taille, seulement le global
        NoGarbageCollection     = $true # Optimise-BatchSize ne force pas GC, laisser Test-ParallelPerformance gÃƒÂ©rer
        ErrorAction             = 'Continue'                  # Capturer les erreurs de Test-ParallelPerformance
    }
    # Note: TestDataPath n'est pas passÃƒÂ© directement ici, il est injectÃƒÂ© dans $currentCombinedParameters si besoin

    $batchResultSummary = $null
    $benchmarkError = $null # Variable pour stocker les erreurs de l'appel &

    try {
        Write-Progress @progressParams -CurrentOperation "ExÃƒÂ©cution de Test-ParallelPerformance ($Iterations itÃƒÂ©rations)..."
        Write-Verbose "Lancement de Test-ParallelPerformance.ps1 pour BatchSize $batchSize..."

        # ExÃƒÂ©cuter le benchmark et capturer sa sortie (le rÃƒÂ©sumÃƒÂ©) et ses erreurs
        $batchResultSummary = & $benchmarkScriptPath @benchmarkParams -ErrorVariable +benchmarkError # '+' pour ajouter aux erreurs existantes

        if ($benchmarkError) {
            Write-Warning "Erreurs non bloquantes lors de l'exÃƒÂ©cution de Test-ParallelPerformance pour BatchSize $batchSize :"
            $benchmarkError | ForEach-Object { Write-Warning ('    ' + $_.ToString()) }
        }
         Write-Progress @progressParams -CurrentOperation "Benchmark terminÃƒÂ©"

    } catch {
        # Erreur critique qui a arrÃƒÂªtÃƒÂ© Test-ParallelPerformance
        Write-Error "Ãƒâ€°chec critique lors de l'appel ÃƒÂ  Test-ParallelPerformance.ps1 pour BatchSize $batchSize. Erreur : $($_.Exception.Message)"
        $benchmarkError = $_ # Sauvegarder l'erreur critique
        # $batchResultSummary restera $null
    }

    # Traiter le rÃƒÂ©sultat (ou l'absence de rÃƒÂ©sultat) du benchmark
    if ($batchResultSummary -is [PSCustomObject] -and $batchResultSummary.PSObject.Properties.Name -contains 'AverageExecutionTimeS') {
        # RÃƒÂ©sultat valide reÃƒÂ§u
        $batchResultSummary | Add-Member -MemberType NoteProperty -Name "BatchSize" -Value $batchSize -Force
        $batchResultSummary | Add-Member -MemberType NoteProperty -Name "Status" -Value "Completed" -Force # Ajouter un statut
        $allBatchSummaryResults.Add($batchResultSummary)
        Write-Host ("RÃƒÂ©sultat enregistrÃƒÂ© pour BatchSize {0}: TempsMoyen={1:F3}s, SuccÃƒÂ¨s={2:F1}%, MemPrivMoy={3:F2}MB" -f `
            $batchSize, $batchResultSummary.AverageExecutionTimeS,
            $batchResultSummary.SuccessRatePercent, $batchResultSummary.AveragePrivateMemoryMB) -ForegroundColor Green
    } else {
        # Ãƒâ€°chec de l'exÃƒÂ©cution ou rÃƒÂ©sultat invalide
        $failureReason = if($benchmarkError) { $benchmarkError[0].ToString() } else { "Test-ParallelPerformance n'a pas retournÃƒÂ© un objet de rÃƒÂ©sumÃƒÂ© valide." }
        Write-Warning "Le test pour BatchSize $batchSize a ÃƒÂ©chouÃƒÂ© ou n'a pas retournÃƒÂ© de rÃƒÂ©sumÃƒÂ© valide. Raison: $failureReason"
        # Ajouter un rÃƒÂ©sultat d'ÃƒÂ©chec structurÃƒÂ©
        $failedResult = [PSCustomObject]@{
            BatchSize             = $batchSize
            TestName              = $benchmarkTestName
            Status                = 'FailedOrIncomplete'
            SuccessRatePercent    = 0
            AverageExecutionTimeS = -1.0; MinExecutionTimeS = -1.0; MaxExecutionTimeS = -1.0
            AverageProcessorTimeS = -1.0; MinProcessorTimeS = -1.0; MaxProcessorTimeS = -1.0
            AverageWorkingSetMB   = -1.0; MinWorkingSetMB = -1.0; MaxWorkingSetMB = -1.0
            AveragePrivateMemoryMB= -1.0; MinPrivateMemoryMB = -1.0; MaxPrivateMemoryMB = -1.0
            ErrorMessage          = $failureReason
        }
        $allBatchSummaryResults.Add($failedResult)
    }
     Write-Progress @progressParams -PercentComplete ($currentBatchIndex / $totalBatchSizes * 100) -CurrentOperation "TerminÃƒÂ©"

} # Fin de la boucle foreach ($batchSize in $BatchSizes)

Write-Progress @progressParams -Activity "Optimisation Taille de Lot: $BatchSizeParameterName" -Status "Analyse finale des rÃƒÂ©sultats..." -Completed

#endregion

#region Analyse Finale et GÃƒÂ©nÃƒÂ©ration des Rapports

Write-Host "`n=== Analyse Finale des RÃƒÂ©sultats ($($allBatchSummaryResults.Count) tailles testÃƒÂ©es) ===" -ForegroundColor Cyan

if ($allBatchSummaryResults.Count -eq 0) {
     Write-Warning "Aucun rÃƒÂ©sultat n'a ÃƒÂ©tÃƒÂ© collectÃƒÂ© (probablement interrompu). Impossible d'analyser ou de gÃƒÂ©nÃƒÂ©rer des rapports."
     return $null
}

# Trier les rÃƒÂ©sultats par taille de lot pour affichage cohÃƒÂ©rent
$sortedResults = $allBatchSummaryResults | Sort-Object BatchSize

# Analyser selon le critÃƒÂ¨re d'optimisation
$optimalBatchInfo = $null
$optimizationReason = "" # Pour le rapport

switch ($OptimizationMetric) {
    'FastestSuccessful' {
        $optimizationReason = "Temps d'exÃƒÂ©cution le plus bas avec 100% de succÃƒÂ¨s"
        $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
        if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        }
    }
    'LowestMemorySuccessful' {
         $optimizationReason = "Utilisation mÃƒÂ©moire privÃƒÂ©e la plus basse avec 100% de succÃƒÂ¨s"
         $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AveragePrivateMemoryMB -ge 0 }
         if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AveragePrivateMemoryMB | Select-Object -First 1
        }
    }
    'BestSuccessRate' {
        $optimizationReason = "Taux de succÃƒÂ¨s le plus ÃƒÂ©levÃƒÂ© (puis temps d'exÃƒÂ©cution le plus bas)"
        # Trier d'abord par succÃƒÂ¨s (dÃƒÂ©croissant), puis par temps (croissant)
        $optimalBatchInfo = $sortedResults | Where-Object {$_.AverageExecutionTimeS -ge 0} | Sort-Object -Property SuccessRatePercent -Descending | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        # Si plusieurs ont le mÃƒÂªme meilleur taux de succÃƒÂ¨s, Sort-Object par temps choisira le plus rapide.
    }
    default {
        # Ne devrait pas arriver avec ValidateSet, mais par sÃƒÂ©curitÃƒÂ©
        Write-Warning "CritÃƒÂ¨re d'optimisation '$OptimizationMetric' non reconnu. Utilisation de 'FastestSuccessful' par dÃƒÂ©faut."
        $optimizationReason = "Temps d'exÃƒÂ©cution le plus bas avec 100% de succÃƒÂ¨s (DÃƒÂ©faut)"
        $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
        if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        }
    }
}

# Afficher le rÃƒÂ©sultat de l'optimisation
if ($optimalBatchInfo) {
    Write-Host "`nÃ°Å¸Ââ€  Taille de Lot Optimale IdentifiÃƒÂ©e (CritÃƒÂ¨re: $optimizationReason) Ã°Å¸Ââ€ " -ForegroundColor Green
    Write-Host ("  Taille de lot  : {0}" -f $optimalBatchInfo.BatchSize) -ForegroundColor White
    Write-Host ("  Temps Moyen    : {0:F3} s" -f $optimalBatchInfo.AverageExecutionTimeS) -ForegroundColor White
    Write-Host ("  SuccÃƒÂ¨s         : {0:F1} %" -f $optimalBatchInfo.SuccessRatePercent) -ForegroundColor White
    Write-Host ("  MÃƒÂ©moire PrivÃƒÂ©e : {0:F2} MB" -f $optimalBatchInfo.AveragePrivateMemoryMB) -ForegroundColor White
} else {
    Write-Warning "`nAucune taille de lot n'a pu satisfaire le critÃƒÂ¨re d'optimisation '$optimizationReason'."
    # Chercher le meilleur compromis global (comme dans la version prÃƒÂ©cÃƒÂ©dente) peut ÃƒÂªtre utile ici
    $bestCompromise = $sortedResults | Where-Object { $_.AverageExecutionTimeS -ge 0 } | Sort-Object -Property SuccessRatePercent -Descending | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
     if($bestCompromise) {
         Write-Host "Ã°Å¸â€™Â¡ Suggestion (meilleur compromis succÃƒÂ¨s/vitesse trouvÃƒÂ©):" -ForegroundColor Yellow
         Write-Host ("  Taille de lot : {0} (SuccÃƒÂ¨s: {1:F1}%)" -f $bestCompromise.BatchSize, $bestCompromise.SuccessRatePercent) -ForegroundColor Yellow
         Write-Host ("  Temps moyen   : {0:F3} s" -f $bestCompromise.AverageExecutionTimeS) -ForegroundColor Yellow
         Write-Host ("  MÃƒÂ©moire PrivÃƒÂ©e: {0:F2} MB" -f $bestCompromise.AveragePrivateMemoryMB) -ForegroundColor Yellow
    } else {
         Write-Warning "Aucune exÃƒÂ©cution n'a fourni de rÃƒÂ©sultats valides."
    }
}

# Enregistrer les rÃƒÂ©sultats agrÃƒÂ©gÃƒÂ©s en JSON
$resultsJsonFileName = "BatchSizeOptimization_Summary_$($BatchSizeParameterName).json" # Nom simplifiÃƒÂ©
$resultsJsonPath = Join-Path -Path $optimizationRunOutputPath -ChildPath $resultsJsonFileName
try {
    # Exclure ErrorMessage dÃƒÂ©taillÃƒÂ© du JSON principal pour lisibilitÃƒÂ© si nÃƒÂ©cessaire
    $resultsForJson = $sortedResults #| Select-Object * -ExcludeProperty ErrorMessage # DÃƒÂ©commenter pour exclure
    ConvertTo-Json -InputObject $resultsForJson -Depth 5 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`nÃ°Å¸â€œÅ  RÃƒÂ©sumÃƒÂ© complet de l'optimisation enregistrÃƒÂ© (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement du rÃƒÂ©sumÃƒÂ© JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# GÃƒÂ©nÃƒÂ©rer le rapport HTML comparatif si demandÃƒÂ©
if ($GenerateReport) {
    if ($sortedResults.Count -gt 0) {
        $reportHtmlFileName = "BatchSizeOptimization_Report_$($BatchSizeParameterName).html" # Nom simplifiÃƒÂ©
        $reportHtmlPath = Join-Path -Path $optimizationRunOutputPath -ChildPath $reportHtmlFileName
        $reportParams = @{
            AllBatchResults    = $sortedResults # Passer les rÃƒÂ©sultats triÃƒÂ©s
            ReportPath         = $reportHtmlPath
            OptimalBatchInfo   = $optimalBatchInfo # Peut ÃƒÂªtre $null
            OptimizationReason = $optimizationReason
            BaseParametersUsed = $BaseParameters
            BatchSizeParamName = $BatchSizeParameterName
            IterationsPerBatch = $Iterations
            TestDataInfo       = $testDataStatus
            OutputDirectory    = $optimizationRunOutputPath # Ajouter le dossier de sortie au rapport
            ErrorAction        = 'Continue'
        }
        New-BatchSizeHtmlReport @reportParams
    } else {
        Write-Warning "GÃƒÂ©nÃƒÂ©ration du rapport HTML annulÃƒÂ©e car aucun rÃƒÂ©sultat n'a ÃƒÂ©tÃƒÂ© collectÃƒÂ©."
    }
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Optimisation Taille de Lot TerminÃƒÂ©e ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "DurÃƒÂ©e totale du script d'optimisation : $($totalDuration.ToString('g'))"

#endregion

# Retourner le tableau des rÃƒÂ©sultats triÃƒÂ©s par taille de lot
return $sortedResults