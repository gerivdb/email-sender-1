#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise la taille de lot pour un script parallèle en testant différentes valeurs et critères.
.DESCRIPTION
    Ce script orchestre l'exécution d'un script de benchmark parallèle (`Test-ParallelPerformance.ps1`)
    avec différentes tailles de lot spécifiées (`BatchSizes`). Pour chaque taille, il exécute le benchmark
    plusieurs fois (`Iterations`) pour collecter des métriques de performance fiables (temps, CPU, mémoire, taux de succès).
    Il analyse ensuite ces résultats agrégés pour identifier la taille de lot "optimale" selon un critère
    configurable (`OptimizationMetric`).
    Finalement, il génère un rapport comparatif détaillé au format JSON et, optionnellement, un rapport HTML
    interactif avec graphiques et recommandations dans un sous-répertoire de sortie unique.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell à exécuter par `Test-ParallelPerformance.ps1`.
    Ce bloc doit typiquement appeler le script parallèle cible en utilisant le splatting
    avec les paramètres reçus. Exemple:
    {
        param($params) # Reçoit la fusion de BaseParameters et du paramètre de lot courant
        & "C:\Path\To\Your\ParallelScript.ps1" @params
    }
.PARAMETER BaseParameters
    Table de hachage contenant les paramètres constants à passer au ScriptBlock (et donc au script cible)
    pour chaque test. Ces paramètres ne varient pas avec la taille du lot.
.PARAMETER BatchSizeParameterName
    Nom exact (sensible à la casse) du paramètre dans le script cible (via ScriptBlock/BaseParameters)
    qui contrôle la taille du lot. Ex: 'BatchSize', 'ChunkSize', 'ItemsPerBatch'.
    Ce script injectera/modifiera cette clé dans la table de hachage passée au ScriptBlock.
.PARAMETER BatchSizes
    Tableau d'entiers représentant les différentes tailles de lot à évaluer.
    Exemple: @(10, 20, 50, 100, 200)
.PARAMETER OutputPath
    Chemin du répertoire racine où les résultats seront stockés. Un sous-répertoire unique
    (basé sur le timestamp) sera créé pour contenir les sorties de cette exécution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un répertoire contenant des données de test pré-existantes.
    Si fourni et valide, ce chemin sera utilisé (et potentiellement injecté dans les BaseParameters
    via TestDataTargetParameterName). Sinon, si 'New-TestData.ps1' est trouvé, il sera utilisé
    pour générer des données dans le sous-répertoire de sortie.
.PARAMETER TestDataTargetParameterName
    [Optionnel] Nom du paramètre dans `BaseParameters` qui doit recevoir le chemin des données de test
    (`$actualTestDataPath`) si des données sont utilisées/générées. Utile si le script cible
    n'utilise pas 'ScriptsPath' pour ses données d'entrée.
    Défaut: 'ScriptsPath'.
.PARAMETER Iterations
    Nombre de fois où `Test-ParallelPerformance.ps1` doit exécuter le `ScriptBlock` pour *chaque*
    taille de lot afin de calculer des moyennes et statistiques fiables. Défaut: 3.
.PARAMETER OptimizationMetric
    [Optionnel] Critère utilisé pour déterminer la taille de lot "optimale" parmi les résultats.
    Options:
      - 'FastestSuccessful' (Défaut): Sélectionne la taille de lot la plus rapide (temps écoulé moyen le plus bas) parmi celles ayant atteint 100% de succès.
      - 'LowestMemorySuccessful': Sélectionne la taille de lot avec la consommation mémoire privée moyenne la plus basse parmi celles ayant atteint 100% de succès.
      - 'BestSuccessRate': Sélectionne la taille de lot avec le taux de succès le plus élevé. En cas d'égalité, choisit la plus rapide parmi elles. Utile si aucune n'atteint 100%.
.PARAMETER GenerateReport
    Si spécifié ($true), génère un rapport HTML comparatif détaillé incluant des graphiques interactifs
    et des recommandations basées sur le critère d'optimisation.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la génération de données via 'New-TestData.ps1' est applicable, force la suppression
    et la regénération des données même si elles existent déjà dans le répertoire de sortie.
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
    # Optimisation pour un script de traitement, focus sur la mémoire, avec génération de données
    $targetScript = ".\scripts\processing\Process-Data.ps1"
    # Process-Data.ps1 attend les données dans -InputFolder
    $baseParams = @{ MaxWorkers = 4; OutputFolder = "C:\ProcessedData" }
    $batchSizes = 50, 100, 250, 500
    .\Optimize-ParallelBatchSize.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -BaseParameters $baseParams `
        -BatchSizeParameterName "ItemsPerBatch" `
        -BatchSizes $batchSizes `
        -OutputPath "C:\PerfReports\MemOpt" `
        -TestDataTargetParameterName "InputFolder" ` # Injecter le chemin généré ici
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration `
        -OptimizationMetric LowestMemorySuccessful

