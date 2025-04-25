#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les performances mémoire et temporelles d'un script sous différents scénarios de configuration.
.DESCRIPTION
    Ce script orchestre l'exécution d'un script de benchmark (`Test-ParallelPerformance.ps1`)
    pour évaluer un `ScriptBlock` cible sous plusieurs configurations définies (`OptimizationScenarios`).
    Chaque scénario spécifie un ensemble unique de paramètres pour le script cible.
    Pour chaque scénario, le benchmark est exécuté plusieurs fois (`Iterations`) pour obtenir
    des métriques fiables (temps, CPU, mémoire, succès).
    Le script collecte les résumés de performance de chaque scénario, les analyse comparativement,
    et génère un rapport JSON détaillé ainsi qu'un rapport HTML interactif (si demandé)
    dans un sous-répertoire de sortie unique. Il met en évidence les scénarios les plus performants
    en termes de mémoire privée et de temps d'exécution.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell qui exécute le script cible à évaluer. Doit accepter
    les paramètres via splatting. Exemple :
    { param($params) & "C:\Path\To\TargetScript.ps1" @params }
.PARAMETER OptimizationScenarios
    Tableau de tables de hachage. Chaque table de hachage représente un scénario à tester et doit contenir:
        - Name (String): Un nom unique et descriptif pour le scénario.
        - Parameters (Hashtable): Les paramètres spécifiques à passer au ScriptBlock pour ce scénario.
    Exemple:
    @(
        @{ Name = "LowWorkers_SmallBatch"; Parameters = @{ MaxWorkers = 2; BatchSize = 10; InputDir = '...' } },
        @{ Name = "HighWorkers_LargeBatch"; Parameters = @{ MaxWorkers = 8; BatchSize = 100; InputDir = '...' } }
    )
.PARAMETER OutputPath
    Chemin du répertoire racine où les résultats seront stockés. Un sous-répertoire unique
    (basé sur 'MemoryOpt' + Timestamp) sera créé pour cette exécution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un répertoire contenant des données de test pré-existantes.
    Si fourni et valide, ce chemin peut être injecté dans les paramètres des scénarios
    via TestDataTargetParameterName. Sinon, 'New-TestData.ps1' peut être utilisé pour générer des données.
.PARAMETER TestDataTargetParameterName
    [Optionnel] Nom du paramètre (dans la hashtable `Parameters` de chaque scénario)
    qui doit recevoir le chemin des données de test effectif (`$actualTestDataPath`).
    Permet d'injecter le chemin des données dans la configuration de chaque scénario. Défaut: 'ScriptsPath'.
.PARAMETER Iterations
    Nombre de fois où `Test-ParallelPerformance.ps1` doit exécuter le `ScriptBlock` pour *chaque*
    scénario afin de calculer des moyennes et statistiques fiables. Défaut: 3.
.PARAMETER GenerateReport
    Si spécifié ($true), génère un rapport HTML comparatif détaillé pour les scénarios,
    incluant des graphiques interactifs et des mises en évidence.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la génération de données via 'New-TestData.ps1' est applicable, force la suppression
    et la regénération des données même si elles existent déjà.
.EXAMPLE
    # Comparaison de différents nombres de workers pour Analyze-Scripts.ps1
    $targetScript = ".\scripts\analysis\Analyze-Scripts.ps1"
    $scenarios = @(
        @{ Name = "Workers_2"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=2 } },
        @{ Name = "Workers_4"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=4 } },
        @{ Name = "Workers_8"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=8 } }
    )
    .\Optimize-ParallelMemory.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -OptimizationScenarios $scenarios `
        -OutputPath "C:\PerfReports\MemOpt_Workers" `
        -TestDataPath "C:\Data" ` # Fourni ici, sera injecté si nécessaire par TestDataTargetParameterName
        -TestDataTargetParameterName "ScriptsPath" `
        -Iterations 5 `
        -GenerateReport -Verbose

.EXAMPLE
    # Comparaison avec et sans cache, avec génération de données
    $targetScript = ".\scripts\processing\Process-Files.ps1"
    # Process-Files.ps1 utilise -SourceDirectory
    $scenarios = @(
        @{ Name = "NoCache"; Parameters = @{ MaxWorkers=4; UseCache=$false } },
        @{ Name = "WithCache"; Parameters = @{ MaxWorkers=4; UseCache=$true } }
    )
    .\Optimize-ParallelMemory.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -OptimizationScenarios $scenarios `
        -OutputPath "C:\PerfReports\MemOpt_Cache" `
        -TestDataTargetParameterName "SourceDirectory" ` # Injecter le chemin généré ici
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration

