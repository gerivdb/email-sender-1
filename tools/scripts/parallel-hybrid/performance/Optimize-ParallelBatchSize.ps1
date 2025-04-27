#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise la taille de lot pour un script parallÃ¨le en testant diffÃ©rentes valeurs et critÃ¨res.
.DESCRIPTION
    Ce script orchestre l'exÃ©cution d'un script de benchmark parallÃ¨le (`Test-ParallelPerformance.ps1`)
    avec diffÃ©rentes tailles de lot spÃ©cifiÃ©es (`BatchSizes`). Pour chaque taille, il exÃ©cute le benchmark
    plusieurs fois (`Iterations`) pour collecter des mÃ©triques de performance fiables (temps, CPU, mÃ©moire, taux de succÃ¨s).
    Il analyse ensuite ces rÃ©sultats agrÃ©gÃ©s pour identifier la taille de lot "optimale" selon un critÃ¨re
    configurable (`OptimizationMetric`).
    Finalement, il gÃ©nÃ¨re un rapport comparatif dÃ©taillÃ© au format JSON et, optionnellement, un rapport HTML
    interactif avec graphiques et recommandations dans un sous-rÃ©pertoire de sortie unique.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell Ã  exÃ©cuter par `Test-ParallelPerformance.ps1`.
    Ce bloc doit typiquement appeler le script parallÃ¨le cible en utilisant le splatting
    avec les paramÃ¨tres reÃ§us. Exemple:
    {
        param($params) # ReÃ§oit la fusion de BaseParameters et du paramÃ¨tre de lot courant
        & "C:\Path\To\Your\ParallelScript.ps1" @params
    }
.PARAMETER BaseParameters
    Table de hachage contenant les paramÃ¨tres constants Ã  passer au ScriptBlock (et donc au script cible)
    pour chaque test. Ces paramÃ¨tres ne varient pas avec la taille du lot.
.PARAMETER BatchSizeParameterName
    Nom exact (sensible Ã  la casse) du paramÃ¨tre dans le script cible (via ScriptBlock/BaseParameters)
    qui contrÃ´le la taille du lot. Ex: 'BatchSize', 'ChunkSize', 'ItemsPerBatch'.
    Ce script injectera/modifiera cette clÃ© dans la table de hachage passÃ©e au ScriptBlock.
.PARAMETER BatchSizes
    Tableau d'entiers reprÃ©sentant les diffÃ©rentes tailles de lot Ã  Ã©valuer.
    Exemple: @(10, 20, 50, 100, 200)
.PARAMETER OutputPath
    Chemin du rÃ©pertoire racine oÃ¹ les rÃ©sultats seront stockÃ©s. Un sous-rÃ©pertoire unique
    (basÃ© sur le timestamp) sera crÃ©Ã© pour contenir les sorties de cette exÃ©cution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un rÃ©pertoire contenant des donnÃ©es de test prÃ©-existantes.
    Si fourni et valide, ce chemin sera utilisÃ© (et potentiellement injectÃ© dans les BaseParameters
    via TestDataTargetParameterName). Sinon, si 'New-TestData.ps1' est trouvÃ©, il sera utilisÃ©
    pour gÃ©nÃ©rer des donnÃ©es dans le sous-rÃ©pertoire de sortie.
.PARAMETER TestDataTargetParameterName
    [Optionnel] Nom du paramÃ¨tre dans `BaseParameters` qui doit recevoir le chemin des donnÃ©es de test
    (`$actualTestDataPath`) si des donnÃ©es sont utilisÃ©es/gÃ©nÃ©rÃ©es. Utile si le script cible
    n'utilise pas 'ScriptsPath' pour ses donnÃ©es d'entrÃ©e.
    DÃ©faut: 'ScriptsPath'.
.PARAMETER Iterations
    Nombre de fois oÃ¹ `Test-ParallelPerformance.ps1` doit exÃ©cuter le `ScriptBlock` pour *chaque*
    taille de lot afin de calculer des moyennes et statistiques fiables. DÃ©faut: 3.
.PARAMETER OptimizationMetric
    [Optionnel] CritÃ¨re utilisÃ© pour dÃ©terminer la taille de lot "optimale" parmi les rÃ©sultats.
    Options:
      - 'FastestSuccessful' (DÃ©faut): SÃ©lectionne la taille de lot la plus rapide (temps Ã©coulÃ© moyen le plus bas) parmi celles ayant atteint 100% de succÃ¨s.
      - 'LowestMemorySuccessful': SÃ©lectionne la taille de lot avec la consommation mÃ©moire privÃ©e moyenne la plus basse parmi celles ayant atteint 100% de succÃ¨s.
      - 'BestSuccessRate': SÃ©lectionne la taille de lot avec le taux de succÃ¨s le plus Ã©levÃ©. En cas d'Ã©galitÃ©, choisit la plus rapide parmi elles. Utile si aucune n'atteint 100%.
.PARAMETER GenerateReport
    Si spÃ©cifiÃ© ($true), gÃ©nÃ¨re un rapport HTML comparatif dÃ©taillÃ© incluant des graphiques interactifs
    et des recommandations basÃ©es sur le critÃ¨re d'optimisation.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la gÃ©nÃ©ration de donnÃ©es via 'New-TestData.ps1' est applicable, force la suppression
    et la regÃ©nÃ©ration des donnÃ©es mÃªme si elles existent dÃ©jÃ  dans le rÃ©pertoire de sortie.