.NOTES
    Auteur     : Votre Nom/Équipe
    Version    : 2.1
    Date       : 2023-10-27
    Dépendances:
        - Test-ParallelPerformance.ps1 (Requis, doit être dans le même répertoire ou chemin connu)
        - New-TestData.ps1 (Optionnel, pour génération de données, même répertoire)
        - Chart.js (via CDN pour le rapport HTML)

    Important:
    - Le script `Test-ParallelPerformance.ps1` est essentiel et doit retourner un PSCustomObject avec les métriques attendues (AverageExecutionTimeS, SuccessRatePercent, etc.).
    - Le `-ScriptBlock` doit être correctement formulé pour recevoir les paramètres fusionnés (`BaseParameters` + le paramètre de lot dynamique) et les passer au script cible via splatting (`@params` ou `@p`).
    - La gestion des données de test (`-TestDataPath`, `-TestDataTargetParameterName`, `-ForceTestDataGeneration`) permet une certaine flexibilité mais dépend de la capacité du script cible à utiliser le chemin fourni.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell qui exécute le script parallèle à tester, acceptant les paramètres via splatting.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $false, HelpMessage = "Paramètres constants passés au ScriptBlock pour chaque test.")]
    [hashtable]$BaseParameters = @{},

    [Parameter(Mandatory = $true, HelpMessage = "Nom du paramètre dans le script cible contrôlant la taille du lot.")]
    [ValidateNotNullOrEmpty()]
    [string]$BatchSizeParameterName,

    [Parameter(Mandatory = $true, HelpMessage = "Tableau des tailles de lot entières à évaluer.")]
    [ValidateNotNullOrEmpty()]
    [int[]]$BatchSizes,

    [Parameter(Mandatory = $true, HelpMessage = "Répertoire racine où le sous-dossier des résultats sera créé.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les données de test pré-existantes.")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nom du paramètre dans BaseParameters où injecter le chemin des données. Défaut: 'ScriptsPath'.")]
    [string]$TestDataTargetParameterName = 'ScriptsPath',

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'itérations du benchmark par taille de lot.")]
    [ValidateRange(1, 100)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false, HelpMessage = "Critère pour déterminer la taille de lot optimale.")]
    [ValidateSet('FastestSuccessful', 'LowestMemorySuccessful', 'BestSuccessRate')]
    [string]$OptimizationMetric = 'FastestSuccessful',

    [Parameter(Mandatory = $false, HelpMessage = "Générer un rapport HTML comparatif détaillé.")]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false, HelpMessage = "Forcer la génération de données de test via New-TestData.ps1 (si applicable).")]
    [switch]$ForceTestDataGeneration
)

#region Global Variables and Helper Functions
$startTimestamp = Get-Date

# --- Helper pour la validation des chemins et création de dossiers ---
function New-DirectoryIfNotExists {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([string]$Path, [string]$Purpose)
    $resolvedPath = $null
    try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if ($resolvedPath -and (Test-Path $resolvedPath -PathType Container)) {
            Write-Verbose "Répertoire existant trouvé pour '$Purpose': $resolvedPath"
            return $resolvedPath.Path
        } elseif ($resolvedPath) {
            Write-Error "Le chemin '$Path' pour '$Purpose' existe mais n'est pas un répertoire."
            return $null
        } else {
            # Le chemin n'existe pas, tenter de le créer
            if ($PSCmdlet.ShouldProcess($Path, "Créer le répertoire pour '$Purpose'")) {
                $created = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
                Write-Verbose "Répertoire créé pour '$Purpose': $($created.FullName)"
                return $created.FullName
            } else {
                Write-Warning "Création du répertoire pour '$Purpose' annulée."
                return $null
            }
        }
    } catch {
        Write-Error "Impossible de créer ou valider le répertoire pour '$Purpose' à '$Path'. Erreur: $($_.Exception.Message)"
        return $null
    }
}

# --- Helper pour préparer les données JS pour le rapport HTML ---
function ConvertTo-JavaScriptData {
    param([object]$Data)
    return ($Data | ConvertTo-Json -Compress -Depth 5)
}

#endregion

#region Initialisation et Validation Strictes
Write-Host "=== Initialisation Optimisation Taille de Lot ($BatchSizeParameterName) ===" -ForegroundColor White -BackgroundColor DarkBlue

