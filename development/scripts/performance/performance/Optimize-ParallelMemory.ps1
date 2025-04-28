#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les performances mÃ©moire et temporelles d'un script sous diffÃ©rents scÃ©narios de configuration.
.DESCRIPTION
    Ce script orchestre l'exÃ©cution d'un script de benchmark (`Test-ParallelPerformance.ps1`)
    pour Ã©valuer un `ScriptBlock` cible sous plusieurs configurations dÃ©finies (`OptimizationScenarios`).
    Chaque scÃ©nario spÃ©cifie un ensemble unique de paramÃ¨tres pour le script cible.
    Pour chaque scÃ©nario, le benchmark est exÃ©cutÃ© plusieurs fois (`Iterations`) pour obtenir
    des mÃ©triques fiables (temps, CPU, mÃ©moire, succÃ¨s).
    Le script collecte les rÃ©sumÃ©s de performance de chaque scÃ©nario, les analyse comparativement,
    et gÃ©nÃ¨re un rapport JSON dÃ©taillÃ© ainsi qu'un rapport HTML interactif (si demandÃ©)
    dans un sous-rÃ©pertoire de sortie unique. Il met en Ã©vidence les scÃ©narios les plus performants
    en termes de mÃ©moire privÃ©e et de temps d'exÃ©cution.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell qui exÃ©cute le script cible Ã  Ã©valuer. Doit accepter
    les paramÃ¨tres via splatting. Exemple :
    { param($params) & "C:\Path\To\TargetScript.ps1" @params }
.PARAMETER OptimizationScenarios
    Tableau de tables de hachage. Chaque table de hachage reprÃ©sente un scÃ©nario Ã  tester et doit contenir:
        - Name (String): Un nom unique et descriptif pour le scÃ©nario.
        - Parameters (Hashtable): Les paramÃ¨tres spÃ©cifiques Ã  passer au ScriptBlock pour ce scÃ©nario.
    Exemple:
    @(
        @{ Name = "LowWorkers_SmallBatch"; Parameters = @{ MaxWorkers = 2; BatchSize = 10; InputDir = '...' } },
        @{ Name = "HighWorkers_LargeBatch"; Parameters = @{ MaxWorkers = 8; BatchSize = 100; InputDir = '...' } }
    )
.PARAMETER OutputPath
    Chemin du rÃ©pertoire racine oÃ¹ les rÃ©sultats seront stockÃ©s. Un sous-rÃ©pertoire unique
    (basÃ© sur 'MemoryOpt' + Timestamp) sera crÃ©Ã© pour cette exÃ©cution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un rÃ©pertoire contenant des donnÃ©es de test prÃ©-existantes.
    Si fourni et valide, ce chemin peut Ãªtre injectÃ© dans les paramÃ¨tres des scÃ©narios
    via TestDataTargetParameterName. Sinon, 'New-TestData.ps1' peut Ãªtre utilisÃ© pour gÃ©nÃ©rer des donnÃ©es.
.PARAMETER TestDataTargetParameterName
    [Optionnel] Nom du paramÃ¨tre (dans la hashtable `Parameters` de chaque scÃ©nario)
    qui doit recevoir le chemin des donnÃ©es de test effectif (`$actualTestDataPath`).
    Permet d'injecter le chemin des donnÃ©es dans la configuration de chaque scÃ©nario. DÃ©faut: 'ScriptsPath'.
.PARAMETER Iterations
    Nombre de fois oÃ¹ `Test-ParallelPerformance.ps1` doit exÃ©cuter le `ScriptBlock` pour *chaque*
    scÃ©nario afin de calculer des moyennes et statistiques fiables. DÃ©faut: 3.
.PARAMETER GenerateReport
    Si spÃ©cifiÃ© ($true), gÃ©nÃ¨re un rapport HTML comparatif dÃ©taillÃ© pour les scÃ©narios,
    incluant des graphiques interactifs et des mises en Ã©vidence.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la gÃ©nÃ©ration de donnÃ©es via 'New-TestData.ps1' est applicable, force la suppression
    et la regÃ©nÃ©ration des donnÃ©es mÃªme si elles existent dÃ©jÃ .
.EXAMPLE
    # Comparaison de diffÃ©rents nombres de workers pour Analyze-Scripts.ps1
    $targetScript = ".\development\scripts\analysis\Analyze-Scripts.ps1"
    $scenarios = @(
        @{ Name = "Workers_2"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=2 } },
        @{ Name = "Workers_4"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=4 } },
        @{ Name = "Workers_8"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=8 } }
    )
    .\Optimize-ParallelMemory.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -OptimizationScenarios $scenarios `
        -OutputPath "C:\PerfReports\MemOpt_Workers" `
        -TestDataPath "C:\Data" ` # Fourni ici, sera injectÃ© si nÃ©cessaire par TestDataTargetParameterName
        -TestDataTargetParameterName "ScriptsPath" `
        -Iterations 5 `
        -GenerateReport -Verbose

.EXAMPLE
    # Comparaison avec et sans cache, avec gÃ©nÃ©ration de donnÃ©es
    $targetScript = ".\development\scripts\processing\Process-Files.ps1"
    # Process-Files.ps1 utilise -SourceDirectory
    $scenarios = @(
        @{ Name = "NoCache"; Parameters = @{ MaxWorkers=4; UseCache=$false } },
        @{ Name = "WithCache"; Parameters = @{ MaxWorkers=4; UseCache=$true } }
    )
    .\Optimize-ParallelMemory.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -OptimizationScenarios $scenarios `
        -OutputPath "C:\PerfReports\MemOpt_Cache" `
        -TestDataTargetParameterName "SourceDirectory" ` # Injecter le chemin gÃ©nÃ©rÃ© ici
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration

.NOTES
    Auteur     : Votre Nom/Ã‰quipe
    Version    : 2.1
    Date       : 2023-10-27
    DÃ©pendances:
        - Test-ParallelPerformance.ps1 (Requis, mÃªme rÃ©pertoire ou chemin connu)
        - New-TestData.ps1 (Optionnel, pour gÃ©nÃ©ration de donnÃ©es, mÃªme rÃ©pertoire)
        - Chart.js (via CDN pour le rapport HTML)

    Structure de Sortie:
    Un sous-rÃ©pertoire unique `MemoryOpt_[Timestamp]` sera crÃ©Ã© dans `OutputPath`.
    Il contiendra :
      - `MemoryOptimization_Summary.json`: DonnÃ©es et rÃ©sumÃ©s pour chaque scÃ©nario.
      - `MemoryOptimization_Report.html`: Rapport HTML comparatif (si -GenerateReport).
      - `generated_test_data/`: DonnÃ©es gÃ©nÃ©rÃ©es (si applicable).
      - Sous-dossiers crÃ©Ã©s par `Test-ParallelPerformance.ps1` pour les logs dÃ©taillÃ©s de chaque scÃ©nario/itÃ©ration.

    Le paramÃ¨tre `-MonitorMemoryDuringRun` de versions prÃ©cÃ©dentes est dÃ©prÃ©ciÃ© car les mÃ©triques
    agrÃ©gÃ©es de `Test-ParallelPerformance.ps1` (notamment AveragePrivateMemoryMB) sont plus fiables
    et suffisantes pour la comparaison entre scÃ©narios.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell qui exÃ©cute le script cible, acceptant les paramÃ¨tres via splatting.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $true, HelpMessage = "Tableau de scÃ©narios Ã  comparer. Chaque scÃ©nario est une hashtable avec 'Name' (string) et 'Parameters' (hashtable).")]
    [ValidateNotNullOrEmpty()]
    [array]$OptimizationScenarios,

    [Parameter(Mandatory = $true, HelpMessage = "RÃ©pertoire racine oÃ¹ le sous-dossier des rÃ©sultats sera crÃ©Ã©.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les donnÃ©es de test prÃ©-existantes.")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nom du paramÃ¨tre dans les Parameters de chaque scÃ©nario oÃ¹ injecter le chemin des donnÃ©es. DÃ©faut: 'ScriptsPath'.")]
    [string]$TestDataTargetParameterName = 'ScriptsPath',

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'itÃ©rations du benchmark par scÃ©nario.")]
    [ValidateRange(1, 100)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false, HelpMessage = "GÃ©nÃ©rer un rapport HTML comparatif dÃ©taillÃ© des scÃ©narios.")]
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
Write-Host "=== Initialisation Optimisation MÃ©moire par ScÃ©narios ===" -ForegroundColor White -BackgroundColor DarkBlue

# 1. Valider le script de benchmark dÃ©pendant
$benchmarkScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ParallelPerformance.ps1"
if (-not (Test-Path $benchmarkScriptPath -PathType Leaf)) {
    Write-Error "Script dÃ©pendant crucial 'Test-ParallelPerformance.ps1' introuvable dans '$PSScriptRoot'. ArrÃªt."
    return
}
Write-Verbose "Script de benchmark dÃ©pendant trouvÃ© : $benchmarkScriptPath"

# 2. Valider la structure des scÃ©narios
if ($OptimizationScenarios.Count -eq 0) {
    Write-Error "Le paramÃ¨tre -OptimizationScenarios ne peut pas Ãªtre vide."
    return
}
foreach ($scenario in $OptimizationScenarios) {
    if (-not ($scenario -is [hashtable]) -or -not $scenario.ContainsKey('Name') -or -not $scenario.ContainsKey('Parameters') -or -not ($scenario.Parameters -is [hashtable])) {
        Write-Error "Structure invalide dÃ©tectÃ©e dans -OptimizationScenarios. Chaque Ã©lÃ©ment doit Ãªtre une hashtable avec les clÃ©s 'Name' (string) et 'Parameters' (hashtable)."
        Write-Error "ScÃ©nario problÃ©matique: $($scenario | Out-String)"
        return
    }
     if ([string]::IsNullOrWhiteSpace($scenario.Name)) {
        Write-Error "La clÃ© 'Name' dans un scÃ©nario ne peut pas Ãªtre vide."
        return
    }
}
$scenarioNames = $OptimizationScenarios.Name
if (($scenarioNames | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
     Write-Error "Les noms de scÃ©narios ('Name') dans -OptimizationScenarios doivent Ãªtre uniques."
     return
}
Write-Verbose "Structure des $($OptimizationScenarios.Count) scÃ©narios validÃ©e."

# 3. CrÃ©er le rÃ©pertoire de sortie racine et le sous-rÃ©pertoire unique
$resolvedOutputPath = New-DirectoryIfNotExists -Path $OutputPath -Purpose "RÃ©sultats Globaux"
if (-not $resolvedOutputPath) { return }

$timestamp = $startTimestamp.ToString('yyyyMMddHHmmss')
$memoryOptRunOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath "MemoryOpt_$timestamp"
$memoryOptRunOutputPath = New-DirectoryIfNotExists -Path $memoryOptRunOutputPath -Purpose "RÃ©sultats de cette ExÃ©cution d'Optimisation"
if (-not $memoryOptRunOutputPath) { return }

Write-Host "RÃ©pertoire de sortie pour cette exÃ©cution : $memoryOptRunOutputPath" -ForegroundColor Green

# 4. Gestion des donnÃ©es de test (similaire aux autres scripts)
$actualTestDataPath = $null
$testDataStatus = "Non applicable"

# 4a. VÃ©rifier le chemin explicite
$actualTestDataPath = $null
$testDataStatus = "Non spÃ©cifiÃ©"

if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des donnÃ©es fournies: $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'est pas valide. Tentative de gÃ©nÃ©ration si New-TestData.ps1 existe."
    }
}