.EXAMPLE
    # Optimisation standard pour Analyze-Scripts.ps1, focus sur la vitesse
    $targetScript = ".\scripts\analysis\Analyze-Scripts.ps1"
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
    # Optimisation pour un script de traitement, focus sur la mÃ©moire, avec gÃ©nÃ©ration de donnÃ©es
    $targetScript = ".\scripts\processing\Process-Data.ps1"
    # Process-Data.ps1 attend les donnÃ©es dans -InputFolder
    $baseParams = @{ MaxWorkers = 4; OutputFolder = "C:\ProcessedData" }
    $batchSizes = 50, 100, 250, 500
    .\Optimize-ParallelBatchSize.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -BaseParameters $baseParams `
        -BatchSizeParameterName "ItemsPerBatch" `
        -BatchSizes $batchSizes `
        -OutputPath "C:\PerfReports\MemOpt" `
        -TestDataTargetParameterName "InputFolder" ` # Injecter le chemin gÃ©nÃ©rÃ© ici
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration `
        -OptimizationMetric LowestMemorySuccessful

.NOTES
    Auteur     : Votre Nom/Ã‰quipe
    Version    : 2.1
    Date       : 2023-10-27
    DÃ©pendances:
        - Test-ParallelPerformance.ps1 (Requis, doit Ãªtre dans le mÃªme rÃ©pertoire ou chemin connu)
        - New-TestData.ps1 (Optionnel, pour gÃ©nÃ©ration de donnÃ©es, mÃªme rÃ©pertoire)
        - Chart.js (via CDN pour le rapport HTML)

    Important:
    - Le script `Test-ParallelPerformance.ps1` est essentiel et doit retourner un PSCustomObject avec les mÃ©triques attendues (AverageExecutionTimeS, SuccessRatePercent, etc.).
    - Le `-ScriptBlock` doit Ãªtre correctement formulÃ© pour recevoir les paramÃ¨tres fusionnÃ©s (`BaseParameters` + le paramÃ¨tre de lot dynamique) et les passer au script cible via splatting (`@params` ou `@p`).
    - La gestion des donnÃ©es de test (`-TestDataPath`, `-TestDataTargetParameterName`, `-ForceTestDataGeneration`) permet une certaine flexibilitÃ© mais dÃ©pend de la capacitÃ© du script cible Ã  utiliser le chemin fourni.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell qui exÃ©cute le script parallÃ¨le Ã  tester, acceptant les paramÃ¨tres via splatting.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $false, HelpMessage = "ParamÃ¨tres constants passÃ©s au ScriptBlock pour chaque test.")]
    [hashtable]$BaseParameters = @{},

    [Parameter(Mandatory = $true, HelpMessage = "Nom du paramÃ¨tre dans le script cible contrÃ´lant la taille du lot.")]
    [ValidateNotNullOrEmpty()]
    [string]$BatchSizeParameterName,

    [Parameter(Mandatory = $true, HelpMessage = "Tableau des tailles de lot entiÃ¨res Ã  Ã©valuer.")]
    [ValidateNotNullOrEmpty()]
    [int[]]$BatchSizes,

    [Parameter(Mandatory = $true, HelpMessage = "RÃ©pertoire racine oÃ¹ le sous-dossier des rÃ©sultats sera crÃ©Ã©.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les donnÃ©es de test prÃ©-existantes.")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nom du paramÃ¨tre dans BaseParameters oÃ¹ injecter le chemin des donnÃ©es. DÃ©faut: 'ScriptsPath'.")]
    [string]$TestDataTargetParameterName = 'ScriptsPath',

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'itÃ©rations du benchmark par taille de lot.")]
    [ValidateRange(1, 100)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false, HelpMessage = "CritÃ¨re pour dÃ©terminer la taille de lot optimale.")]
    [ValidateSet('FastestSuccessful', 'LowestMemorySuccessful', 'BestSuccessRate')]
    [string]$OptimizationMetric = 'FastestSuccessful',

    [Parameter(Mandatory = $false, HelpMessage = "GÃ©nÃ©rer un rapport HTML comparatif dÃ©taillÃ©.")]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false, HelpMessage = "Forcer la gÃ©nÃ©ration de donnÃ©es de test via New-TestData.ps1 (si applicable).")]
    [switch]$ForceTestDataGeneration
)

#region Global Variables and Helper Functions
$startTimestamp = Get-Date

# --- Helper pour la validation des chemins et crÃ©ation de dossiers ---
function New-DirectoryIfNotExists {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([string]$Path, [string]$Purpose)
    $resolvedPath = $null
    try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if ($resolvedPath -and (Test-Path $resolvedPath -PathType Container)) {
            Write-Verbose "RÃ©pertoire existant trouvÃ© pour '$Purpose': $resolvedPath"
            return $resolvedPath.Path
        } elseif ($resolvedPath) {
            Write-Error "Le chemin '$Path' pour '$Purpose' existe mais n'est pas un rÃ©pertoire."
            return $null
        } else {
            # Le chemin n'existe pas, tenter de le crÃ©er
            if ($PSCmdlet.ShouldProcess($Path, "CrÃ©er le rÃ©pertoire pour '$Purpose'")) {
                $created = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
                Write-Verbose "RÃ©pertoire crÃ©Ã© pour '$Purpose': $($created.FullName)"
                return $created.FullName
            } else {
                Write-Warning "CrÃ©ation du rÃ©pertoire pour '$Purpose' annulÃ©e."
                return $null
            }
        }
    } catch {
        Write-Error "Impossible de crÃ©er ou valider le rÃ©pertoire pour '$Purpose' Ã  '$Path'. Erreur: $($_.Exception.Message)"
        return $null
    }
}