# 1. Valider le script de benchmark dépendant
$benchmarkScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ParallelPerformance.ps1"
if (-not (Test-Path $benchmarkScriptPath -PathType Leaf)) {
    Write-Error "Script dépendant crucial 'Test-ParallelPerformance.ps1' introuvable dans '$PSScriptRoot'. Ce script est requis pour exécuter les mesures. Arrêt."
    return # Arrêt immédiat
}
Write-Verbose "Script de benchmark dépendant trouvé : $benchmarkScriptPath"

# 2. Créer le répertoire de sortie racine si nécessaire
$resolvedOutputPath = New-DirectoryIfNotExists -Path $OutputPath -Purpose "Résultats Globaux"
if (-not $resolvedOutputPath) { return }

# 3. Créer le sous-répertoire unique pour cette exécution
$timestamp = $startTimestamp.ToString('yyyyMMddHHmmss')
$optimizationRunOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath "BatchOpt_$(($BatchSizeParameterName -replace '[^a-zA-Z0-9]','_'))_$timestamp"
$optimizationRunOutputPath = New-DirectoryIfNotExists -Path $optimizationRunOutputPath -Purpose "Résultats de cette Exécution d'Optimisation"
if (-not $optimizationRunOutputPath) { return }

Write-Host "Répertoire de sortie pour cette exécution : $optimizationRunOutputPath" -ForegroundColor Green

# 4. Gestion des données de test
$actualTestDataPath = $null # Chemin effectif qui sera utilisé/injecté
$testDataStatus = "Non applicable"

# 4a. Vérifier le chemin explicite fourni
if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des données fournies : $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'est pas valide. Tentative de génération si New-TestData.ps1 existe."
    }
}

# 4b. Tenter la génération si pas de chemin valide fourni OU si on force la génération
if (-not $actualTestDataPath -or $ForceTestDataGeneration) {
    $testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
    if (Test-Path $testDataScriptPath -PathType Leaf) {
        $targetGeneratedDataPath = Join-Path -Path $optimizationRunOutputPath -ChildPath "generated_test_data"
        $generate = $false
        if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
            $generate = $true
            Write-Verbose "Le répertoire de données générées '$targetGeneratedDataPath' n'existe pas, génération planifiée."
        } elseif ($ForceTestDataGeneration) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et Regénérer les données de test (option -ForceTestDataGeneration)")) {
                Write-Verbose "Forçage de la regénération des données de test."
                try { Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop } catch { Write-Warning "Impossible de supprimer l'ancien dossier de données '$targetGeneratedDataPath': $($_.Exception.Message)" }
                $generate = $true
            } else {
                Write-Warning "Regénération des données de test annulée par l'utilisateur. Utilisation des données existantes."
                $actualTestDataPath = $targetGeneratedDataPath # Utiliser l'existant si annulation
                $testDataStatus = "Utilisation des données existantes (regénération annulée): $actualTestDataPath"
            }
        } else {
            # Le dossier existe et on ne force pas -> utiliser l'existant
            $actualTestDataPath = $targetGeneratedDataPath
            $testDataStatus = "Réutilisation des données précédemment générées: $actualTestDataPath"
            Write-Verbose $testDataStatus
        }

        if ($generate) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Générer les données de test via $testDataScriptPath")) {
                Write-Host "Génération des données de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
                try {
                    $genParams = @{ OutputPath = $targetGeneratedDataPath; ErrorAction = 'Stop' }
                    if ($ForceTestDataGeneration) { $genParams.Force = $true }
                    $generatedPath = & $testDataScriptPath @genParams

                    if ($generatedPath -and (Test-Path $generatedPath -PathType Container)) {
                        $actualTestDataPath = $generatedPath # Mise à jour du chemin effectif
                        $testDataStatus = "Données générées avec succès: $actualTestDataPath"
                        Write-Host $testDataStatus -ForegroundColor Green
                    } else {
                        Write-Error "La génération des données de test via New-TestData.ps1 a échoué ou n'a pas retourné de chemin valide."
                        $testDataStatus = "Échec de la génération."
                        $actualTestDataPath = $null # Assurer qu'on n'utilise pas un chemin invalide
                    }
                } catch {
                    Write-Error "Erreur critique lors de l'appel à New-TestData.ps1: $($_.Exception.Message)"
                    $testDataStatus = "Échec critique de la génération."
                    $actualTestDataPath = $null
                }
            } else {
                Write-Warning "Génération des données de test annulée par l'utilisateur."
                $testDataStatus = "Génération annulée."
                # Si le dossier existait avant l'annulation, s'assurer qu'on l'utilise
                if ($actualTestDataPath -eq $targetGeneratedDataPath) { $testDataStatus += " Utilisation des données pré-existantes." }
                else { $actualTestDataPath = $null } # Si on a annulé la création initiale
            }
        }
    } elseif (-not $actualTestDataPath) { # Si pas de chemin explicite et pas de New-TestData.ps1
        $testDataStatus = "Non requis/géré (TestDataPath non fourni/valide et New-TestData.ps1 non trouvé)."
        Write-Verbose $testDataStatus
    }
}