.NOTES
    Auteur     : Votre Nom/Équipe
    Version    : 2.1
    Date       : 2023-10-27
    Dépendances:
        - Test-ParallelPerformance.ps1 (Requis, même répertoire ou chemin connu)
        - New-TestData.ps1 (Optionnel, pour génération de données, même répertoire)
        - Chart.js (via CDN pour le rapport HTML)

    Structure de Sortie:
    Un sous-répertoire unique `MemoryOpt_[Timestamp]` sera créé dans `OutputPath`.
    Il contiendra :
      - `MemoryOptimization_Summary.json`: Données et résumés pour chaque scénario.
      - `MemoryOptimization_Report.html`: Rapport HTML comparatif (si -GenerateReport).
      - `generated_test_data/`: Données générées (si applicable).
      - Sous-dossiers créés par `Test-ParallelPerformance.ps1` pour les logs détaillés de chaque scénario/itération.

    Le paramètre `-MonitorMemoryDuringRun` de versions précédentes est déprécié car les métriques
    agrégées de `Test-ParallelPerformance.ps1` (notamment AveragePrivateMemoryMB) sont plus fiables
    et suffisantes pour la comparaison entre scénarios.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell qui exécute le script cible, acceptant les paramètres via splatting.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $true, HelpMessage = "Tableau de scénarios à comparer. Chaque scénario est une hashtable avec 'Name' (string) et 'Parameters' (hashtable).")]
    [ValidateNotNullOrEmpty()]
    [array]$OptimizationScenarios,

    [Parameter(Mandatory = $true, HelpMessage = "Répertoire racine où le sous-dossier des résultats sera créé.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les données de test pré-existantes.")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nom du paramètre dans les Parameters de chaque scénario où injecter le chemin des données. Défaut: 'ScriptsPath'.")]
    [string]$TestDataTargetParameterName = 'ScriptsPath',

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'itérations du benchmark par scénario.")]
    [ValidateRange(1, 100)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false, HelpMessage = "Générer un rapport HTML comparatif détaillé des scénarios.")]
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
Write-Host "=== Initialisation Optimisation Mémoire par Scénarios ===" -ForegroundColor White -BackgroundColor DarkBlue

# 1. Valider le script de benchmark dépendant
$benchmarkScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ParallelPerformance.ps1"
if (-not (Test-Path $benchmarkScriptPath -PathType Leaf)) {
    Write-Error "Script dépendant crucial 'Test-ParallelPerformance.ps1' introuvable dans '$PSScriptRoot'. Arrêt."
    return
}
Write-Verbose "Script de benchmark dépendant trouvé : $benchmarkScriptPath"