# 4b. Tenter la gÃ©nÃ©ration si nÃ©cessaire/forcÃ©
$testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
$targetGeneratedDataPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath "generated_test_data"
$generate = $false

# VÃ©rifier si nous devons gÃ©nÃ©rer des donnÃ©es de test
if ((-not $actualTestDataPath -or $ForceTestDataGeneration) -and (Test-Path $testDataScriptPath -PathType Leaf)) {
    # DÃ©terminer si nous devons gÃ©nÃ©rer des donnÃ©es
    if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
        $generate = $true
    } elseif ($ForceTestDataGeneration) {
        if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et regÃ©nÃ©rer les donnÃ©es de test")) {
            Write-Verbose "ForÃ§age de la regÃ©nÃ©ration des donnÃ©es de test."
            try {
                Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop
                $generate = $true
            } catch {
                Write-Warning "Impossible de supprimer l'ancien dossier de donnÃ©es '$targetGeneratedDataPath': $($_.Exception.Message)"
            }
        } else {
            Write-Warning "RegÃ©nÃ©ration annulÃ©e. Utilisation des donnÃ©es existantes si possible."
            if (Test-Path $targetGeneratedDataPath -PathType Container) {
                $actualTestDataPath = $targetGeneratedDataPath
                $testDataStatus = "Utilisation des donnÃ©es existantes (regÃ©nÃ©ration annulÃ©e): $actualTestDataPath"
                Write-Verbose $testDataStatus
            } else {
                $testDataStatus = "RegÃ©nÃ©ration annulÃ©e, dossier inexistant."
                Write-Verbose $testDataStatus
            }
        }
    } else {
        # Utiliser les donnÃ©es existantes
        $actualTestDataPath = $targetGeneratedDataPath
        $testDataStatus = "RÃ©utilisation des donnÃ©es prÃ©cÃ©demment gÃ©nÃ©rÃ©es: $actualTestDataPath"
        Write-Verbose $testDataStatus
    }

    # GÃ©nÃ©rer les donnÃ©es si nÃ©cessaire
    if ($generate) {
        if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "GÃ©nÃ©rer les donnÃ©es de test")) {
            Write-Host "GÃ©nÃ©ration des donnÃ©es de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
            try {
                $genParams = @{
                    OutputPath = $targetGeneratedDataPath
                    ErrorAction = 'Stop'
                }

                if ($ForceTestDataGeneration) {
                    $genParams.Add('Force', $true)
                }

                $generatedPath = & $testDataScriptPath @genParams

                if ($generatedPath -and (Test-Path $generatedPath -PathType Container)) {
                    $actualTestDataPath = $generatedPath
                    $testDataStatus = "DonnÃ©es gÃ©nÃ©rÃ©es avec succÃ¨s: $actualTestDataPath"
                    Write-Host $testDataStatus -ForegroundColor Green
                } else {
                    Write-Error "Ã‰chec de New-TestData.ps1."
                    $testDataStatus = "Ã‰chec gÃ©nÃ©ration."
                    $actualTestDataPath = $null
                }
            } catch {
                Write-Error "Erreur critique New-TestData.ps1: $($_.Exception.Message)"
                $testDataStatus = "Ã‰chec critique."
                $actualTestDataPath = $null
            }
        } else {
            Write-Warning "GÃ©nÃ©ration annulÃ©e."
            $testDataStatus = "GÃ©nÃ©ration annulÃ©e."

            if ($actualTestDataPath -eq $targetGeneratedDataPath) {
                $testDataStatus += " Utilisation des donnÃ©es prÃ©-existantes."
            } else {
                $actualTestDataPath = $null
            }

            Write-Verbose $testDataStatus
        }
    }
} elseif (-not $actualTestDataPath) {
    $testDataStatus = "DonnÃ©es de test non requises ou non gÃ©rÃ©es."
    Write-Verbose $testDataStatus
}

# 4c. Injecter le chemin des donnÃ©es dans les paramÃ¨tres des scÃ©narios
if ($actualTestDataPath) {
    Write-Verbose "Injection du chemin de donnÃ©es '$actualTestDataPath' dans les scÃ©narios (paramÃ¨tre cible: '$TestDataTargetParameterName')."
    foreach ($scenario in $OptimizationScenarios) {
        if ($scenario.Parameters.ContainsKey($TestDataTargetParameterName)) {
            Write-Verbose "  -> ScÃ©nario '$($scenario.Name)': Mise Ã  jour de Parameters['$TestDataTargetParameterName']"
            $scenario.Parameters[$TestDataTargetParameterName] = $actualTestDataPath
        } else {
             Write-Verbose "  -> ScÃ©nario '$($scenario.Name)': Le paramÃ¨tre cible '$TestDataTargetParameterName' n'existe pas dans ses Parameters."
             # Optionnel : ajouter le paramÃ¨tre s'il manque ? Pour l'instant, on suppose qu'il doit exister.
             # $scenario.Parameters[$TestDataTargetParameterName] = $actualTestDataPath
        }
    }
} elseif (-not [string]::IsNullOrEmpty($TestDataTargetParameterName)) {
     Write-Verbose "Aucun chemin de donnÃ©es effectif ($actualTestDataPath est vide), l'injection du paramÃ¨tre '$TestDataTargetParameterName' est ignorÃ©e."
}