# 4c. Injecter le chemin des données effectif dans BaseParameters si applicable
if ($actualTestDataPath -and $BaseParameters) {
    if ($BaseParameters.ContainsKey($TestDataTargetParameterName)) {
        Write-Verbose "Mise à jour de BaseParameters['$TestDataTargetParameterName'] avec '$actualTestDataPath'"
        $BaseParameters[$TestDataTargetParameterName] = $actualTestDataPath
    } else {
        Write-Warning "Le chemin des données '$actualTestDataPath' a été déterminé, mais le paramètre cible '$TestDataTargetParameterName' n'existe pas dans BaseParameters. Le ScriptBlock devra gérer l'accès aux données autrement."
    }
}

# 5. Afficher le contexte d'exécution
Write-Host "Contexte d'exécution :"
Write-Host "  - Script de Benchmark : $benchmarkScriptPath"
Write-Host "  - Tailles de Lot      : $($BatchSizes -join ', ')"
Write-Host "  - Itérations par Taille: $Iterations"
Write-Host "  - Critère Optimisation: $OptimizationMetric"
Write-Host "  - Génération Rapport HTML: $($GenerateReport.IsPresent)"
Write-Host "  - Statut Données Test : $testDataStatus"
Write-Verbose "  - Paramètres de Base (-BaseParameters):"
Write-Verbose ($BaseParameters | Out-String)

Write-Verbose "Validation et Initialisation terminées."
#endregion