# 2. Valider la structure des scénarios
if ($OptimizationScenarios.Count -eq 0) {
    Write-Error "Le paramètre -OptimizationScenarios ne peut pas être vide."
    return
}
foreach ($scenario in $OptimizationScenarios) {
    if (-not ($scenario -is [hashtable]) -or -not $scenario.ContainsKey('Name') -or -not $scenario.ContainsKey('Parameters') -or -not ($scenario.Parameters -is [hashtable])) {
        Write-Error "Structure invalide détectée dans -OptimizationScenarios. Chaque élément doit être une hashtable avec les clés 'Name' (string) et 'Parameters' (hashtable)."
        Write-Error "Scénario problématique: $($scenario | Out-String)"
        return
    }
     if ([string]::IsNullOrWhiteSpace($scenario.Name)) {
        Write-Error "La clé 'Name' dans un scénario ne peut pas être vide."
        return
    }
}
$scenarioNames = $OptimizationScenarios.Name
if (($scenarioNames | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
     Write-Error "Les noms de scénarios ('Name') dans -OptimizationScenarios doivent être uniques."
     return
}
Write-Verbose "Structure des $($OptimizationScenarios.Count) scénarios validée."

# 3. Créer le répertoire de sortie racine et le sous-répertoire unique
$resolvedOutputPath = New-DirectoryIfNotExists -Path $OutputPath -Purpose "Résultats Globaux"
if (-not $resolvedOutputPath) { return }

$timestamp = $startTimestamp.ToString('yyyyMMddHHmmss')
$memoryOptRunOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath "MemoryOpt_$timestamp"
$memoryOptRunOutputPath = New-DirectoryIfNotExists -Path $memoryOptRunOutputPath -Purpose "Résultats de cette Exécution d'Optimisation"
if (-not $memoryOptRunOutputPath) { return }

Write-Host "Répertoire de sortie pour cette exécution : $memoryOptRunOutputPath" -ForegroundColor Green

# 4. Gestion des données de test (similaire aux autres scripts)
$actualTestDataPath = $null
$testDataStatus = "Non applicable"

# 4a. Vérifier le chemin explicite
$actualTestDataPath = $null
$testDataStatus = "Non spécifié"

if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des données fournies: $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'est pas valide. Tentative de génération si New-TestData.ps1 existe."
    }
}

# 4b. Tenter la génération si nécessaire/forcé
$testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
$targetGeneratedDataPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath "generated_test_data"
$generate = $false

# Vérifier si nous devons générer des données de test
if ((-not $actualTestDataPath -or $ForceTestDataGeneration) -and (Test-Path $testDataScriptPath -PathType Leaf)) {
    # Déterminer si nous devons générer des données
    if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
        $generate = $true
    } elseif ($ForceTestDataGeneration) {
        if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et regénérer les données de test")) {
            Write-Verbose "Forçage de la regénération des données de test."
            try {
                Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop
                $generate = $true
            } catch {
                Write-Warning "Impossible de supprimer l'ancien dossier de données '$targetGeneratedDataPath': $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Regénération annulée. Utilisation des données existantes si possible."
            if (Test-Path $targetGeneratedDataPath -PathType Container) {
                $actualTestDataPath = $targetGeneratedDataPath
                $testDataStatus = "Utilisation des données existantes (regénération annulée): $actualTestDataPath"
                Write-Verbose $testDataStatus
            } else {
                $testDataStatus = "Regénération annulée, dossier inexistant."
                Write-Verbose $testDataStatus
            }
        }
    } else {
        # Utiliser les données existantes
        $actualTestDataPath = $targetGeneratedDataPath
        $testDataStatus = "Réutilisation des données précédemment générées: $actualTestDataPath"
        Write-Verbose $testDataStatus
    }

    # Générer les données si nécessaire
    if ($generate) {
        if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Générer les données de test")) {
            Write-Host "Génération des données de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
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
                    $testDataStatus = "Données générées avec succès: $actualTestDataPath"
                    Write-Host $testDataStatus -ForegroundColor Green
                } else {
                    Write-Error "Échec de New-TestData.ps1."
                    $testDataStatus = "Échec génération."
                    $actualTestDataPath = $null
                }
            } catch {
                Write-Error "Erreur critique New-TestData.ps1: $($_.Exception.Message)"
                $testDataStatus = "Échec critique."
                $actualTestDataPath = $null
            }
        } else {
            Write-Warning "Génération annulée."
            $testDataStatus = "Génération annulée."

            if ($actualTestDataPath -eq $targetGeneratedDataPath) {
                $testDataStatus += " Utilisation des données pré-existantes."
            } else {
                $actualTestDataPath = $null
            }

            Write-Verbose $testDataStatus
        }
    }
} elseif (-not $actualTestDataPath) {
    $testDataStatus = "Données de test non requises ou non gérées."
    Write-Verbose $testDataStatus
}