# --- Helper pour prÃ©parer les donnÃ©es JS pour le rapport HTML ---
function ConvertTo-JavaScriptData {
    param([object]$Data)
    return ($Data | ConvertTo-Json -Compress -Depth 5)
}

#endregion

#region Initialisation et Validation Strictes
Write-Host "=== Initialisation Optimisation Taille de Lot ($BatchSizeParameterName) ===" -ForegroundColor White -BackgroundColor DarkBlue

# 1. Valider le script de benchmark dÃ©pendant
$benchmarkScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ParallelPerformance.ps1"
if (-not (Test-Path $benchmarkScriptPath -PathType Leaf)) {
    Write-Error "Script dÃ©pendant crucial 'Test-ParallelPerformance.ps1' introuvable dans '$PSScriptRoot'. Ce script est requis pour exÃ©cuter les mesures. ArrÃªt."
    return # ArrÃªt immÃ©diat
}
Write-Verbose "Script de benchmark dÃ©pendant trouvÃ© : $benchmarkScriptPath"

# 2. CrÃ©er le rÃ©pertoire de sortie racine si nÃ©cessaire
$resolvedOutputPath = New-DirectoryIfNotExists -Path $OutputPath -Purpose "RÃ©sultats Globaux"
if (-not $resolvedOutputPath) { return }

# 3. CrÃ©er le sous-rÃ©pertoire unique pour cette exÃ©cution
$timestamp = $startTimestamp.ToString('yyyyMMddHHmmss')
$optimizationRunOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath "BatchOpt_$(($BatchSizeParameterName -replace '[^a-zA-Z0-9]','_'))_$timestamp"
$optimizationRunOutputPath = New-DirectoryIfNotExists -Path $optimizationRunOutputPath -Purpose "RÃ©sultats de cette ExÃ©cution d'Optimisation"
if (-not $optimizationRunOutputPath) { return }

Write-Host "RÃ©pertoire de sortie pour cette exÃ©cution : $optimizationRunOutputPath" -ForegroundColor Green

# 4. Gestion des donnÃ©es de test
$actualTestDataPath = $null # Chemin effectif qui sera utilisÃ©/injectÃ©
$testDataStatus = "Non applicable"

# 4a. VÃ©rifier le chemin explicite fourni
if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des donnÃ©es fournies : $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'est pas valide. Tentative de gÃ©nÃ©ration si New-TestData.ps1 existe."
    }
}

# 4b. Tenter la gÃ©nÃ©ration si pas de chemin valide fourni OU si on force la gÃ©nÃ©ration
if (-not $actualTestDataPath -or $ForceTestDataGeneration) {
    $testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
    if (Test-Path $testDataScriptPath -PathType Leaf) {
        $targetGeneratedDataPath = Join-Path -Path $optimizationRunOutputPath -ChildPath "generated_test_data"
        $generate = $false
        if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
            $generate = $true
            Write-Verbose "Le rÃ©pertoire de donnÃ©es gÃ©nÃ©rÃ©es '$targetGeneratedDataPath' n'existe pas, gÃ©nÃ©ration planifiÃ©e."
        } elseif ($ForceTestDataGeneration) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et RegÃ©nÃ©rer les donnÃ©es de test (option -ForceTestDataGeneration)")) {
                Write-Verbose "ForÃ§age de la regÃ©nÃ©ration des donnÃ©es de test."
                try { Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop } catch { Write-Warning "Impossible de supprimer l'ancien dossier de donnÃ©es '$targetGeneratedDataPath': $($_.Exception.Message)" }
                $generate = $true
            } else {
                Write-Warning "RegÃ©nÃ©ration des donnÃ©es de test annulÃ©e par l'utilisateur. Utilisation des donnÃ©es existantes."
                $actualTestDataPath = $targetGeneratedDataPath # Utiliser l'existant si annulation
                $testDataStatus = "Utilisation des donnÃ©es existantes (regÃ©nÃ©ration annulÃ©e): $actualTestDataPath"
            }
        } else {
            # Le dossier existe et on ne force pas -> utiliser l'existant
            $actualTestDataPath = $targetGeneratedDataPath
            $testDataStatus = "RÃ©utilisation des donnÃ©es prÃ©cÃ©demment gÃ©nÃ©rÃ©es: $actualTestDataPath"
            Write-Verbose $testDataStatus
        }

        if ($generate) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "GÃ©nÃ©rer les donnÃ©es de test via $testDataScriptPath")) {
                Write-Host "GÃ©nÃ©ration des donnÃ©es de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
                try {
                    $genParams = @{ OutputPath = $targetGeneratedDataPath; ErrorAction = 'Stop' }
                    if ($ForceTestDataGeneration) { $genParams.Force = $true }
                    $generatedPath = & $testDataScriptPath @genParams

                    if ($generatedPath -and (Test-Path $generatedPath -PathType Container)) {
                        $actualTestDataPath = $generatedPath # Mise Ã  jour du chemin effectif
                        $testDataStatus = "DonnÃ©es gÃ©nÃ©rÃ©es avec succÃ¨s: $actualTestDataPath"
                        Write-Host $testDataStatus -ForegroundColor Green
                    } else {
                        Write-Error "La gÃ©nÃ©ration des donnÃ©es de test via New-TestData.ps1 a Ã©chouÃ© ou n'a pas retournÃ© de chemin valide."
                        $testDataStatus = "Ã‰chec de la gÃ©nÃ©ration."
                        $actualTestDataPath = $null # Assurer qu'on n'utilise pas un chemin invalide
                    }
                } catch {
                    Write-Error "Erreur critique lors de l'appel Ã  New-TestData.ps1: $($_.Exception.Message)"
                    $testDataStatus = "Ã‰chec critique de la gÃ©nÃ©ration."
                    $actualTestDataPath = $null
                }
            } else {
                Write-Warning "GÃ©nÃ©ration des donnÃ©es de test annulÃ©e par l'utilisateur."
                $testDataStatus = "GÃ©nÃ©ration annulÃ©e."
                # Si le dossier existait avant l'annulation, s'assurer qu'on l'utilise
                if ($actualTestDataPath -eq $targetGeneratedDataPath) { $testDataStatus += " Utilisation des donnÃ©es prÃ©-existantes." }
                else { $actualTestDataPath = $null } # Si on a annulÃ© la crÃ©ation initiale
            }
        }
    } elseif (-not $actualTestDataPath) { # Si pas de chemin explicite et pas de New-TestData.ps1
        $testDataStatus = "Non requis/gÃ©rÃ© (TestDataPath non fourni/valide et New-TestData.ps1 non trouvÃ©)."
        Write-Verbose $testDataStatus
    }
}