#region Fonction de Génération du Rapport HTML (Adaptée)

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

    Write-Host "Génération du rapport HTML comparatif : $ReportPath" -ForegroundColor Cyan

    $validResults = $AllBatchResults | Where-Object { $null -ne $_ -and $null -ne $_.PSObject.Properties['AverageExecutionTimeS'] -and $_.AverageExecutionTimeS -ge 0 }
    if ($validResults.Count -eq 0) {
        Write-Warning "Aucune donnée de résultat valide pour générer les graphiques du rapport HTML."
        # Potentiellement créer un rapport minimal ici
        return
    }

    # Trier les résultats valides par taille de lot pour les graphiques/tableaux
    $sortedResults = $validResults | Sort-Object BatchSize

    # Préparer les données pour JS
    $jsLabels = ConvertTo-JavaScriptData ($sortedResults.BatchSize)
    $jsAvgTimes = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageExecutionTimeS, 3) })
    $jsAvgCpu = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageProcessorTimeS, 3) })
    $jsAvgWS = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AverageWorkingSetMB, 2) })
    $jsAvgPM = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.AveragePrivateMemoryMB, 2) })
    $jsSuccessRates = ConvertTo-JavaScriptData ($sortedResults | ForEach-Object { [Math]::Round($_.SuccessRatePercent, 1) })

    $paramsHtml = "<i>Aucun paramètre de base spécifié</i>"
    if ($BaseParametersUsed -and $BaseParametersUsed.Count -gt 0) {
        $paramsHtml = ($BaseParametersUsed.GetEnumerator() | ForEach-Object { "<li><strong>$($_.Name):</strong> <span class='param-value'>$($_.Value | Out-String -Width 100)</span></li>" }) -join ""
        $paramsHtml = "<ul>$paramsHtml</ul>"
    }
    $dataInfoHtml = if (-not [string]::IsNullOrEmpty($TestDataInfo)) { "<p><span class='metric-label'>Statut Données Test:</span> $TestDataInfo</p>" } else { "" }

    # Section Optimale
    $optimalSectionHtml = ""
    if ($OptimalBatchInfo) {
        $optimalSectionHtml = @"
<div class="section optimal" id="optimal-result">
    <h2>🏆 Taille de Lot Recommandée (Critère: $OptimizationReason)</h2>
    <p><span class="metric-label">Taille de Lot Optimale:</span> <span class="optimal-value">$($OptimalBatchInfo.BatchSize)</span></p>
    <p><span class="metric-label tooltip">Temps Moyen Écoulé:<span class="tooltiptext">Durée totale moyenne pour cette taille de lot. Plus bas est mieux.</span></span> $($OptimalBatchInfo.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label tooltip">Temps CPU Moyen:<span class="tooltiptext">Temps processeur moyen consommé.</span></span> $($OptimalBatchInfo.AverageProcessorTimeS.ToString('F3')) s</p>
    <p><span class="metric-label tooltip">Working Set Moyen:<span class="tooltiptext">Mémoire physique moyenne utilisée.</span></span> $($OptimalBatchInfo.AverageWorkingSetMB.ToString('F2')) MB</p>
    <p><span class="metric-label tooltip">Mémoire Privée Moyenne:<span class="tooltiptext">Mémoire non partagée moyenne allouée. Indicateur clé.</span></span> $($OptimalBatchInfo.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Taux de Succès:</span> $($OptimalBatchInfo.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    } else {
        $optimalSectionHtml = @"
<div class="section warning" id="optimal-result">
    <h2>⚠️ Taille de Lot Optimale Non Trouvée</h2>
    <p>Aucune taille de lot n'a satisfait le critère d'optimisation '$OptimizationReason' (par exemple, aucune n'a atteint 100% de succès si requis).</p>
    <p>Consultez les résultats détaillés et les graphiques pour identifier le meilleur compromis pour vos besoins.</p>
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
        $recoItems += "<li>La taille de lot <strong>$($fastestOverall.BatchSize)</strong> était la plus rapide globalement ({$($fastestOverall.AverageExecutionTimeS.ToString('F3'))}s) mais n'a peut-être pas atteint 100% de succès ({$($fastestOverall.SuccessRatePercent.ToString('F1'))}%).</li>"
    }
    if ($lowestMemOverall -and $OptimalBatchInfo -and $lowestMemOverall.BatchSize -ne $OptimalBatchInfo.BatchSize) {
         $recoItems += "<li>La taille de lot <strong>$($lowestMemOverall.BatchSize)</strong> utilisait le moins de mémoire privée ({$($lowestMemOverall.AveragePrivateMemoryMB.ToString('F2'))}MB) avec un temps moyen de {$($lowestMemOverall.AverageExecutionTimeS.ToString('F3'))}s et {$($lowestMemOverall.SuccessRatePercent.ToString('F1'))}% de succès.</li>"
    }
     if ($bestSuccessOverall -and $OptimalBatchInfo -and $bestSuccessOverall.BatchSize -ne $OptimalBatchInfo.BatchSize -and $bestSuccessOverall.SuccessRatePercent -gt $OptimalBatchInfo.SuccessRatePercent) {
         $recoItems += "<li>La taille de lot <strong>$($bestSuccessOverall.BatchSize)</strong> avait le meilleur taux de succès ({$($bestSuccessOverall.SuccessRatePercent.ToString('F1'))}%) avec un temps moyen de {$($bestSuccessOverall.AverageExecutionTimeS.ToString('F3'))}s.</li>"
    }

    if ($recoItems.Count -gt 0) {
        $recommendationsHtml = @"
<div class="section" id="recommendations">
    <h3>Autres Observations Pertinentes</h3>
    <ul>$($recoItems -join '')</ul>
</div>
"@
    }

    # Table des détails (générée via boucle pour meilleur contrôle)
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
    <thead><tr><th>Taille Lot</th><th>Taux Succès (%)</th><th>Temps Moyen (s)</th><th>Temps Min (s)</th><th>Temps Max (s)</th><th>CPU Moyen (s)</th><th>WS Moyen (MB)</th><th>PM Moyen (MB)</th></tr></thead>
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
    <style>/* CSS Similaire à Test-ParallelPerformance */
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
        <h2>Contexte de l'Exécution</h2>
        <p><span class="metric-label">Généré le:</span> $(Get-Date -Format "yyyy-MM-dd 'à' HH:mm:ss")</p>
        <p><span class="metric-label">Itérations par Taille:</span> $IterationsPerBatch</p>
        <p><span class="metric-label">Critère d'Optimisation:</span> $OptimizationMetric</p>
        $dataInfoHtml
        <p><span class="metric-label">Répertoire des Résultats:</span> <code>$OutputDirectory</code></p>
        <h3>Paramètres de Base Utilisés :</h3>
        $paramsHtml
    </div>

    $optimalSectionHtml
    $recommendationsHtml

    <div class="section" id="detailed-results">
        <h2>Résultats Comparatifs Détaillés par Taille de Lot</h2>
        $detailsTableHtml
        <p class="notes"><i>Les métriques sont moyennées sur $IterationsPerBatch exécutions pour chaque taille de lot.</i></p>
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
        { label: 'Temps Écoulé Moyen (s)', data: $jsAvgTimes, borderColor: 'rgb(220, 53, 69)', backgroundColor: 'rgba(220, 53, 69, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 },
        { label: 'Temps CPU Moyen (s)', data: $jsAvgCpu, borderColor: 'rgb(13, 110, 253)', backgroundColor: 'rgba(13, 110, 253, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Performance Temps vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, yTime: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'line', data: { labels: batchSizeLabels, datasets: [
        { label: 'Working Set Moyen (MB)', data: $jsAvgWS, borderColor: 'rgb(25, 135, 84)', backgroundColor: 'rgba(25, 135, 84, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 },
        { label: 'Mémoire Privée Moyenne (MB)', data: $jsAvgPM, borderColor: 'rgb(108, 117, 125)', backgroundColor: 'rgba(108, 117, 125, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Utilisation Mémoire vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, yMemory: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'MB'}}} }
    });

    // Success Rate Chart
    createChart('successRateChart', { type: 'bar', data: { labels: batchSizeLabels, datasets: [{ label: 'Taux de Succès (%)', data: $jsSuccessRates, backgroundColor: 'rgba(255, 193, 7, 0.7)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1 }] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Taux de Succès vs Taille de Lot'} }, scales: { ...commonChartOptions.scales, y: { ...commonChartOptions.scales.y, min: 0, max: 100, title: { ...commonChartOptions.scales.y.title, text: '%' } } } }
    });
</script>
</div> <!-- /container -->
</body>
</html>
"@

    # Sauvegarder le rapport HTML
    try {
        $htmlContent | Out-File -FilePath $ReportPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML comparatif généré avec succès : $ReportPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur critique lors de la sauvegarde du rapport HTML '$ReportPath': $($_.Exception.Message)"
        # Ne pas arrêter le script principal pour une erreur de rapport, juste notifier.
    }
}

#endregion

#region Exécution Principale du Benchmarking

Write-Host "`n=== Démarrage des Tests par Taille de Lot ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan
Write-Host "Critère d'Optimisation : $OptimizationMetric"

$allBatchSummaryResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalBatchSizes = $BatchSizes.Count
$currentBatchIndex = 0

# Boucle sur chaque taille de lot à tester
foreach ($batchSize in $BatchSizes) {
    $currentBatchIndex++
    $progressParams = @{
        Activity = "Optimisation Taille de Lot: $BatchSizeParameterName"
        Status   = "Test BatchSize $batchSize ($currentBatchIndex/$totalBatchSizes)"
        PercentComplete = (($currentBatchIndex -1) / $totalBatchSizes) * 100 # Start at 0%
        CurrentOperation = "Préparation..."
    }
    Write-Progress @progressParams

    Write-Host "`n--- Test BatchSize = $batchSize ($currentBatchIndex/$totalBatchSizes) ---" -ForegroundColor Yellow

    # Préparer les paramètres spécifiques pour cette taille de lot
    $currentCombinedParameters = $BaseParameters.Clone() # Cloner pour isoler
    try {
        $currentCombinedParameters[$BatchSizeParameterName] = $batchSize
    } catch {
         Write-Error "Impossible d'ajouter/modifier le paramètre '$BatchSizeParameterName' dans les paramètres. Vérifiez le nom et la structure de BaseParameters. Erreur: $($_.Exception.Message)"
         # Ajouter un résultat d'échec pour cette taille de lot et continuer
         $allBatchSummaryResults.Add([PSCustomObject]@{ BatchSize=$batchSize; Status='SetupError'; ErrorMessage=$_.Exception.Message; SuccessRatePercent=0; AverageExecutionTimeS=-1; AveragePrivateMemoryMB=-1 })
         continue # Passer à la taille de lot suivante
    }

    Write-Verbose "Paramètres combinés pour le ScriptBlock (BatchSize $batchSize):"
    Write-Verbose ($currentCombinedParameters | Out-String)

    # Nom unique pour le test de performance sous-jacent
    $benchmarkTestName = "BatchSize_$($batchSize)_$(Get-Date -Format 'HHmmssfff')" # Plus de précision pour unicité

    # Paramètres pour Test-ParallelPerformance.ps1
    $benchmarkParams = @{
        ScriptBlock             = $ScriptBlock                # Le bloc qui appelle le script cible
        Parameters              = $currentCombinedParameters   # Params pour le ScriptBlock
        TestName                = $benchmarkTestName          # Nom pour les logs/rapports de CE test
        OutputPath              = $optimizationRunOutputPath  # Sortie DANS le dossier de l'optimisation
        Iterations              = $Iterations                 # Répétitions pour cette taille
        GenerateReport          = $false # Ne pas générer de rapport HTML pour chaque taille, seulement le global
        NoGarbageCollection     = $true # Optimise-BatchSize ne force pas GC, laisser Test-ParallelPerformance gérer
        ErrorAction             = 'Continue'                  # Capturer les erreurs de Test-ParallelPerformance
    }
    # Note: TestDataPath n'est pas passé directement ici, il est injecté dans $currentCombinedParameters si besoin

    $batchResultSummary = $null
    $benchmarkError = $null # Variable pour stocker les erreurs de l'appel &

    try {
        Write-Progress @progressParams -CurrentOperation "Exécution de Test-ParallelPerformance ($Iterations itérations)..."
        Write-Verbose "Lancement de Test-ParallelPerformance.ps1 pour BatchSize $batchSize..."

        # Exécuter le benchmark et capturer sa sortie (le résumé) et ses erreurs
        $batchResultSummary = & $benchmarkScriptPath @benchmarkParams -ErrorVariable +benchmarkError # '+' pour ajouter aux erreurs existantes

        if ($benchmarkError) {
            Write-Warning "Erreurs non bloquantes lors de l'exécution de Test-ParallelPerformance pour BatchSize $batchSize :"
            $benchmarkError | ForEach-Object { Write-Warning ('    ' + $_.ToString()) }
        }
         Write-Progress @progressParams -CurrentOperation "Benchmark terminé"

    } catch {
        # Erreur critique qui a arrêté Test-ParallelPerformance
        Write-Error "Échec critique lors de l'appel à Test-ParallelPerformance.ps1 pour BatchSize $batchSize. Erreur : $($_.Exception.Message)"
        $benchmarkError = $_ # Sauvegarder l'erreur critique
        # $batchResultSummary restera $null
    }

    # Traiter le résultat (ou l'absence de résultat) du benchmark
    if ($batchResultSummary -is [PSCustomObject] -and $batchResultSummary.PSObject.Properties.Name -contains 'AverageExecutionTimeS') {
        # Résultat valide reçu
        $batchResultSummary | Add-Member -MemberType NoteProperty -Name "BatchSize" -Value $batchSize -Force
        $batchResultSummary | Add-Member -MemberType NoteProperty -Name "Status" -Value "Completed" -Force # Ajouter un statut
        $allBatchSummaryResults.Add($batchResultSummary)
        Write-Host ("Résultat enregistré pour BatchSize {0}: TempsMoyen={1:F3}s, Succès={2:F1}%, MemPrivMoy={3:F2}MB" -f `
            $batchSize, $batchResultSummary.AverageExecutionTimeS,
            $batchResultSummary.SuccessRatePercent, $batchResultSummary.AveragePrivateMemoryMB) -ForegroundColor Green
    } else {
        # Échec de l'exécution ou résultat invalide
        $failureReason = if($benchmarkError) { $benchmarkError[0].ToString() } else { "Test-ParallelPerformance n'a pas retourné un objet de résumé valide." }
        Write-Warning "Le test pour BatchSize $batchSize a échoué ou n'a pas retourné de résumé valide. Raison: $failureReason"
        # Ajouter un résultat d'échec structuré
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
     Write-Progress @progressParams -PercentComplete ($currentBatchIndex / $totalBatchSizes * 100) -CurrentOperation "Terminé"

} # Fin de la boucle foreach ($batchSize in $BatchSizes)

Write-Progress @progressParams -Activity "Optimisation Taille de Lot: $BatchSizeParameterName" -Status "Analyse finale des résultats..." -Completed

#endregion

#region Analyse Finale et Génération des Rapports

Write-Host "`n=== Analyse Finale des Résultats ($($allBatchSummaryResults.Count) tailles testées) ===" -ForegroundColor Cyan

if ($allBatchSummaryResults.Count -eq 0) {
     Write-Warning "Aucun résultat n'a été collecté (probablement interrompu). Impossible d'analyser ou de générer des rapports."
     return $null
}

# Trier les résultats par taille de lot pour affichage cohérent
$sortedResults = $allBatchSummaryResults | Sort-Object BatchSize

# Analyser selon le critère d'optimisation
$optimalBatchInfo = $null
$optimizationReason = "" # Pour le rapport

switch ($OptimizationMetric) {
    'FastestSuccessful' {
        $optimizationReason = "Temps d'exécution le plus bas avec 100% de succès"
        $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
        if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        }
    }
    'LowestMemorySuccessful' {
         $optimizationReason = "Utilisation mémoire privée la plus basse avec 100% de succès"
         $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AveragePrivateMemoryMB -ge 0 }
         if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AveragePrivateMemoryMB | Select-Object -First 1
        }
    }
    'BestSuccessRate' {
        $optimizationReason = "Taux de succès le plus élevé (puis temps d'exécution le plus bas)"
        # Trier d'abord par succès (décroissant), puis par temps (croissant)
        $optimalBatchInfo = $sortedResults | Where-Object {$_.AverageExecutionTimeS -ge 0} | Sort-Object -Property SuccessRatePercent -Descending | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        # Si plusieurs ont le même meilleur taux de succès, Sort-Object par temps choisira le plus rapide.
    }
    default {
        # Ne devrait pas arriver avec ValidateSet, mais par sécurité
        Write-Warning "Critère d'optimisation '$OptimizationMetric' non reconnu. Utilisation de 'FastestSuccessful' par défaut."
        $optimizationReason = "Temps d'exécution le plus bas avec 100% de succès (Défaut)"
        $successfulRuns = $sortedResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
        if ($successfulRuns) {
            $optimalBatchInfo = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
        }
    }
}

# Afficher le résultat de l'optimisation
if ($optimalBatchInfo) {
    Write-Host "`n🏆 Taille de Lot Optimale Identifiée (Critère: $optimizationReason) 🏆" -ForegroundColor Green
    Write-Host ("  Taille de lot  : {0}" -f $optimalBatchInfo.BatchSize) -ForegroundColor White
    Write-Host ("  Temps Moyen    : {0:F3} s" -f $optimalBatchInfo.AverageExecutionTimeS) -ForegroundColor White
    Write-Host ("  Succès         : {0:F1} %" -f $optimalBatchInfo.SuccessRatePercent) -ForegroundColor White
    Write-Host ("  Mémoire Privée : {0:F2} MB" -f $optimalBatchInfo.AveragePrivateMemoryMB) -ForegroundColor White
} else {
    Write-Warning "`nAucune taille de lot n'a pu satisfaire le critère d'optimisation '$optimizationReason'."
    # Chercher le meilleur compromis global (comme dans la version précédente) peut être utile ici
    $bestCompromise = $sortedResults | Where-Object { $_.AverageExecutionTimeS -ge 0 } | Sort-Object -Property SuccessRatePercent -Descending | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
     if($bestCompromise) {
         Write-Host "💡 Suggestion (meilleur compromis succès/vitesse trouvé):" -ForegroundColor Yellow
         Write-Host ("  Taille de lot : {0} (Succès: {1:F1}%)" -f $bestCompromise.BatchSize, $bestCompromise.SuccessRatePercent) -ForegroundColor Yellow
         Write-Host ("  Temps moyen   : {0:F3} s" -f $bestCompromise.AverageExecutionTimeS) -ForegroundColor Yellow
         Write-Host ("  Mémoire Privée: {0:F2} MB" -f $bestCompromise.AveragePrivateMemoryMB) -ForegroundColor Yellow
    } else {
         Write-Warning "Aucune exécution n'a fourni de résultats valides."
    }
}

# Enregistrer les résultats agrégés en JSON
$resultsJsonFileName = "BatchSizeOptimization_Summary_$($BatchSizeParameterName).json" # Nom simplifié
$resultsJsonPath = Join-Path -Path $optimizationRunOutputPath -ChildPath $resultsJsonFileName
try {
    # Exclure ErrorMessage détaillé du JSON principal pour lisibilité si nécessaire
    $resultsForJson = $sortedResults #| Select-Object * -ExcludeProperty ErrorMessage # Décommenter pour exclure
    ConvertTo-Json -InputObject $resultsForJson -Depth 5 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`n📊 Résumé complet de l'optimisation enregistré (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement du résumé JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# Générer le rapport HTML comparatif si demandé
if ($GenerateReport) {
    if ($sortedResults.Count -gt 0) {
        $reportHtmlFileName = "BatchSizeOptimization_Report_$($BatchSizeParameterName).html" # Nom simplifié
        $reportHtmlPath = Join-Path -Path $optimizationRunOutputPath -ChildPath $reportHtmlFileName
        $reportParams = @{
            AllBatchResults    = $sortedResults # Passer les résultats triés
            ReportPath         = $reportHtmlPath
            OptimalBatchInfo   = $optimalBatchInfo # Peut être $null
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
        Write-Warning "Génération du rapport HTML annulée car aucun résultat n'a été collecté."
    }
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Optimisation Taille de Lot Terminée ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Durée totale du script d'optimisation : $($totalDuration.ToString('g'))"

#endregion

# Retourner le tableau des résultats triés par taille de lot
return $sortedResults