# 5. Afficher le contexte d'exÃ©cution final
Write-Host "Contexte d'exÃ©cution :" -ForegroundColor Cyan
Write-Host "  - Script Benchmark : $benchmarkScriptPath"
Write-Host "  - ScÃ©narios Ã  Tester: $($scenarioNames -join ', ')"
Write-Host "  - ItÃ©rations par ScÃ©nario: $Iterations"
Write-Host "  - GÃ©nÃ©ration Rapport HTML: $($GenerateReport.IsPresent)"
Write-Host "  - Statut DonnÃ©es Test : $testDataStatus"
Write-Verbose "  - ParamÃ¨tres dÃ©taillÃ©s par scÃ©nario :"
$OptimizationScenarios | ForEach-Object { Write-Verbose "    - Scenario '$($_.Name)': $($_.Parameters | Out-String | Select-Object -Skip 1 | ForEach-Object { '      ' + $_ })" }


Write-Verbose "Validation et Initialisation terminÃ©es."
#endregion

#region Fonction de GÃ©nÃ©ration du Rapport HTML (AdaptÃ©e pour ScÃ©narios)

function New-MemoryOptimizationHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [array]$AllScenarioResults, # Tableau des rÃ©sumÃ©s retournÃ©s par Test-ParallelPerformance pour chaque scÃ©nario
        [Parameter(Mandatory = $true)] [string]$ReportPath,
        [Parameter(Mandatory = $false)] [PSCustomObject]$FastestScenario,
        [Parameter(Mandatory = $false)] [PSCustomObject]$LowestMemoryScenario,
        [Parameter(Mandatory = $false)] [array]$OptimizationScenariosConfig, # La config originale pour afficher les params
        [Parameter(Mandatory = $false)] [int]$IterationsPerScenario,
        [Parameter(Mandatory = $false)] [string]$TestDataInfo,
        [Parameter(Mandatory = $false)] [string]$OutputDirectory
    )

    Write-Host "GÃ©nÃ©ration du rapport HTML de comparaison des scÃ©narios : $ReportPath" -ForegroundColor Cyan

    $validResults = $AllScenarioResults | Where-Object { $null -ne $_ -and $_.PSObject.Properties.ContainsKey('AverageExecutionTimeS') -and $_.AverageExecutionTimeS -ge 0 }
    if ($validResults.Count -eq 0) {
        Write-Warning "Aucune donnÃ©e de rÃ©sultat valide pour gÃ©nÃ©rer le rapport HTML."
        # Potentiellement crÃ©er un rapport minimal ici
        return
    }

    # PrÃ©parer les donnÃ©es pour JS (Labels = Noms des scÃ©narios)
    $jsLabels = ConvertTo-JavaScriptData ($validResults.TestName) # Utiliser le TestName qui contient le nom du scÃ©nario
    $jsAvgTimes = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageExecutionTimeS, 3) })
    $jsAvgCpu = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageProcessorTimeS, 3) })
    $jsAvgWS = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageWorkingSetMB, 2) })
    $jsAvgPM = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AveragePrivateMemoryMB, 2) })
    $jsSuccessRates = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.SuccessRatePercent, 1) })

    # Section de mise en Ã©vidence
    $highlightHtml = ""
    if ($LowestMemoryScenario) {
         $highlightHtml += @"
<div class="section optimal" id="lowest-memory">
    <h2>ðŸ’§ Consommation MÃ©moire Minimale</h2>
    <p><span class="metric-label">ScÃ©nario:</span> <span class="optimal-value">$($LowestMemoryScenario.TestName)</span></p>
    <p><span class="metric-label tooltip">MÃ©moire PrivÃ©e Moyenne:<span class="tooltiptext">MÃ©moire non partagÃ©e moyenne allouÃ©e. Indicateur clÃ©.</span></span> $($LowestMemoryScenario.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Temps Moyen Ã‰coulÃ©:</span> $($LowestMemoryScenario.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label">Taux de SuccÃ¨s:</span> $($LowestMemoryScenario.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    }
    if ($FastestScenario) {
         $highlightHtml += @"
<div class="section optimal" id="fastest">
    <h2>â±ï¸ ExÃ©cution la Plus Rapide</h2>
    <p><span class="metric-label">ScÃ©nario:</span> <span class="optimal-value">$($FastestScenario.TestName)</span></p>
    <p><span class="metric-label tooltip">Temps Moyen Ã‰coulÃ©:<span class="tooltiptext">DurÃ©e totale moyenne pour ce scÃ©nario. Plus bas est mieux.</span></span> $($FastestScenario.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label">MÃ©moire PrivÃ©e Moyenne:</span> $($FastestScenario.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Taux de SuccÃ¨s:</span> $($FastestScenario.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    }
     if (-not $LowestMemoryScenario -and -not $FastestScenario) {
         $highlightHtml = @"
<div class="section warning">
    <h2>âš ï¸ Analyse LimitÃ©e</h2>
    <p>Impossible de dÃ©terminer formellement le scÃ©nario le plus rapide ou celui consommant le moins de mÃ©moire (probablement dÃ» Ã  des Ã©checs ou donnÃ©es manquantes).</p>
</div>
"@
     }


    # Table des dÃ©tails (gÃ©nÃ©rÃ©e via boucle)
    $detailsTableRows = $AllScenarioResults | ForEach-Object {
        $scenarioConfig = $OptimizationScenariosConfig | Where-Object { $_.Name -eq $_.TestName } | Select-Object -First 1
        $paramsForScenarioHtml = "<i>Erreur: Config non trouvÃ©e</i>"
        if($scenarioConfig) {
             $paramsForScenarioHtml = ($scenarioConfig.Parameters.GetEnumerator() | ForEach-Object { "$($_.Name) = $($_.Value)" }) -join '; '
        }

        $avgExecTimeStr = if($_.AverageExecutionTimeS -ge 0) { $_.AverageExecutionTimeS.ToString('F3') } else { 'N/A' }
        $avgCpuStr = if($_.AverageProcessorTimeS -ge 0) { $_.AverageProcessorTimeS.ToString('F3') } else { 'N/A' }
        $avgWsStr = if($_.AverageWorkingSetMB -ge 0) { $_.AverageWorkingSetMB.ToString('F2') } else { 'N/A' }
        $avgPmStr = if($_.AveragePrivateMemoryMB -ge 0) { $_.AveragePrivateMemoryMB.ToString('F2') } else { 'N/A' }
        $statusClass = ""
        if($_.Status -match 'Failed') { $statusClass = "class='status-failed'" } elseif ($_.SuccessRatePercent -eq 100) { $statusClass = "class='status-success'" }

        $errorMessageHtml = if ($_.ErrorMessage) { "<pre class='error-message'>$($_.ErrorMessage -replace '<','<' -replace '>','>')</pre>" } else { '-' }


        @"
        <tr $statusClass>
            <td><strong>$($_.TestName)</strong><br/><small><code class='param-value'>$paramsForScenarioHtml</code></small></td>
            <td class='number'>$($_.SuccessRatePercent.ToString('F1'))</td>
            <td class='number'>$avgExecTimeStr</td>
            <td class='number'>$avgCpuStr</td>
            <td class='number'>$avgWsStr</td>
            <td class='number'>$avgPmStr</td>
            <td>$errorMessageHtml</td>
        </tr>
"@
    }
    $detailsTableHtml = @"
<table class='details-table'>
    <thead><tr><th>ScÃ©nario & ParamÃ¨tres</th><th>Taux SuccÃ¨s (%)</th><th>Temps Moyen (s)</th><th>CPU Moyen (s)</th><th>WS Moyen (MB)</th><th>PM Moyen (MB)</th><th>Message Principal (si Ã©chec)</th></tr></thead>
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
    <title>Rapport Comparaison MÃ©moire/Perf par ScÃ©nario</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
    <style>/* CSS Similaire aux autres rapports */
        :root { --success-color: #28a745; --failure-color: #dc3545; --warning-color: #ffc107; --primary-color: #0056b3; --secondary-color: #007bff; --light-gray: #f8f9fa; --medium-gray: #e9ecef; --dark-gray: #343a40; --border-color: #dee2e6; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; line-height: 1.6; margin: 20px; background-color: var(--light-gray); color: var(--dark-gray); }
        .container { max-width: 1400px; margin: auto; background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 6px 12px rgba(0,0,0,0.1); }
        h1, h2, h3 { color: var(--primary-color); border-bottom: 2px solid var(--border-color); padding-bottom: 10px; margin-top: 30px; margin-bottom: 20px; font-weight: 600; }
        h1 { font-size: 2em; } h2 { font-size: 1.6em; } h3 { font-size: 1.3em; border-bottom: none; color: var(--secondary-color); }
        .section { background-color: var(--light-gray); padding: 20px; border: 1px solid var(--medium-gray); border-radius: 6px; margin-bottom: 25px; }
        .optimal { border-left: 6px solid var(--success-color); background-color: #e9f7ef; }
        .warning { border-left: 6px solid var(--warning-color); background-color: #fff8e1; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 0.95em; table-layout: auto; } /* Auto layout for scenario params */
        th, td { padding: 12px 15px; text-align: left; border: 1px solid var(--border-color); vertical-align: top; word-wrap: break-word; }
        th { background-color: var(--secondary-color); color: white; font-weight: 600; white-space: normal; }
        tr:nth-child(even) { background-color: #ffffff; } tr:hover { background-color: var(--medium-gray); }
        .details-table td, .details-table th { vertical-align: middle; }
        .details-table .number { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
        .metric-label { font-weight: 600; color: var(--dark-gray); display: inline-block; min-width: 190px;}
        .chart-container { width: 100%; max-width: 900px; height: 450px; margin: 40px auto; border: 1px solid var(--border-color); padding: 20px; border-radius: 6px; background: white; box-shadow: 0 4px 8px rgba(0,0,0,0.05); }
        ul { padding-left: 20px; margin-top: 5px; } li { margin-bottom: 8px; }
        .param-value, code { font-family: 'Consolas', 'Menlo', 'Courier New', monospace; background-color: var(--medium-gray); padding: 3px 6px; border-radius: 4px; font-size: 0.9em; border: 1px solid #ced4da; display: inline-block; max-width: 95%; overflow-x: auto; vertical-align: middle; }
        .optimal-value { font-weight: bold; color: var(--success-color); font-size: 1.1em; }
        .tooltip { position: relative; display: inline-block; border-bottom: 1px dotted black; cursor: help; }
        .tooltip .tooltiptext { visibility: hidden; width: 250px; background-color: #333; color: #fff; text-align: center; border-radius: 6px; padding: 8px; position: absolute; z-index: 1; bottom: 130%; left: 50%; margin-left: -125px; opacity: 0; transition: opacity 0.3s; font-size: 0.9em; }
        .tooltip:hover .tooltiptext { visibility: visible; opacity: 1; }
        pre { background-color: #eee; padding: 10px; border-radius: 4px; font-size: 0.85em; white-space: pre-wrap; word-wrap: break-word; max-height: 100px; overflow-y: auto; border: 1px solid #ccc; margin-top: 5px; }
        .error-message { color: var(--failure-color); font-weight: 500; }
        .status-failed td { background-color: #fdeeee !important; }
        .status-success td { background-color: #e9f7ef !important; }
        .notes { font-size: 0.9em; color: #555; margin-top: 10px; }
    </style>
</head>
<body>
<div class="container">
    <h1>Rapport Comparaison MÃ©moire/Performance par ScÃ©nario</h1>
    <div class="section" id="context">
        <h2>Contexte de l'ExÃ©cution</h2>
        <p><span class="metric-label">GÃ©nÃ©rÃ© le:</span> $(Get-Date -Format "yyyy-MM-dd 'Ã ' HH:mm:ss")</p>
        <p><span class="metric-label">Nombre de ScÃ©narios TestÃ©s:</span> $($AllScenarioResults.Count)</p>
        <p><span class="metric-label">ItÃ©rations par ScÃ©nario:</span> $IterationsPerScenario</p>
        <p><span class="metric-label">Statut DonnÃ©es Test:</span> $TestDataInfo</p>
        <p><span class="metric-label">RÃ©pertoire des RÃ©sultats:</span> <code>$OutputDirectory</code></p>
    </div>

    $highlightHtml

    <div class="section" id="detailed-results">
        <h2>RÃ©sultats Comparatifs DÃ©taillÃ©s par ScÃ©nario</h2>
        $detailsTableHtml
        <p class="notes"><i>Les mÃ©triques sont moyennÃ©es sur $IterationsPerScenario exÃ©cutions pour chaque scÃ©nario.</i></p>
    </div>

    <div class="section" id="charts">
        <h2>Graphiques Comparatifs des ScÃ©narios</h2>
        <div class="chart-container"><canvas id="timeChart"></canvas></div>
        <div class="chart-container"><canvas id="memoryChart"></canvas></div>
        <div class="chart-container"><canvas id="successRateChart"></canvas></div>
    </div>
<script>
    const scenarioLabels = $jsLabels;
    const commonChartOptions = { /* Options communes identiques Ã  Optimize-ParallelBatchSize */
        scales: { x: { title: { display: true, text: 'ScÃ©nario de Test', font: { size: 14 } } }, y: { beginAtZero: true, title: { display: true, font: { size: 14 } } } },
        responsive: true, maintainAspectRatio: false, interaction: { intersect: false, mode: 'index' },
        plugins: { legend: { position: 'top', labels: { font: { size: 13 } } }, title: { display: true, font: { size: 18, weight: 'bold' } } }
    };
    const createChart = (canvasId, config) => { if (document.getElementById(canvasId)) { new Chart(document.getElementById(canvasId).getContext('2d'), config); }};

    // Time Chart
    createChart('timeChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [ // Bar chart better for comparing distinct scenarios
        { label: 'Temps Ã‰coulÃ© Moyen (s)', data: $jsAvgTimes, backgroundColor: 'rgba(220, 53, 69, 0.7)', borderColor: 'rgb(220, 53, 69)', borderWidth: 1, yAxisID: 'yTime' },
        { label: 'Temps CPU Moyen (s)', data: $jsAvgCpu, backgroundColor: 'rgba(13, 110, 253, 0.7)', borderColor: 'rgb(13, 110, 253)', borderWidth: 1, yAxisID: 'yTime' } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Performance Temps par ScÃ©nario'} }, scales: { ...commonChartOptions.scales, yTime: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [ // Bar chart better here too
        { label: 'Working Set Moyen (MB)', data: $jsAvgWS, backgroundColor: 'rgba(25, 135, 84, 0.7)', borderColor: 'rgb(25, 135, 84)', borderWidth: 1, yAxisID: 'yMemory' },
        { label: 'MÃ©moire PrivÃ©e Moyenne (MB)', data: $jsAvgPM, backgroundColor: 'rgba(108, 117, 125, 0.7)', borderColor: 'rgb(108, 117, 125)', borderWidth: 1, yAxisID: 'yMemory' } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Utilisation MÃ©moire par ScÃ©nario'} }, scales: { ...commonChartOptions.scales, yMemory: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'MB'}}} }
    });

    // Success Rate Chart
    createChart('successRateChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [{ label: 'Taux de SuccÃ¨s (%)', data: $jsSuccessRates, backgroundColor: 'rgba(255, 193, 7, 0.7)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1 }] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Taux de SuccÃ¨s par ScÃ©nario'} }, scales: { ...commonChartOptions.scales, y: { ...commonChartOptions.scales.y, min: 0, max: 100, title: { ...commonChartOptions.scales.y.title, text: '%' } } } }
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
    }
}

#endregion

#region ExÃ©cution Principale du Benchmarking

Write-Host "`n=== DÃ©marrage des Tests par ScÃ©nario ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan

$allScenarioResultsList = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalScenarios = $OptimizationScenarios.Count
$currentScenarioIndex = 0

# Boucle sur chaque scÃ©nario dÃ©fini
foreach ($scenario in $OptimizationScenarios) {
    $currentScenarioIndex++
    $scenarioName = $scenario.Name
    $scenarioParameters = $scenario.Parameters

    $progressParams = @{
        Activity = "Optimisation MÃ©moire par ScÃ©narios"
        Status   = "Test ScÃ©nario '$scenarioName' ($currentScenarioIndex/$totalScenarios)"
        PercentComplete = (($currentScenarioIndex -1) / $totalScenarios) * 100
        CurrentOperation = "PrÃ©paration..."
    }
    Write-Progress @progressParams

    Write-Host "`n--- Test ScÃ©nario : '$scenarioName' ($currentScenarioIndex/$totalScenarios) ---" -ForegroundColor Yellow
    Write-Verbose "ParamÃ¨tres spÃ©cifiques pour ce scÃ©nario :"
    Write-Verbose ($scenarioParameters | Out-String)

    # Nom unique pour l'appel Ã  Test-ParallelPerformance
    # Utiliser le nom du scÃ©nario pour identifier facilement les logs/rapports intermÃ©diaires
    $safeScenarioName = $scenarioName -replace '[^a-zA-Z0-9_.-]+', '_' -replace '^[_.-]+|[_.-]+$'
    $benchmarkTestName = $safeScenarioName # Utiliser directement le nom nettoyÃ© du scÃ©nario

    # PrÃ©parer les paramÃ¨tres pour Test-ParallelPerformance.ps1
    $benchmarkParams = @{
        ScriptBlock         = $ScriptBlock             # Le mÃªme pour tous les scÃ©narios
        Parameters          = $scenarioParameters      # ParamÃ¨tres SPÃ‰CIFIQUES Ã  ce scÃ©nario
        TestName            = $benchmarkTestName       # Nom basÃ© sur le scÃ©nario
        OutputPath          = $memoryOptRunOutputPath  # Sortie DANS le dossier global de l'optimisation
        Iterations          = $Iterations              # Nombre de rÃ©pÃ©titions pour ce scÃ©nario
        GenerateReport      = $false # Pas de rapport HTML individuel par scÃ©nario
        NoGarbageCollection = $true # Laisser Test-ParallelPerformance dÃ©cider (ou ajouter un switch ici si besoin)
        ErrorAction         = 'Continue'               # Capturer les erreurs de Test-ParallelPerformance
    }

    $scenarioResultSummary = $null
    $benchmarkError = $null

    try {
        Write-Progress @progressParams -CurrentOperation "ExÃ©cution de Test-ParallelPerformance ($Iterations itÃ©rations)..."
        Write-Verbose "Lancement de Test-ParallelPerformance.ps1 pour le scÃ©nario '$scenarioName'..."

        # ExÃ©cuter le benchmark pour ce scÃ©nario
        $scenarioResultSummary = & $benchmarkScriptPath @benchmarkParams -ErrorVariable +benchmarkError

        if ($benchmarkError) {
            Write-Warning "Erreurs non bloquantes lors de l'exÃ©cution du scÃ©nario '$scenarioName':"
            $benchmarkError | ForEach-Object { Write-Warning ('    ' + $_.ToString()) }
        }
         Write-Progress @progressParams -CurrentOperation "Benchmark terminÃ©"

    } catch {
        # Erreur critique arrÃªtant Test-ParallelPerformance
        Write-Error "Ã‰chec critique lors de l'exÃ©cution du scÃ©nario '$scenarioName'. Erreur : $($_.Exception.Message)"
        $benchmarkError = $_
    }

    # Traiter le rÃ©sultat du benchmark pour ce scÃ©nario
    if ($scenarioResultSummary -is [PSCustomObject] -and $scenarioResultSummary.PSObject.Properties.Name -contains 'AverageExecutionTimeS') {
        # RÃ©sultat valide
        $scenarioResultSummary | Add-Member -MemberType NoteProperty -Name "ScenarioName" -Value $scenarioName -Force # Ajouter le nom du scÃ©nario au rÃ©sultat
        $scenarioResultSummary | Add-Member -MemberType NoteProperty -Name "Status" -Value "Completed" -Force
        $allScenarioResultsList.Add($scenarioResultSummary)
        Write-Host ("RÃ©sultat enregistrÃ© pour ScÃ©nario '{0}': TempsMoyen={1:F3}s, SuccÃ¨s={2:F1}%, MemPrivMoy={3:F2}MB" -f `
            $scenarioName, $scenarioResultSummary.AverageExecutionTimeS,
            $scenarioResultSummary.SuccessRatePercent, $scenarioResultSummary.AveragePrivateMemoryMB) -ForegroundColor Green
    } else {
        # Ã‰chec ou rÃ©sultat invalide
        $failureReason = if($benchmarkError) { $benchmarkError[0].ToString() } else { "Test-ParallelPerformance n'a pas retournÃ© un objet de rÃ©sumÃ© valide." }
        Write-Warning "Le test pour le scÃ©nario '$scenarioName' a Ã©chouÃ© ou n'a pas retournÃ© de rÃ©sumÃ© valide. Raison: $failureReason"
        $failedResult = [PSCustomObject]@{
            ScenarioName          = $scenarioName
            TestName              = $benchmarkTestName # Garder le nom passÃ© au benchmark
            Status                = 'FailedOrIncomplete'
            SuccessRatePercent    = 0
            AverageExecutionTimeS = -1.0; MinExecutionTimeS = -1.0; MaxExecutionTimeS = -1.0
            AverageProcessorTimeS = -1.0; MinProcessorTimeS = -1.0; MaxProcessorTimeS = -1.0
            AverageWorkingSetMB   = -1.0; MinWorkingSetMB = -1.0; MaxWorkingSetMB = -1.0
            AveragePrivateMemoryMB= -1.0; MinPrivateMemoryMB = -1.0; MaxPrivateMemoryMB = -1.0
            ErrorMessage          = $failureReason
        }
        $allScenarioResultsList.Add($failedResult)
    }
     Write-Progress @progressParams -PercentComplete ($currentScenarioIndex / $totalScenarios * 100) -CurrentOperation "TerminÃ©"

} # Fin de la boucle foreach ($scenario in $OptimizationScenarios)

Write-Progress @progressParams -Activity "Optimisation MÃ©moire par ScÃ©narios" -Status "Analyse finale des rÃ©sultats..." -Completed

#endregion

#region Analyse Finale et GÃ©nÃ©ration des Rapports

Write-Host "`n=== Analyse Finale des RÃ©sultats ($($allScenarioResultsList.Count) scÃ©narios testÃ©s) ===" -ForegroundColor Cyan

$finalResultsArray = $allScenarioResultsList.ToArray() # Convertir en tableau

if ($finalResultsArray.Length -eq 0) {
     Write-Warning "Aucun rÃ©sultat de scÃ©nario n'a Ã©tÃ© collectÃ©. Impossible d'analyser ou de gÃ©nÃ©rer des rapports."
     return $null
}

# Identifier les meilleurs scÃ©narios (parmi ceux avec rÃ©sultats valides)
$validResults = $finalResultsArray | Where-Object { $_.AverageExecutionTimeS -ge 0 }
$fastestScenario = $null
$lowestMemoryScenario = $null

if ($validResults.Length -gt 0) {
    $fastestScenario = $validResults | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
    $lowestMemoryScenario = $validResults | Where-Object {$_.AveragePrivateMemoryMB -ge 0} | Sort-Object -Property AveragePrivateMemoryMB | Select-Object -First 1

    Write-Host "--- Points ClÃ©s ---" -ForegroundColor Cyan
    if ($fastestScenario) {
        Write-Host ("  - ScÃ©nario le plus rapide : '{0}' ({1:F3}s)" -f $fastestScenario.TestName, $fastestScenario.AverageExecutionTimeS) -ForegroundColor Green
    } else { Write-Warning "  - Impossible de dÃ©terminer le scÃ©nario le plus rapide." }
    if ($lowestMemoryScenario) {
        Write-Host ("  - Consommation mÃ©moire privÃ©e la plus basse : '{0}' ({1:F2}MB)" -f $lowestMemoryScenario.TestName, $lowestMemoryScenario.AveragePrivateMemoryMB) -ForegroundColor Green
    } else { Write-Warning "  - Impossible de dÃ©terminer le scÃ©nario avec la plus basse mÃ©moire privÃ©e."}
} else {
     Write-Warning "Aucun scÃ©nario n'a produit de rÃ©sultats valides pour l'analyse."
}

# Enregistrer les rÃ©sultats agrÃ©gÃ©s en JSON
$resultsJsonFileName = "MemoryOptimization_Summary.json"
$resultsJsonPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath $resultsJsonFileName
try {
    # On peut inclure la config des scÃ©narios dans le JSON pour rÃ©fÃ©rence
    $outputJsonData = @{
        ExecutionTimestamp = $startTimestamp
        Configuration = @{
            IterationsPerScenario = $Iterations
            TestDataStatus = $testDataStatus
        }
        ScenariosTested = $OptimizationScenariosConfig # La config originale
        ResultsSummary = $finalResultsArray # Les rÃ©sumÃ©s de chaque scÃ©nario
    }
    ConvertTo-Json -InputObject $outputJsonData -Depth 6 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`nðŸ“Š RÃ©sumÃ© complet de la comparaison enregistrÃ© (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement du rÃ©sumÃ© JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# GÃ©nÃ©rer le rapport HTML comparatif si demandÃ©
if ($GenerateReport) {
    if ($finalResultsArray.Length -gt 0) {
        $reportHtmlFileName = "MemoryOptimization_Report.html"
        $reportHtmlPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath $reportHtmlFileName
        $reportParams = @{
            AllScenarioResults        = $finalResultsArray
            ReportPath                = $reportHtmlPath
            FastestScenario           = $fastestScenario # Peut Ãªtre $null
            LowestMemoryScenario      = $lowestMemoryScenario # Peut Ãªtre $null
            OptimizationScenariosConfig = $OptimizationScenarios # Passer la config pour dÃ©tails
            IterationsPerScenario     = $Iterations
            TestDataInfo              = $testDataStatus
            OutputDirectory           = $memoryOptRunOutputPath
            ErrorAction               = 'Continue'
        }
        New-MemoryOptimizationHtmlReport @reportParams
    } else {
        Write-Warning "GÃ©nÃ©ration du rapport HTML annulÃ©e car aucun rÃ©sultat de scÃ©nario n'a Ã©tÃ© collectÃ©."
    }
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Comparaison MÃ©moire/Performance par ScÃ©narios TerminÃ©e ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "DurÃ©e totale du script d'optimisation : $($totalDuration.ToString('g'))"

#endregion

# Retourner le tableau des rÃ©sultats rÃ©sumÃ©s pour chaque scÃ©nario
return $finalResultsArray