# 4c. Injecter le chemin des donnÃ©es effectif dans BaseParameters si applicable
if ($actualTestDataPath -and $BaseParameters) {
    if ($BaseParameters.ContainsKey($TestDataTargetParameterName)) {
        Write-Verbose "Mise Ã  jour de BaseParameters['$TestDataTargetParameterName'] avec '$actualTestDataPath'"
        $BaseParameters[$TestDataTargetParameterName] = $actualTestDataPath
    } else {
        Write-Warning "Le chemin des donnÃ©es '$actualTestDataPath' a Ã©tÃ© dÃ©terminÃ©, mais le paramÃ¨tre cible '$TestDataTargetParameterName' n'existe pas dans BaseParameters. Le ScriptBlock devra gÃ©rer l'accÃ¨s aux donnÃ©es autrement."
    }
}

# 5. Afficher le contexte d'exÃ©cution
Write-Host "Contexte d'exÃ©cution :"
Write-Host "  - Script de Benchmark : $benchmarkScriptPath"
Write-Host "  - Tailles de Lot      : $($BatchSizes -join ', ')"
Write-Host "  - ItÃ©rations par Taille: $Iterations"
Write-Host "  - CritÃ¨re Optimisation: $OptimizationMetric"
Write-Host "  - GÃ©nÃ©ration Rapport HTML: $($GenerateReport.IsPresent)"
Write-Host "  - Statut DonnÃ©es Test : $testDataStatus"
Write-Verbose "  - ParamÃ¨tres de Base (-BaseParameters):"
Write-Verbose ($BaseParameters | Out-String)

Write-Verbose "Validation et Initialisation terminÃ©es."
#endregion