# 4c. Injecter le chemin des données dans les paramètres des scénarios
if ($actualTestDataPath) {
    Write-Verbose "Injection du chemin de données '$actualTestDataPath' dans les scénarios (paramètre cible: '$TestDataTargetParameterName')."
    foreach ($scenario in $OptimizationScenarios) {
        if ($scenario.Parameters.ContainsKey($TestDataTargetParameterName)) {
            Write-Verbose "  -> Scénario '$($scenario.Name)': Mise à jour de Parameters['$TestDataTargetParameterName']"
            $scenario.Parameters[$TestDataTargetParameterName] = $actualTestDataPath
        } else {
             Write-Verbose "  -> Scénario '$($scenario.Name)': Le paramètre cible '$TestDataTargetParameterName' n'existe pas dans ses Parameters."
             # Optionnel : ajouter le paramètre s'il manque ? Pour l'instant, on suppose qu'il doit exister.
             # $scenario.Parameters[$TestDataTargetParameterName] = $actualTestDataPath
        }
    }
} elseif (-not [string]::IsNullOrEmpty($TestDataTargetParameterName)) {
     Write-Verbose "Aucun chemin de données effectif ($actualTestDataPath est vide), l'injection du paramètre '$TestDataTargetParameterName' est ignorée."
}


# 5. Afficher le contexte d'exécution final
Write-Host "Contexte d'exécution :" -ForegroundColor Cyan
Write-Host "  - Script Benchmark : $benchmarkScriptPath"
Write-Host "  - Scénarios à Tester: $($scenarioNames -join ', ')"
Write-Host "  - Itérations par Scénario: $Iterations"
Write-Host "  - Génération Rapport HTML: $($GenerateReport.IsPresent)"
Write-Host "  - Statut Données Test : $testDataStatus"
Write-Verbose "  - Paramètres détaillés par scénario :"
$OptimizationScenarios | ForEach-Object { Write-Verbose "    - Scenario '$($_.Name)': $($_.Parameters | Out-String | Select-Object -Skip 1 | ForEach-Object { '      ' + $_ })" }


Write-Verbose "Validation et Initialisation terminées."
#endregion

#region Fonction de Génération du Rapport HTML (Adaptée pour Scénarios)