#region Fonction de GÃ©nÃ©ration du Rapport HTML (AdaptÃ©e)

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

    Write-Host "GÃ©nÃ©ration du rapport HTML comparatif : $ReportPath" -ForegroundColor Cyan

    $validResults = $AllBatchResults | Where-Object { $null -ne $_ -and $null -ne $_.PSObject.Properties['AverageExecutionTimeS'] -and $_.AverageExecutionTimeS -ge 0 }
    if ($validResults.Count -eq 0) {
        Write-Warning "Aucune donnÃ©e de rÃ©sultat valide pour gÃ©nÃ©rer les graphiques du rapport HTML."
        # Potentiellement crÃ©er un rapport minimal ici
        return
    }

    # Trier les rÃ©sultats valides par taille de lot pour les graphiques/tableaux
    $sortedResults = $validResults | Sort-Object BatchSize

    # PrÃ©parer les donnÃ©es pour JS
    $jsLabels = ConvertTo-JavaScriptData ($sortedResults.BatchSize)
    $jsAvgTimes = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageExecutionTimeS, 3) })
    $jsAvgCpu = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageProcessorTimeS, 3) })
    $jsAvgWS = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageWorkingSetMB, 2) })
    $jsAvgPM = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AveragePrivateMemoryMB, 2) })
    $jsSuccessRates = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.SuccessRatePercent, 1) })

    $paramsHtml = "<i>Aucun paramÃ¨tre de base spÃ©cifiÃ©</i>"
    if ($BaseParametersUsed -and $BaseParametersUsed.Count -gt 0) {
        $paramsHtml = ($BaseParametersUsed.GetEnumerator() | ForEach-Object { "<li><strong>$($_.Name):</strong> <span class='param-value'>$($_.Value | Out-String -Width 100)</span></li>" }) -join ""
        $paramsHtml = "<ul>$paramsHtml</ul>"
    }
    $dataInfoHtml = if (-not [string]::IsNullOrEmpty($TestDataInfo)) { "<p><span class='metric-label'>Statut DonnÃ©es Test:</span> $TestDataInfo</p>" } else { "" }

    # Section Optimale
    $optimalSectionHtml = ""
    if ($OptimalBatchInfo) {
        $optimalSectionHtml = @"
<div class="section optimal" id="optimal-result">
    <h2>ðŸ† Taille de Lot RecommandÃ©e (CritÃ¨re: $OptimizationReason)</h2>
    <p><span class="metric-label">Taille de Lot Optimale:</span> <span class="optimal-value">$($OptimalBatchInfo.BatchSize)</span></p>
    <p><span class="metric-label tooltip">Temps Moyen Ã‰coulÃ©:<span class="tooltiptext">DurÃ©e totale moyenne pour cette taille de lot. Plus bas est mieux.</span></span> $($OptimalBatchInfo.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label tooltip">Temps CPU Moyen:<span class="tooltiptext">Temps processeur moyen consommÃ©.</span></span> $($OptimalBatchInfo.AverageProcessorTimeS.ToString('F3')) s</p>
    <p><span class="metric-label tooltip">Working Set Moyen:<span class="tooltiptext">MÃ©moire physique moyenne utilisÃ©e.</span></span> $($OptimalBatchInfo.AverageWorkingSetMB.ToString('F2')) MB</p>
    <p><span class="metric-label tooltip">MÃ©moire PrivÃ©e Moyenne:<span class="tooltiptext">MÃ©moire non partagÃ©e moyenne allouÃ©e. Indicateur clÃ©.</span></span> $($OptimalBatchInfo.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Taux de SuccÃ¨s:</span> $($OptimalBatchInfo.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    } else {
        $optimalSectionHtml = @"
<div class="section warning" id="optimal-result">
    <h2>âš ï¸ Taille de Lot Optimale Non TrouvÃ©e</h2>
    <p>Aucune taille de lot n'a satisfait le critÃ¨re d'optimisation '$OptimizationReason' (par exemple, aucune n'a atteint 100% de succÃ¨s si requis).</p>
    <p>Consultez les rÃ©sultats dÃ©taillÃ©s et les graphiques pour identifier le meilleur compromis pour vos besoins.</p>
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
        $recoItems += "<li>La taille de lot <strong>$($fastestOverall.BatchSize)</strong> Ã©tait la plus rapide globalement ({$($fastestOverall.AverageExecutionTimeS.ToString('F3'))}s) mais n'a peut-Ãªtre pas atteint 100% de succÃ¨s ({$($fastestOverall.SuccessRatePercent.ToString('F1'))}%).</li>"
    }
    if ($lowestMemOverall -and $OptimalBatchInfo -and $lowestMemOverall.BatchSize -ne $OptimalBatchInfo.BatchSize) {
         $recoItems += "<li>La taille de lot <strong>$($lowestMemOverall.BatchSize)</strong> utilisait le moins de mÃ©moire privÃ©e ({$($lowestMemOverall.AveragePrivateMemoryMB.ToString('F2'))}MB) avec un temps moyen de {$($lowestMemOverall.AverageExecutionTimeS.ToString('F3'))}s et {$($lowestMemOverall.SuccessRatePercent.ToString('F1'))}% de succÃ¨s.</li>"
    }
     if ($bestSuccessOverall -and $OptimalBatchInfo -and $bestSuccessOverall.BatchSize -ne $OptimalBatchInfo.BatchSize -and $bestSuccessOverall.SuccessRatePercent -gt $OptimalBatchInfo.SuccessRatePercent) {
         $recoItems += "<li>La taille de lot <strong>$($bestSuccessOverall.BatchSize)</strong> avait le meilleur taux de succÃ¨s ({$($bestSuccessOverall.SuccessRatePercent.ToString('F1'))}%) avec un temps moyen de {$($bestSuccessOverall.AverageExecutionTimeS.ToString('F3'))}s.</li>"
    }

    if ($recoItems.Count -gt 0) {
        $recommendationsHtml = @"
<div class="section" id="recommendations">
    <h3>Autres Observations Pertinentes</h3>
    <ul>$($recoItems -join '')</ul>
</div>
"@
    }

    # Table des dÃ©tails (gÃ©nÃ©rÃ©e via boucle pour meilleur contrÃ´le)
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
    <thead><tr><th>Taille Lot</th><th>Taux SuccÃ¨s (%)</th><th>Temps Moyen (s)</th><th>Temps Min (s)</th><th>Temps Max (s)</th><th>CPU Moyen (s)</th><th>WS Moyen (MB)</th><th>PM Moyen (MB)</th></tr></thead>
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
    <style>/* CSS Similaire Ã  Test-ParallelPerformance */
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
        <h2>Contexte de l'ExÃ©cution</h2>
        <p><span class="metric-label">GÃ©nÃ©rÃ© le:</span> $(Get-Date -Format "yyyy-MM-dd 'Ã ' HH:mm:ss")</p>
        <p><span class="metric-label">ItÃ©rations par Taille:</span> $IterationsPerBatch</p>
        <p><span class="metric-label">CritÃ¨re d'Optimisation:</span> $OptimizationMetric</p>
        $dataInfoHtml
        <p><span class="metric-label">RÃ©pertoire des RÃ©sultats:</span> <code>$OutputDirectory</code></p>
        <h3>ParamÃ¨tres de Base UtilisÃ©s :</h3>
        $paramsHtml
    </div>

    $optimalSectionHtml
    $recommendationsHtml

    <div class="section" id="detailed-results">
        <h2>RÃ©sultats Comparatifs DÃ©taillÃ©s par Taille de Lot</h2>
        $detailsTableHtml
        <p class="notes"><i>Les mÃ©triques sont moyennÃ©es sur $IterationsPerBatch exÃ©cutions pour chaque taille de lot.</i></p>
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
        { label: 'Temps Ã‰coulÃ© Moyen (s)', data: $jsAvgTimes, borderColor: 'rgb(220, 53, 69)', backgroundColor: 'rgba(220, 53, 69, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 },
        { label: 'Temps CPU Moyen (s)', data: $jsAvgCpu, borderColor: 'rgb(13, 110, 253)', backgroundColor: 'rgba(13, 110, 253, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Performance Temps vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, yTime: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'line', data: { labels: batchSizeLabels, datasets: [
        { label: 'Working Set Moyen (MB)', data: $jsAvgWS, borderColor: 'rgb(25, 135, 84)', backgroundColor: 'rgba(25, 135, 84, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 },
        { label: 'MÃ©moire PrivÃ©e Moyenne (MB)', data: $jsAvgPM, borderColor: 'rgb(108, 117, 125)', backgroundColor: 'rgba(108, 117, 125, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Utilisation MÃ©moire vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, yMemory: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'MB'}}} }
    });

    // Success Rate Chart
    createChart('successRateChart', { type: 'bar', data: { labels: batchSizeLabels, datasets: [{ label: 'Taux de SuccÃ¨s (%)', data: $jsSuccessRates, backgroundColor: 'rgba(255, 193, 7, 0.7)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1 }] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Taux de SuccÃ¨s vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, y: { ...commonChartOptions.scales.y, min: 0, max: 100, title: { ...commonChartOptions.scales.y.title, text: '%' } } } }
    });
</script>
</div> <!-- /container -->
</body>
</html>
"@

    # Sauvegarder le rapport HTML
    try {
        $htmlContent | Out-File -FilePath $ReportPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML comparatif gÃ©nÃ©rÃ© avec succÃ¨s : $ReportPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur critique lors de la sauvegarde du rapport HTML '$ReportPath': $($_.Exception.Message)"
        # Ne pas arrÃªter le script principal pour une erreur de rapport, juste notifier.
    }
}

#endregion

#region ExÃ©cution Principale du Benchmarking

Write-Host "`n=== DÃ©marrage des Tests par Taille de Lot ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan
Write-Host "CritÃ¨re d'Optimisation : $OptimizationMetric"

$allBatchSummaryResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalBatchSizes = $BatchSizes.Count
$currentBatchIndex = 0

# Boucle sur chaque taille de lot Ã  tester
foreach ($batchSize in $BatchSizes) {
    $currentBatchIndex++
    $progressParams = @{
        Activity = "Optimisation Taille de Lot: $BatchSizeParameterName"
        Status   = "Test BatchSize $batchSize ($currentBatchIndex/$totalBatchSizes)"
        PercentComplete = (($currentBatchIndex -1) / $totalBatchSizes) * 100 # Start at 0%
        CurrentOperation = "PrÃ©paration..."
    }
    Write-Progress @progressParams

    Write-Host "`n--- Test BatchSize = $batchSize ($currentBatchIndex/$totalBatchSizes) ---" -ForegroundColor Yellow

    # PrÃ©parer les paramÃ¨tres spÃ©cifiques pour cette taille de lot
    $currentCombinedParameters = $BaseParameters.Clone() # Cloner pour isoler
    try {
        $currentCombinedParameters[$BatchSizeParameterName] = $batchSize
    } catch {
         Write-Error "Impossible d'ajouter/modifier le paramÃ¨tre '$BatchSizeParameterName' dans les paramÃ¨tres. VÃ©rifiez le nom et la structure de BaseParameters. Erreur: $($_.Exception.Message)"
         # Ajouter un rÃ©sultat d'Ã©chec pour cette taille de lot et continuer
         $allBatchSummaryResults.Add([PSCustomObject]@{ BatchSize=$batchSize; Status='SetupError'; ErrorMessage=$_.Exception.Message; SuccessRatePercent=0; AverageExecutionTimeS=-1; AveragePrivateMemoryMB=-1 })
         continue # Passer Ã  la taille de lot suivante
    }

    Write-Verbose "ParamÃ¨tres combinÃ©s pour le ScriptBlock (BatchSize $batchSize):"
    Write-Verbose ($currentCombinedParameters | Out-String)

    # Nom unique pour le test de performance sous-jacent
    $benchmarkTestName = "BatchSize_$($batchSize)_$(Get-Date -Format 'HHmmssfff')" # Plus de prÃ©cision pour unicitÃ©

    # ParamÃ¨tres pour Test-ParallelPerformance.ps1
    $benchmarkParams = @{
        ScriptBlock             = $ScriptBlock                # Le bloc qui appelle le script cible
        Parameters              = $currentCombinedParameters   # Params pour le ScriptBlock
        TestName                = $benchmarkTestName          # Nom pour les logs/rapports de CE test
        OutputPath              = $optimizationRunOutputPath  # Sortie DANS le dossier de l'optimisation
        Iterations              = $Iterations                 # RÃ©pÃ©titions pour cette taille
        GenerateReport          = $false # Ne pas gÃ©nÃ©rer de rapport HTML pour chaque taille, seulement le global
        NoGarbageCollection     = $true # Optimise-BatchSize ne force pas GC, laisser Test-ParallelPerformance gÃ©rer
        ErrorAction             = 'Continue'                  # Capturer les erreurs de Test-ParallelPerformance
    }
    # Note: TestDataPath n'est pas passÃ© directement ici, il est injectÃ© dans $currentCombinedParameters si besoin

    $batchResultSummary = $null
    $benchmarkError = $null # Variable pour stocker les erreurs de l'appel &

    try {
        Write-Progress @progressParams -CurrentOperation "ExÃ©cution de Test-ParallelPerformance ($Iterations itÃ©rations)..."
        Write-Verbose "Lancement de Test-ParallelPerformance.ps1 pour BatchSize $batchSize..."

        # ExÃ©cuter le benchmark et capturer sa sortie (le rÃ©sumÃ©) et ses erreurs
        $batchResultSummary = & $benchmarkScriptPath @benchmarkParams -ErrorVariable +benchmarkError # '+' pour ajouter aux erreurs existantes

        if ($benchmarkError) {
            Write-Warning "Erreurs non bloquantes lors de l'exÃ©cution de Test-ParallelPerformance pour BatchSize $batchSize :"
            $benchmarkError | ForEach-Object { Write-Warning ('    ' + $_.ToString()) }
        }
         Write-Progress @progressParams -CurrentOperation "Benchmark terminÃ©"

    } catch {
        # Erreur critique qui a arrÃªtÃ© Test-ParallelPerformance
        Write-Error "Ã‰chec critique lors de l'appel Ã  Test-ParallelPerformance.ps1 pour BatchSize $batchSize. Erreur : $($_.Exception.Message)"
        $benchmarkError = $_ # Sauvegarder l'erreur critique
        # $batchResultSummary restera $null
    }

    # Traiter le rÃ©sultat (ou l'absence de rÃ©sultat) du benchmark
    if ($batchResultSummary -is [PSCustomObject] -and $batchResultSummary.PSObject.Properties.Name -contains 'AverageExecutionTimeS') {
        # RÃ©sultat valide reÃ§u
        $batchResultSummary | Add-Member -MemberType NoteProperty -Name "BatchSize" -Value $batchSize -Force
        $batchResultSummary | Add-Member -MemberType NoteProperty -Name "Status" -Value "Completed" -Force # Ajouter un statut
        $allBatchSummaryResults.Add($batchResultSummary)
        Write-Host ("RÃ©sultat enregistrÃ© pour BatchSize {0}: TempsMoyen={1:F3}s, SuccÃ¨s={2:F1}%, MemPrivMoy={3:F2}MB" -f `
            $batchSize, $batchResultSummary.AverageExecutionTimeS,
            $batchResultSummary.SuccessRatePercent, $batchResultSummary.AveragePrivateMemoryMB) -ForegroundColor Green
    } else {
        # Ã‰chec de l'exÃ©cution ou rÃ©sultat invalide
        $failureReason = if($benchmarkError) { $benchmarkError[0].ToString() } else { "Test-ParallelPerformance n'a pas retournÃ© un objet de rÃ©sumÃ© valide." }
        Write-Warning "Le test pour BatchSize $batchSize a Ã©chouÃ© ou n'a pas retournÃ© de rÃ©sumÃ© valide. Raison: $failureReason"
        # Ajouter un rÃ©sultat d'Ã©chec structurÃ©
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
     Write-Progress @progressParams -PercentComplete ($currentBatchIndex / $totalBatchSizes * 100) -CurrentOperation "TerminÃ©"

} # Fin de la boucle foreach ($batchSize in $BatchSizes)

Write-Progress @progressParams -Activity "Optimisation Taille de Lot: $BatchSizeParameterName" -Status "Analyse finale des rÃ©sultats..." -Completed

#endregion

#region Analyse Finale et GÃ©nÃ©ration des Rapports

Write-Host "`n=== Analyse Finale des RÃ©sultats ($($allBatchSummaryResults.Count) tailles testÃ©es) ===" -ForegroundColor Cyan

if ($allBatchSummaryResults.Count -eq 0) {
     Write-Warning "Aucun rÃ©sultat n'a Ã©tÃ© collectÃ© (probablement interrompu). Impossible d'analyser ou de gÃ©nÃ©rer des rapports."
     return $null
}

# Trier les rÃ©sultats par taille de lot pour affichage cohÃ©rent
$sortedResults = $allBatchSummaryResults | Sort-Object BatchSize

# Analyser selon le critÃ¨re d'optimisation
$optimalBatchInfo = $null
$optimizationReason = "" # Pour le rapport

switch ($OptimizationMetric) {
    'FastestSuccessful' {
        $optimizationReason = "Temps d'exÃ©cution le plus bas avec 100% de succÃ¨s"
        $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
        if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        }
    }
    'LowestMemorySuccessful' {
         $optimizationReason = "Utilisation mÃ©moire privÃ©e la plus basse avec 100% de succÃ¨s"
         $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AveragePrivateMemoryMB -ge 0 }
         if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AveragePrivateMemoryMB | Select-Object -First 1
        }
    }
    'BestSuccessRate' {
        $optimizationReason = "Taux de succÃ¨s le plus Ã©levÃ© (puis temps d'exÃ©cution le plus bas)"
        # Trier d'abord par succÃ¨s (dÃ©croissant), puis par temps (croissant)
        $optimalBatchInfo = $sortedResults | Where-Object {$_.AverageExecutionTimeS -ge 0} | Sort-Object -Property SuccessRatePercent -Descending | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        # Si plusieurs ont le mÃªme meilleur taux de succÃ¨s, Sort-Object par temps choisira le plus rapide.
    }
    default {
        # Ne devrait pas arriver avec ValidateSet, mais par sÃ©curitÃ©
        Write-Warning "CritÃ¨re d'optimisation '$OptimizationMetric' non reconnu. Utilisation de 'FastestSuccessful' par dÃ©faut."
        $optimizationReason = "Temps d'exÃ©cution le plus bas avec 100% de succÃ¨s (DÃ©faut)"
        $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
        if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        }
    }
}

# Afficher le rÃ©sultat de l'optimisation
if ($optimalBatchInfo) {
    Write-Host "`nðŸ† Taille de Lot Optimale IdentifiÃ©e (CritÃ¨re: $optimizationReason) ðŸ†" -ForegroundColor Green
    Write-Host ("  Taille de lot  : {0}" -f $optimalBatchInfo.BatchSize) -ForegroundColor White
    Write-Host ("  Temps Moyen    : {0:F3} s" -f $optimalBatchInfo.AverageExecutionTimeS) -ForegroundColor White
    Write-Host ("  SuccÃ¨s         : {0:F1} %" -f $optimalBatchInfo.SuccessRatePercent) -ForegroundColor White
    Write-Host ("  MÃ©moire PrivÃ©e : {0:F2} MB" -f $optimalBatchInfo.AveragePrivateMemoryMB) -ForegroundColor White
} else {
    Write-Warning "`nAucune taille de lot n'a pu satisfaire le critÃ¨re d'optimisation '$optimizationReason'."
    # Chercher le meilleur compromis global (comme dans la version prÃ©cÃ©dente) peut Ãªtre utile ici
    $bestCompromise = $sortedResults | Where-Object { $_.AverageExecutionTimeS -ge 0 } | Sort-Object -Property SuccessRatePercent -Descending | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
     if($bestCompromise) {
         Write-Host "ðŸ’¡ Suggestion (meilleur compromis succÃ¨s/vitesse trouvÃ©):" -ForegroundColor Yellow
         Write-Host ("  Taille de lot : {0} (SuccÃ¨s: {1:F1}%)" -f $bestCompromise.BatchSize, $bestCompromise.SuccessRatePercent) -ForegroundColor Yellow
         Write-Host ("  Temps moyen   : {0:F3} s" -f $bestCompromise.AverageExecutionTimeS) -ForegroundColor Yellow
         Write-Host ("  MÃ©moire PrivÃ©e: {0:F2} MB" -f $bestCompromise.AveragePrivateMemoryMB) -ForegroundColor Yellow
    } else {
         Write-Warning "Aucune exÃ©cution n'a fourni de rÃ©sultats valides."
    }
}

# Enregistrer les rÃ©sultats agrÃ©gÃ©s en JSON
$resultsJsonFileName = "BatchSizeOptimization_Summary_$($BatchSizeParameterName).json" # Nom simplifiÃ©
$resultsJsonPath = Join-Path -Path $optimizationRunOutputPath -ChildPath $resultsJsonFileName
try {
    # Exclure ErrorMessage dÃ©taillÃ© du JSON principal pour lisibilitÃ© si nÃ©cessaire
    $resultsForJson = $sortedResults #| Select-Object * -ExcludeProperty ErrorMessage # DÃ©commenter pour exclure
    ConvertTo-Json -InputObject $resultsForJson -Depth 5 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`nðŸ“Š RÃ©sumÃ© complet de l'optimisation enregistrÃ© (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement du rÃ©sumÃ© JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# GÃ©nÃ©rer le rapport HTML comparatif si demandÃ©
if ($GenerateReport) {
    if ($sortedResults.Count -gt 0) {
        $reportHtmlFileName = "BatchSizeOptimization_Report_$($BatchSizeParameterName).html" # Nom simplifiÃ©
        $reportHtmlPath = Join-Path -Path $optimizationRunOutputPath -ChildPath $reportHtmlFileName
        $reportParams = @{
            AllBatchResults    = $sortedResults # Passer les rÃ©sultats triÃ©s
            ReportPath         = $reportHtmlPath
            OptimalBatchInfo   = $optimalBatchInfo # Peut Ãªtre $null
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
        Write-Warning "GÃ©nÃ©ration du rapport HTML annulÃ©e car aucun rÃ©sultat n'a Ã©tÃ© collectÃ©."
    }
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Optimisation Taille de Lot TerminÃ©e ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "DurÃ©e totale du script d'optimisation : $($totalDuration.ToString('g'))"

#endregion

# Retourner le tableau des rÃ©sultats triÃ©s par taille de lot
return $sortedResults