function New-MemoryOptimizationHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [array]$AllScenarioResults, # Tableau des résumés retournés par Test-ParallelPerformance pour chaque scénario
        [Parameter(Mandatory = $true)] [string]$ReportPath,
        [Parameter(Mandatory = $false)] [PSCustomObject]$FastestScenario,
        [Parameter(Mandatory = $false)] [PSCustomObject]$LowestMemoryScenario,
        [Parameter(Mandatory = $false)] [array]$OptimizationScenariosConfig, # La config originale pour afficher les params
        [Parameter(Mandatory = $false)] [int]$IterationsPerScenario,
        [Parameter(Mandatory = $false)] [string]$TestDataInfo,
        [Parameter(Mandatory = $false)] [string]$OutputDirectory
    )

    Write-Host "Génération du rapport HTML de comparaison des scénarios : $ReportPath" -ForegroundColor Cyan

    $validResults = $AllScenarioResults | Where-Object { $null -ne $_ -and $_.PSObject.Properties.ContainsKey('AverageExecutionTimeS') -and $_.AverageExecutionTimeS -ge 0 }
    if ($validResults.Count -eq 0) {
        Write-Warning "Aucune donnée de résultat valide pour générer le rapport HTML."
        # Potentiellement créer un rapport minimal ici
        return
    }

    # Préparer les données pour JS (Labels = Noms des scénarios)
    $jsLabels = ConvertTo-JavaScriptData ($validResults.TestName) # Utiliser le TestName qui contient le nom du scénario
    $jsAvgTimes = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageExecutionTimeS, 3) })
    $jsAvgCpu = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageProcessorTimeS, 3) })
    $jsAvgWS = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageWorkingSetMB, 2) })
    $jsAvgPM = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AveragePrivateMemoryMB, 2) })
    $jsSuccessRates = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.SuccessRatePercent, 1) })

    # Section de mise en évidence
    $highlightHtml = ""
    if ($LowestMemoryScenario) {
         $highlightHtml += @"
<div class="section optimal" id="lowest-memory">
    <h2>💧 Consommation Mémoire Minimale</h2>
    <p><span class="metric-label">Scénario:</span> <span class="optimal-value">$($LowestMemoryScenario.TestName)</span></p>
    <p><span class="metric-label tooltip">Mémoire Privée Moyenne:<span class="tooltiptext">Mémoire non partagée moyenne allouée. Indicateur clé.</span></span> $($LowestMemoryScenario.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Temps Moyen Écoulé:</span> $($LowestMemoryScenario.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label">Taux de Succès:</span> $($LowestMemoryScenario.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    }
    if ($FastestScenario) {
         $highlightHtml += @"
<div class="section optimal" id="fastest">
    <h2>⏱️ Exécution la Plus Rapide</h2>
    <p><span class="metric-label">Scénario:</span> <span class="optimal-value">$($FastestScenario.TestName)</span></p>
    <p><span class="metric-label tooltip">Temps Moyen Écoulé:<span class="tooltiptext">Durée totale moyenne pour ce scénario. Plus bas est mieux.</span></span> $($FastestScenario.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label">Mémoire Privée Moyenne:</span> $($FastestScenario.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Taux de Succès:</span> $($FastestScenario.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    }
     if (-not $LowestMemoryScenario -and -not $FastestScenario) {
         $highlightHtml = @"
<div class="section warning">
    <h2>⚠️ Analyse Limitée</h2>
    <p>Impossible de déterminer formellement le scénario le plus rapide ou celui consommant le moins de mémoire (probablement dû à des échecs ou données manquantes).</p>
</div>
"@
     }


    # Table des détails (générée via boucle)
    $detailsTableRows = $AllScenarioResults | ForEach-Object {
        $scenarioConfig = $OptimizationScenariosConfig | Where-Object { $_.Name -eq $_.TestName } | Select-Object -First 1
        $paramsForScenarioHtml = "<i>Erreur: Config non trouvée</i>"
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
    <thead><tr><th>Scénario & Paramètres</th><th>Taux Succès (%)</th><th>Temps Moyen (s)</th><th>CPU Moyen (s)</th><th>WS Moyen (MB)</th><th>PM Moyen (MB)</th><th>Message Principal (si échec)</th></tr></thead>
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
    <title>Rapport Comparaison Mémoire/Perf par Scénario</title>
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
    <h1>Rapport Comparaison Mémoire/Performance par Scénario</h1>
    <div class="section" id="context">
        <h2>Contexte de l'Exécution</h2>
        <p><span class="metric-label">Généré le:</span> $(Get-Date -Format "yyyy-MM-dd 'à' HH:mm:ss")</p>
        <p><span class="metric-label">Nombre de Scénarios Testés:</span> $($AllScenarioResults.Count)</p>
        <p><span class="metric-label">Itérations par Scénario:</span> $IterationsPerScenario</p>
        <p><span class="metric-label">Statut Données Test:</span> $TestDataInfo</p>
        <p><span class="metric-label">Répertoire des Résultats:</span> <code>$OutputDirectory</code></p>
    </div>

    $highlightHtml

    <div class="section" id="detailed-results">
        <h2>Résultats Comparatifs Détaillés par Scénario</h2>
        $detailsTableHtml
        <p class="notes"><i>Les métriques sont moyennées sur $IterationsPerScenario exécutions pour chaque scénario.</i></p>
    </div>

    <div class="section" id="charts">
        <h2>Graphiques Comparatifs des Scénarios</h2>
        <div class="chart-container"><canvas id="timeChart"></canvas></div>
        <div class="chart-container"><canvas id="memoryChart"></canvas></div>
        <div class="chart-container"><canvas id="successRateChart"></canvas></div>
    </div>
<script>
    const scenarioLabels = $jsLabels;
    const commonChartOptions = { /* Options communes identiques à Optimize-ParallelBatchSize */
        scales: { x: { title: { display: true, text: 'Scénario de Test', font: { size: 14 } } }, y: { beginAtZero: true, title: { display: true, font: { size: 14 } } } },
        responsive: true, maintainAspectRatio: false, interaction: { intersect: false, mode: 'index' },
        plugins: { legend: { position: 'top', labels: { font: { size: 13 } } }, title: { display: true, font: { size: 18, weight: 'bold' } } }
    };
    const createChart = (canvasId, config) => { if (document.getElementById(canvasId)) { new Chart(document.getElementById(canvasId).getContext('2d'), config); }};

    // Time Chart
    createChart('timeChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [ // Bar chart better for comparing distinct scenarios
        { label: 'Temps Écoulé Moyen (s)', data: $jsAvgTimes, backgroundColor: 'rgba(220, 53, 69, 0.7)', borderColor: 'rgb(220, 53, 69)', borderWidth: 1, yAxisID: 'yTime' },
        { label: 'Temps CPU Moyen (s)', data: $jsAvgCpu, backgroundColor: 'rgba(13, 110, 253, 0.7)', borderColor: 'rgb(13, 110, 253)', borderWidth: 1, yAxisID: 'yTime' } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Performance Temps par Scénario'} }, scales: { ...commonChartOptions.scales, yTime: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [ // Bar chart better here too
        { label: 'Working Set Moyen (MB)', data: $jsAvgWS, backgroundColor: 'rgba(25, 135, 84, 0.7)', borderColor: 'rgb(25, 135, 84)', borderWidth: 1, yAxisID: 'yMemory' },
        { label: 'Mémoire Privée Moyenne (MB)', data: $jsAvgPM, backgroundColor: 'rgba(108, 117, 125, 0.7)', borderColor: 'rgb(108, 117, 125)', borderWidth: 1, yAxisID: 'yMemory' } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Utilisation Mémoire par Scénario'} }, scales: { ...commonChartOptions.scales, yMemory: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'MB'}}} }
    });

    // Success Rate Chart
    createChart('successRateChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [{ label: 'Taux de Succès (%)', data: $jsSuccessRates, backgroundColor: 'rgba(255, 193, 7, 0.7)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1 }] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Taux de Succès par Scénario'} }, scales: { ...commonChartOptions.scales, y: { ...commonChartOptions.scales.y, min: 0, max: 100, title: { ...commonChartOptions.scales.y.title, text: '%' } } } }
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
    }
}

#endregion

#region Exécution Principale du Benchmarking

Write-Host "`n=== Démarrage des Tests par Scénario ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan

$allScenarioResultsList = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalScenarios = $OptimizationScenarios.Count
$currentScenarioIndex = 0

# Boucle sur chaque scénario défini
foreach ($scenario in $OptimizationScenarios) {
    $currentScenarioIndex++
    $scenarioName = $scenario.Name
    $scenarioParameters = $scenario.Parameters

    $progressParams = @{
        Activity = "Optimisation Mémoire par Scénarios"
        Status   = "Test Scénario '$scenarioName' ($currentScenarioIndex/$totalScenarios)"
        PercentComplete = (($currentScenarioIndex -1) / $totalScenarios) * 100
        CurrentOperation = "Préparation..."
    }
    Write-Progress @progressParams

    Write-Host "`n--- Test Scénario : '$scenarioName' ($currentScenarioIndex/$totalScenarios) ---" -ForegroundColor Yellow
    Write-Verbose "Paramètres spécifiques pour ce scénario :"
    Write-Verbose ($scenarioParameters | Out-String)

    # Nom unique pour l'appel à Test-ParallelPerformance
    # Utiliser le nom du scénario pour identifier facilement les logs/rapports intermédiaires
    $safeScenarioName = $scenarioName -replace '[^a-zA-Z0-9_.-]+', '_' -replace '^[_.-]+|[_.-]+$'
    $benchmarkTestName = $safeScenarioName # Utiliser directement le nom nettoyé du scénario

    # Préparer les paramètres pour Test-ParallelPerformance.ps1
    $benchmarkParams = @{
        ScriptBlock         = $ScriptBlock             # Le même pour tous les scénarios
        Parameters          = $scenarioParameters      # Paramètres SPÉCIFIQUES à ce scénario
        TestName            = $benchmarkTestName       # Nom basé sur le scénario
        OutputPath          = $memoryOptRunOutputPath  # Sortie DANS le dossier global de l'optimisation
        Iterations          = $Iterations              # Nombre de répétitions pour ce scénario
        GenerateReport      = $false # Pas de rapport HTML individuel par scénario
        NoGarbageCollection = $true # Laisser Test-ParallelPerformance décider (ou ajouter un switch ici si besoin)
        ErrorAction         = 'Continue'               # Capturer les erreurs de Test-ParallelPerformance
    }

    $scenarioResultSummary = $null
    $benchmarkError = $null

    try {
        Write-Progress @progressParams -CurrentOperation "Exécution de Test-ParallelPerformance ($Iterations itérations)..."
        Write-Verbose "Lancement de Test-ParallelPerformance.ps1 pour le scénario '$scenarioName'..."

        # Exécuter le benchmark pour ce scénario
        $scenarioResultSummary = & $benchmarkScriptPath @benchmarkParams -ErrorVariable +benchmarkError

        if ($benchmarkError) {
            Write-Warning "Erreurs non bloquantes lors de l'exécution du scénario '$scenarioName':"
            $benchmarkError | ForEach-Object { Write-Warning ('    ' + $_.ToString()) }
        }
         Write-Progress @progressParams -CurrentOperation "Benchmark terminé"

    } catch {
        # Erreur critique arrêtant Test-ParallelPerformance
        Write-Error "Échec critique lors de l'exécution du scénario '$scenarioName'. Erreur : $($_.Exception.Message)"
        $benchmarkError = $_
    }

    # Traiter le résultat du benchmark pour ce scénario
    if ($scenarioResultSummary -is [PSCustomObject] -and $scenarioResultSummary.PSObject.Properties.Name -contains 'AverageExecutionTimeS') {
        # Résultat valide
        $scenarioResultSummary | Add-Member -MemberType NoteProperty -Name "ScenarioName" -Value $scenarioName -Force # Ajouter le nom du scénario au résultat
        $scenarioResultSummary | Add-Member -MemberType NoteProperty -Name "Status" -Value "Completed" -Force
        $allScenarioResultsList.Add($scenarioResultSummary)
        Write-Host ("Résultat enregistré pour Scénario '{0}': TempsMoyen={1:F3}s, Succès={2:F1}%, MemPrivMoy={3:F2}MB" -f `
            $scenarioName, $scenarioResultSummary.AverageExecutionTimeS,
            $scenarioResultSummary.SuccessRatePercent, $scenarioResultSummary.AveragePrivateMemoryMB) -ForegroundColor Green
    } else {
        # Échec ou résultat invalide
        $failureReason = if($benchmarkError) { $benchmarkError[0].ToString() } else { "Test-ParallelPerformance n'a pas retourné un objet de résumé valide." }
        Write-Warning "Le test pour le scénario '$scenarioName' a échoué ou n'a pas retourné de résumé valide. Raison: $failureReason"
        $failedResult = [PSCustomObject]@{
            ScenarioName          = $scenarioName
            TestName              = $benchmarkTestName # Garder le nom passé au benchmark
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
     Write-Progress @progressParams -PercentComplete ($currentScenarioIndex / $totalScenarios * 100) -CurrentOperation "Terminé"

} # Fin de la boucle foreach ($scenario in $OptimizationScenarios)

Write-Progress @progressParams -Activity "Optimisation Mémoire par Scénarios" -Status "Analyse finale des résultats..." -Completed

#endregion

#region Analyse Finale et Génération des Rapports

Write-Host "`n=== Analyse Finale des Résultats ($($allScenarioResultsList.Count) scénarios testés) ===" -ForegroundColor Cyan

$finalResultsArray = $allScenarioResultsList.ToArray() # Convertir en tableau

if ($finalResultsArray.Length -eq 0) {
     Write-Warning "Aucun résultat de scénario n'a été collecté. Impossible d'analyser ou de générer des rapports."
     return $null
}

# Identifier les meilleurs scénarios (parmi ceux avec résultats valides)
$validResults = $finalResultsArray | Where-Object { $_.AverageExecutionTimeS -ge 0 }
$fastestScenario = $null
$lowestMemoryScenario = $null

if ($validResults.Length -gt 0) {
    $fastestScenario = $validResults | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
    $lowestMemoryScenario = $validResults | Where-Object {$_.AveragePrivateMemoryMB -ge 0} | Sort-Object -Property AveragePrivateMemoryMB | Select-Object -First 1

    Write-Host "--- Points Clés ---" -ForegroundColor Cyan
    if ($fastestScenario) {
        Write-Host ("  - Scénario le plus rapide : '{0}' ({1:F3}s)" -f $fastestScenario.TestName, $fastestScenario.AverageExecutionTimeS) -ForegroundColor Green
    } else { Write-Warning "  - Impossible de déterminer le scénario le plus rapide." }
    if ($lowestMemoryScenario) {
        Write-Host ("  - Consommation mémoire privée la plus basse : '{0}' ({1:F2}MB)" -f $lowestMemoryScenario.TestName, $lowestMemoryScenario.AveragePrivateMemoryMB) -ForegroundColor Green
    } else { Write-Warning "  - Impossible de déterminer le scénario avec la plus basse mémoire privée."}
} else {
     Write-Warning "Aucun scénario n'a produit de résultats valides pour l'analyse."
}

# Enregistrer les résultats agrégés en JSON
$resultsJsonFileName = "MemoryOptimization_Summary.json"
$resultsJsonPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath $resultsJsonFileName
try {
    # On peut inclure la config des scénarios dans le JSON pour référence
    $outputJsonData = @{
        ExecutionTimestamp = $startTimestamp
        Configuration = @{
            IterationsPerScenario = $Iterations
            TestDataStatus = $testDataStatus
        }
        ScenariosTested = $OptimizationScenariosConfig # La config originale
        ResultsSummary = $finalResultsArray # Les résumés de chaque scénario
    }
    ConvertTo-Json -InputObject $outputJsonData -Depth 6 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`n📊 Résumé complet de la comparaison enregistré (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement du résumé JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# Générer le rapport HTML comparatif si demandé
if ($GenerateReport) {
    if ($finalResultsArray.Length -gt 0) {
        $reportHtmlFileName = "MemoryOptimization_Report.html"
        $reportHtmlPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath $reportHtmlFileName
        $reportParams = @{
            AllScenarioResults        = $finalResultsArray
            ReportPath                = $reportHtmlPath
            FastestScenario           = $fastestScenario # Peut être $null
            LowestMemoryScenario      = $lowestMemoryScenario # Peut être $null
            OptimizationScenariosConfig = $OptimizationScenarios # Passer la config pour détails
            IterationsPerScenario     = $Iterations
            TestDataInfo              = $testDataStatus
            OutputDirectory           = $memoryOptRunOutputPath
            ErrorAction               = 'Continue'
        }
        New-MemoryOptimizationHtmlReport @reportParams
    } else {
        Write-Warning "Génération du rapport HTML annulée car aucun résultat de scénario n'a été collecté."
    }
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Comparaison Mémoire/Performance par Scénarios Terminée ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Durée totale du script d'optimisation : $($totalDuration.ToString('g'))"

#endregion

# Retourner le tableau des résultats résumés pour chaque scénario
return $finalResultsArray