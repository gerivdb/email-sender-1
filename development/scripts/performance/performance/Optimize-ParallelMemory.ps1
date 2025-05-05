#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les performances mÃƒÂ©moire et temporelles d'un script sous diffÃƒÂ©rents scÃƒÂ©narios de configuration.
.DESCRIPTION
    Ce script orchestre l'exÃƒÂ©cution d'un script de benchmark (`Test-ParallelPerformance.ps1`)
    pour ÃƒÂ©valuer un `ScriptBlock` cible sous plusieurs configurations dÃƒÂ©finies (`OptimizationScenarios`).
    Chaque scÃƒÂ©nario spÃƒÂ©cifie un ensemble unique de paramÃƒÂ¨tres pour le script cible.
    Pour chaque scÃƒÂ©nario, le benchmark est exÃƒÂ©cutÃƒÂ© plusieurs fois (`Iterations`) pour obtenir
    des mÃƒÂ©triques fiables (temps, CPU, mÃƒÂ©moire, succÃƒÂ¨s).
    Le script collecte les rÃƒÂ©sumÃƒÂ©s de performance de chaque scÃƒÂ©nario, les analyse comparativement,
    et gÃƒÂ©nÃƒÂ¨re un rapport JSON dÃƒÂ©taillÃƒÂ© ainsi qu'un rapport HTML interactif (si demandÃƒÂ©)
    dans un sous-rÃƒÂ©pertoire de sortie unique. Il met en ÃƒÂ©vidence les scÃƒÂ©narios les plus performants
    en termes de mÃƒÂ©moire privÃƒÂ©e et de temps d'exÃƒÂ©cution.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell qui exÃƒÂ©cute le script cible ÃƒÂ  ÃƒÂ©valuer. Doit accepter
    les paramÃƒÂ¨tres via splatting. Exemple :
    { param($params) & "C:\Path\To\TargetScript.ps1" @params }
.PARAMETER OptimizationScenarios
    Tableau de tables de hachage. Chaque table de hachage reprÃƒÂ©sente un scÃƒÂ©nario ÃƒÂ  tester et doit contenir:
        - Name (String): Un nom unique et descriptif pour le scÃƒÂ©nario.
        - Parameters (Hashtable): Les paramÃƒÂ¨tres spÃƒÂ©cifiques ÃƒÂ  passer au ScriptBlock pour ce scÃƒÂ©nario.
    Exemple:
    @(
        @{ Name = "LowWorkers_SmallBatch"; Parameters = @{ MaxWorkers = 2; BatchSize = 10; InputDir = '...' } },
        @{ Name = "HighWorkers_LargeBatch"; Parameters = @{ MaxWorkers = 8; BatchSize = 100; InputDir = '...' } }
    )
.PARAMETER OutputPath
    Chemin du rÃƒÂ©pertoire racine oÃƒÂ¹ les rÃƒÂ©sultats seront stockÃƒÂ©s. Un sous-rÃƒÂ©pertoire unique
    (basÃƒÂ© sur 'MemoryOpt' + Timestamp) sera crÃƒÂ©ÃƒÂ© pour cette exÃƒÂ©cution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un rÃƒÂ©pertoire contenant des donnÃƒÂ©es de test prÃƒÂ©-existantes.
    Si fourni et valide, ce chemin peut ÃƒÂªtre injectÃƒÂ© dans les paramÃƒÂ¨tres des scÃƒÂ©narios
    via TestDataTargetParameterName. Sinon, 'New-TestData.ps1' peut ÃƒÂªtre utilisÃƒÂ© pour gÃƒÂ©nÃƒÂ©rer des donnÃƒÂ©es.
.PARAMETER TestDataTargetParameterName
    [Optionnel] Nom du paramÃƒÂ¨tre (dans la hashtable `Parameters` de chaque scÃƒÂ©nario)
    qui doit recevoir le chemin des donnÃƒÂ©es de test effectif (`$actualTestDataPath`).
    Permet d'injecter le chemin des donnÃƒÂ©es dans la configuration de chaque scÃƒÂ©nario. DÃƒÂ©faut: 'ScriptsPath'.
.PARAMETER Iterations
    Nombre de fois oÃƒÂ¹ `Test-ParallelPerformance.ps1` doit exÃƒÂ©cuter le `ScriptBlock` pour *chaque*
    scÃƒÂ©nario afin de calculer des moyennes et statistiques fiables. DÃƒÂ©faut: 3.
.PARAMETER GenerateReport
    Si spÃƒÂ©cifiÃƒÂ© ($true), gÃƒÂ©nÃƒÂ¨re un rapport HTML comparatif dÃƒÂ©taillÃƒÂ© pour les scÃƒÂ©narios,
    incluant des graphiques interactifs et des mises en ÃƒÂ©vidence.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es via 'New-TestData.ps1' est applicable, force la suppression
    et la regÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es mÃƒÂªme si elles existent dÃƒÂ©jÃƒÂ .
.EXAMPLE
    # Comparaison de diffÃƒÂ©rents nombres de workers pour Analyze-Scripts.ps1
    $targetScript = ".\development\scripts\analysis\Analyze-Scripts.ps1"
    $scenarios = @(
        @{ Name = "Workers_2"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=2 } },
        @{ Name = "Workers_4"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=4 } },
        @{ Name = "Workers_8"; Parameters = @{ ScriptsPath="C:\Data"; MaxWorkers=8 } }
    )
    .\Optimize-ParallelMemory.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -OptimizationScenarios $scenarios `
        -OutputPath "C:\PerfReports\MemOpt_Workers" `
        -TestDataPath "C:\Data" ` # Fourni ici, sera injectÃƒÂ© si nÃƒÂ©cessaire par TestDataTargetParameterName
        -TestDataTargetParameterName "ScriptsPath" `
        -Iterations 5 `
        -GenerateReport -Verbose

.EXAMPLE
    # Comparaison avec et sans cache, avec gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es
    $targetScript = ".\development\scripts\processing\Process-Files.ps1"
    # Process-Files.ps1 utilise -SourceDirectory
    $scenarios = @(
        @{ Name = "NoCache"; Parameters = @{ MaxWorkers=4; UseCache=$false } },
        @{ Name = "WithCache"; Parameters = @{ MaxWorkers=4; UseCache=$true } }
    )
    .\Optimize-ParallelMemory.ps1 -ScriptBlock { param($p) & $targetScript @p } `
        -OptimizationScenarios $scenarios `
        -OutputPath "C:\PerfReports\MemOpt_Cache" `
        -TestDataTargetParameterName "SourceDirectory" ` # Injecter le chemin gÃƒÂ©nÃƒÂ©rÃƒÂ© ici
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration

.NOTES
    Auteur     : Votre Nom/Ãƒâ€°quipe
    Version    : 2.1
    Date       : 2023-10-27
    DÃƒÂ©pendances:
        - Test-ParallelPerformance.ps1 (Requis, mÃƒÂªme rÃƒÂ©pertoire ou chemin connu)
        - New-TestData.ps1 (Optionnel, pour gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es, mÃƒÂªme rÃƒÂ©pertoire)
        - Chart.js (via CDN pour le rapport HTML)

    Structure de Sortie:
    Un sous-rÃƒÂ©pertoire unique `MemoryOpt_[Timestamp]` sera crÃƒÂ©ÃƒÂ© dans `OutputPath`.
    Il contiendra :
      - `MemoryOptimization_Summary.json`: DonnÃƒÂ©es et rÃƒÂ©sumÃƒÂ©s pour chaque scÃƒÂ©nario.
      - `MemoryOptimization_Report.html`: Rapport HTML comparatif (si -GenerateReport).
      - `generated_test_data/`: DonnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es (si applicable).
      - Sous-dossiers crÃƒÂ©ÃƒÂ©s par `Test-ParallelPerformance.ps1` pour les logs dÃƒÂ©taillÃƒÂ©s de chaque scÃƒÂ©nario/itÃƒÂ©ration.

    Le paramÃƒÂ¨tre `-MonitorMemoryDuringRun` de versions prÃƒÂ©cÃƒÂ©dentes est dÃƒÂ©prÃƒÂ©ciÃƒÂ© car les mÃƒÂ©triques
    agrÃƒÂ©gÃƒÂ©es de `Test-ParallelPerformance.ps1` (notamment AveragePrivateMemoryMB) sont plus fiables
    et suffisantes pour la comparaison entre scÃƒÂ©narios.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell qui exÃƒÂ©cute le script cible, acceptant les paramÃƒÂ¨tres via splatting.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $true, HelpMessage = "Tableau de scÃƒÂ©narios ÃƒÂ  comparer. Chaque scÃƒÂ©nario est une hashtable avec 'Name' (string) et 'Parameters' (hashtable).")]
    [ValidateNotNullOrEmpty()]
    [array]$OptimizationScenarios,

    [Parameter(Mandatory = $true, HelpMessage = "RÃƒÂ©pertoire racine oÃƒÂ¹ le sous-dossier des rÃƒÂ©sultats sera crÃƒÂ©ÃƒÂ©.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les donnÃƒÂ©es de test prÃƒÂ©-existantes.")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nom du paramÃƒÂ¨tre dans les Parameters de chaque scÃƒÂ©nario oÃƒÂ¹ injecter le chemin des donnÃƒÂ©es. DÃƒÂ©faut: 'ScriptsPath'.")]
    [string]$TestDataTargetParameterName = 'ScriptsPath',

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'itÃƒÂ©rations du benchmark par scÃƒÂ©nario.")]
    [ValidateRange(1, 100)]
    [int]$Iterations = 3,

    [Parameter(Mandatory = $false, HelpMessage = "GÃƒÂ©nÃƒÂ©rer un rapport HTML comparatif dÃƒÂ©taillÃƒÂ© des scÃƒÂ©narios.")]
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
Write-Host "=== Initialisation Optimisation MÃƒÂ©moire par ScÃƒÂ©narios ===" -ForegroundColor White -BackgroundColor DarkBlue

# 1. Valider le script de benchmark dÃƒÂ©pendant
$benchmarkScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ParallelPerformance.ps1"
if (-not (Test-Path $benchmarkScriptPath -PathType Leaf)) {
    Write-Error "Script dÃƒÂ©pendant crucial 'Test-ParallelPerformance.ps1' introuvable dans '$PSScriptRoot'. ArrÃƒÂªt."
    return
}
Write-Verbose "Script de benchmark dÃƒÂ©pendant trouvÃƒÂ© : $benchmarkScriptPath"

# 2. Valider la structure des scÃƒÂ©narios
if ($OptimizationScenarios.Count -eq 0) {
    Write-Error "Le paramÃƒÂ¨tre -OptimizationScenarios ne peut pas ÃƒÂªtre vide."
    return
}
foreach ($scenario in $OptimizationScenarios) {
    if (-not ($scenario -is [hashtable]) -or -not $scenario.ContainsKey('Name') -or -not $scenario.ContainsKey('Parameters') -or -not ($scenario.Parameters -is [hashtable])) {
        Write-Error "Structure invalide dÃƒÂ©tectÃƒÂ©e dans -OptimizationScenarios. Chaque ÃƒÂ©lÃƒÂ©ment doit ÃƒÂªtre une hashtable avec les clÃƒÂ©s 'Name' (string) et 'Parameters' (hashtable)."
        Write-Error "ScÃƒÂ©nario problÃƒÂ©matique: $($scenario | Out-String)"
        return
    }
     if ([string]::IsNullOrWhiteSpace($scenario.Name)) {
        Write-Error "La clÃƒÂ© 'Name' dans un scÃƒÂ©nario ne peut pas ÃƒÂªtre vide."
        return
    }
}
$scenarioNames = $OptimizationScenarios.Name
if (($scenarioNames | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
     Write-Error "Les noms de scÃƒÂ©narios ('Name') dans -OptimizationScenarios doivent ÃƒÂªtre uniques."
     return
}
Write-Verbose "Structure des $($OptimizationScenarios.Count) scÃƒÂ©narios validÃƒÂ©e."

# 3. CrÃƒÂ©er le rÃƒÂ©pertoire de sortie racine et le sous-rÃƒÂ©pertoire unique
$resolvedOutputPath = New-DirectoryIfNotExists -Path $OutputPath -Purpose "RÃƒÂ©sultats Globaux"
if (-not $resolvedOutputPath) { return }

$timestamp = $startTimestamp.ToString('yyyyMMddHHmmss')
$memoryOptRunOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath "MemoryOpt_$timestamp"
$memoryOptRunOutputPath = New-DirectoryIfNotExists -Path $memoryOptRunOutputPath -Purpose "RÃƒÂ©sultats de cette ExÃƒÂ©cution d'Optimisation"
if (-not $memoryOptRunOutputPath) { return }

Write-Host "RÃƒÂ©pertoire de sortie pour cette exÃƒÂ©cution : $memoryOptRunOutputPath" -ForegroundColor Green

# 4. Gestion des donnÃƒÂ©es de test (similaire aux autres scripts)
$actualTestDataPath = $null
$testDataStatus = "Non applicable"

# 4a. VÃƒÂ©rifier le chemin explicite
$actualTestDataPath = $null
$testDataStatus = "Non spÃƒÂ©cifiÃƒÂ©"

if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des donnÃƒÂ©es fournies: $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'est pas valide. Tentative de gÃƒÂ©nÃƒÂ©ration si New-TestData.ps1 existe."
    }
}

# 4b. Tenter la gÃƒÂ©nÃƒÂ©ration si nÃƒÂ©cessaire/forcÃƒÂ©
$testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
$targetGeneratedDataPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath "generated_test_data"
$generate = $false

# VÃƒÂ©rifier si nous devons gÃƒÂ©nÃƒÂ©rer des donnÃƒÂ©es de test
if ((-not $actualTestDataPath -or $ForceTestDataGeneration) -and (Test-Path $testDataScriptPath -PathType Leaf)) {
    # DÃƒÂ©terminer si nous devons gÃƒÂ©nÃƒÂ©rer des donnÃƒÂ©es
    if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
        $generate = $true
    } elseif ($ForceTestDataGeneration) {
        if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et regÃƒÂ©nÃƒÂ©rer les donnÃƒÂ©es de test")) {
            Write-Verbose "ForÃƒÂ§age de la regÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test."
            try {
                Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop
                $generate = $true
            } catch {
                Write-Warning "Impossible de supprimer l'ancien dossier de donnÃƒÂ©es '$targetGeneratedDataPath': $($_.Exception.Message)"
            }
        } else {
            Write-Warning "RegÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e. Utilisation des donnÃƒÂ©es existantes si possible."
            if (Test-Path $targetGeneratedDataPath -PathType Container) {
                $actualTestDataPath = $targetGeneratedDataPath
                $testDataStatus = "Utilisation des donnÃƒÂ©es existantes (regÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e): $actualTestDataPath"
                Write-Verbose $testDataStatus
            } else {
                $testDataStatus = "RegÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e, dossier inexistant."
                Write-Verbose $testDataStatus
            }
        }
    } else {
        # Utiliser les donnÃƒÂ©es existantes
        $actualTestDataPath = $targetGeneratedDataPath
        $testDataStatus = "RÃƒÂ©utilisation des donnÃƒÂ©es prÃƒÂ©cÃƒÂ©demment gÃƒÂ©nÃƒÂ©rÃƒÂ©es: $actualTestDataPath"
        Write-Verbose $testDataStatus
    }

    # GÃƒÂ©nÃƒÂ©rer les donnÃƒÂ©es si nÃƒÂ©cessaire
    if ($generate) {
        if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "GÃƒÂ©nÃƒÂ©rer les donnÃƒÂ©es de test")) {
            Write-Host "GÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
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
                    $testDataStatus = "DonnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es avec succÃƒÂ¨s: $actualTestDataPath"
                    Write-Host $testDataStatus -ForegroundColor Green
                } else {
                    Write-Error "Ãƒâ€°chec de New-TestData.ps1."
                    $testDataStatus = "Ãƒâ€°chec gÃƒÂ©nÃƒÂ©ration."
                    $actualTestDataPath = $null
                }
            } catch {
                Write-Error "Erreur critique New-TestData.ps1: $($_.Exception.Message)"
                $testDataStatus = "Ãƒâ€°chec critique."
                $actualTestDataPath = $null
            }
        } else {
            Write-Warning "GÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e."
            $testDataStatus = "GÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e."

            if ($actualTestDataPath -eq $targetGeneratedDataPath) {
                $testDataStatus += " Utilisation des donnÃƒÂ©es prÃƒÂ©-existantes."
            } else {
                $actualTestDataPath = $null
            }

            Write-Verbose $testDataStatus
        }
    }
} elseif (-not $actualTestDataPath) {
    $testDataStatus = "DonnÃƒÂ©es de test non requises ou non gÃƒÂ©rÃƒÂ©es."
    Write-Verbose $testDataStatus
}

# 4c. Injecter le chemin des donnÃƒÂ©es dans les paramÃƒÂ¨tres des scÃƒÂ©narios
if ($actualTestDataPath) {
    Write-Verbose "Injection du chemin de donnÃƒÂ©es '$actualTestDataPath' dans les scÃƒÂ©narios (paramÃƒÂ¨tre cible: '$TestDataTargetParameterName')."
    foreach ($scenario in $OptimizationScenarios) {
        if ($scenario.Parameters.ContainsKey($TestDataTargetParameterName)) {
            Write-Verbose "  -> ScÃƒÂ©nario '$($scenario.Name)': Mise ÃƒÂ  jour de Parameters['$TestDataTargetParameterName']"
            $scenario.Parameters[$TestDataTargetParameterName] = $actualTestDataPath
        } else {
             Write-Verbose "  -> ScÃƒÂ©nario '$($scenario.Name)': Le paramÃƒÂ¨tre cible '$TestDataTargetParameterName' n'existe pas dans ses Parameters."
             # Optionnel : ajouter le paramÃƒÂ¨tre s'il manque ? Pour l'instant, on suppose qu'il doit exister.
             # $scenario.Parameters[$TestDataTargetParameterName] = $actualTestDataPath
        }
    }
} elseif (-not [string]::IsNullOrEmpty($TestDataTargetParameterName)) {
     Write-Verbose "Aucun chemin de donnÃƒÂ©es effectif ($actualTestDataPath est vide), l'injection du paramÃƒÂ¨tre '$TestDataTargetParameterName' est ignorÃƒÂ©e."
}


# 5. Afficher le contexte d'exÃƒÂ©cution final
Write-Host "Contexte d'exÃƒÂ©cution :" -ForegroundColor Cyan
Write-Host "  - Script Benchmark : $benchmarkScriptPath"
Write-Host "  - ScÃƒÂ©narios ÃƒÂ  Tester: $($scenarioNames -join ', ')"
Write-Host "  - ItÃƒÂ©rations par ScÃƒÂ©nario: $Iterations"
Write-Host "  - GÃƒÂ©nÃƒÂ©ration Rapport HTML: $($GenerateReport.IsPresent)"
Write-Host "  - Statut DonnÃƒÂ©es Test : $testDataStatus"
Write-Verbose "  - ParamÃƒÂ¨tres dÃƒÂ©taillÃƒÂ©s par scÃƒÂ©nario :"
$OptimizationScenarios | ForEach-Object { Write-Verbose "    - Scenario '$($_.Name)': $($_.Parameters | Out-String | Select-Object -Skip 1 | ForEach-Object { '      ' + $_ })" }


Write-Verbose "Validation et Initialisation terminÃƒÂ©es."
#endregion

#region Fonction de GÃƒÂ©nÃƒÂ©ration du Rapport HTML (AdaptÃƒÂ©e pour ScÃƒÂ©narios)

function New-MemoryOptimizationHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [array]$AllScenarioResults, # Tableau des rÃƒÂ©sumÃƒÂ©s retournÃƒÂ©s par Test-ParallelPerformance pour chaque scÃƒÂ©nario
        [Parameter(Mandatory = $true)] [string]$ReportPath,
        [Parameter(Mandatory = $false)] [PSCustomObject]$FastestScenario,
        [Parameter(Mandatory = $false)] [PSCustomObject]$LowestMemoryScenario,
        [Parameter(Mandatory = $false)] [array]$OptimizationScenariosConfig, # La config originale pour afficher les params
        [Parameter(Mandatory = $false)] [int]$IterationsPerScenario,
        [Parameter(Mandatory = $false)] [string]$TestDataInfo,
        [Parameter(Mandatory = $false)] [string]$OutputDirectory
    )

    Write-Host "GÃƒÂ©nÃƒÂ©ration du rapport HTML de comparaison des scÃƒÂ©narios : $ReportPath" -ForegroundColor Cyan

    $validResults = $AllScenarioResults | Where-Object { $null -ne $_ -and $_.PSObject.Properties.ContainsKey('AverageExecutionTimeS') -and $_.AverageExecutionTimeS -ge 0 }
    if ($validResults.Count -eq 0) {
        Write-Warning "Aucune donnÃƒÂ©e de rÃƒÂ©sultat valide pour gÃƒÂ©nÃƒÂ©rer le rapport HTML."
        # Potentiellement crÃƒÂ©er un rapport minimal ici
        return
    }

    # PrÃƒÂ©parer les donnÃƒÂ©es pour JS (Labels = Noms des scÃƒÂ©narios)
    $jsLabels = ConvertTo-JavaScriptData ($validResults.TestName) # Utiliser le TestName qui contient le nom du scÃƒÂ©nario
    $jsAvgTimes = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageExecutionTimeS, 3) })
    $jsAvgCpu = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageProcessorTimeS, 3) })
    $jsAvgWS = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AverageWorkingSetMB, 2) })
    $jsAvgPM = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.AveragePrivateMemoryMB, 2) })
    $jsSuccessRates = ConvertTo-JavaScriptData ($validResults | ForEach-Object { [Math]::Round($_.SuccessRatePercent, 1) })

    # Section de mise en ÃƒÂ©vidence
    $highlightHtml = ""
    if ($LowestMemoryScenario) {
         $highlightHtml += @"
<div class="section optimal" id="lowest-memory">
    <h2>Ã°Å¸â€™Â§ Consommation MÃƒÂ©moire Minimale</h2>
    <p><span class="metric-label">ScÃƒÂ©nario:</span> <span class="optimal-value">$($LowestMemoryScenario.TestName)</span></p>
    <p><span class="metric-label tooltip">MÃƒÂ©moire PrivÃƒÂ©e Moyenne:<span class="tooltiptext">MÃƒÂ©moire non partagÃƒÂ©e moyenne allouÃƒÂ©e. Indicateur clÃƒÂ©.</span></span> $($LowestMemoryScenario.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Temps Moyen Ãƒâ€°coulÃƒÂ©:</span> $($LowestMemoryScenario.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label">Taux de SuccÃƒÂ¨s:</span> $($LowestMemoryScenario.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    }
    if ($FastestScenario) {
         $highlightHtml += @"
<div class="section optimal" id="fastest">
    <h2>Ã¢ÂÂ±Ã¯Â¸Â ExÃƒÂ©cution la Plus Rapide</h2>
    <p><span class="metric-label">ScÃƒÂ©nario:</span> <span class="optimal-value">$($FastestScenario.TestName)</span></p>
    <p><span class="metric-label tooltip">Temps Moyen Ãƒâ€°coulÃƒÂ©:<span class="tooltiptext">DurÃƒÂ©e totale moyenne pour ce scÃƒÂ©nario. Plus bas est mieux.</span></span> $($FastestScenario.AverageExecutionTimeS.ToString('F3')) s</p>
    <p><span class="metric-label">MÃƒÂ©moire PrivÃƒÂ©e Moyenne:</span> $($FastestScenario.AveragePrivateMemoryMB.ToString('F2')) MB</p>
    <p><span class="metric-label">Taux de SuccÃƒÂ¨s:</span> $($FastestScenario.SuccessRatePercent.ToString('F1')) %</p>
</div>
"@
    }
     if (-not $LowestMemoryScenario -and -not $FastestScenario) {
         $highlightHtml = @"
<div class="section warning">
    <h2>Ã¢Å¡Â Ã¯Â¸Â Analyse LimitÃƒÂ©e</h2>
    <p>Impossible de dÃƒÂ©terminer formellement le scÃƒÂ©nario le plus rapide ou celui consommant le moins de mÃƒÂ©moire (probablement dÃƒÂ» ÃƒÂ  des ÃƒÂ©checs ou donnÃƒÂ©es manquantes).</p>
</div>
"@
     }


    # Table des dÃƒÂ©tails (gÃƒÂ©nÃƒÂ©rÃƒÂ©e via boucle)
    $detailsTableRows = $AllScenarioResults | ForEach-Object {
        $scenarioConfig = $OptimizationScenariosConfig | Where-Object { $_.Name -eq $_.TestName } | Select-Object -First 1
        $paramsForScenarioHtml = "<i>Erreur: Config non trouvÃƒÂ©e</i>"
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
    <thead><tr><th>ScÃƒÂ©nario & ParamÃƒÂ¨tres</th><th>Taux SuccÃƒÂ¨s (%)</th><th>Temps Moyen (s)</th><th>CPU Moyen (s)</th><th>WS Moyen (MB)</th><th>PM Moyen (MB)</th><th>Message Principal (si ÃƒÂ©chec)</th></tr></thead>
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
    <title>Rapport Comparaison MÃƒÂ©moire/Perf par ScÃƒÂ©nario</title>
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
    <h1>Rapport Comparaison MÃƒÂ©moire/Performance par ScÃƒÂ©nario</h1>
    <div class="section" id="context">
        <h2>Contexte de l'ExÃƒÂ©cution</h2>
        <p><span class="metric-label">GÃƒÂ©nÃƒÂ©rÃƒÂ© le:</span> $(Get-Date -Format "yyyy-MM-dd 'ÃƒÂ ' HH:mm:ss")</p>
        <p><span class="metric-label">Nombre de ScÃƒÂ©narios TestÃƒÂ©s:</span> $($AllScenarioResults.Count)</p>
        <p><span class="metric-label">ItÃƒÂ©rations par ScÃƒÂ©nario:</span> $IterationsPerScenario</p>
        <p><span class="metric-label">Statut DonnÃƒÂ©es Test:</span> $TestDataInfo</p>
        <p><span class="metric-label">RÃƒÂ©pertoire des RÃƒÂ©sultats:</span> <code>$OutputDirectory</code></p>
    </div>

    $highlightHtml

    <div class="section" id="detailed-results">
        <h2>RÃƒÂ©sultats Comparatifs DÃƒÂ©taillÃƒÂ©s par ScÃƒÂ©nario</h2>
        $detailsTableHtml
        <p class="notes"><i>Les mÃƒÂ©triques sont moyennÃƒÂ©es sur $IterationsPerScenario exÃƒÂ©cutions pour chaque scÃƒÂ©nario.</i></p>
    </div>

    <div class="section" id="charts">
        <h2>Graphiques Comparatifs des ScÃƒÂ©narios</h2>
        <div class="chart-container"><canvas id="timeChart"></canvas></div>
        <div class="chart-container"><canvas id="memoryChart"></canvas></div>
        <div class="chart-container"><canvas id="successRateChart"></canvas></div>
    </div>
<script>
    const scenarioLabels = $jsLabels;
    const commonChartOptions = { /* Options communes identiques ÃƒÂ  Optimize-ParallelBatchSize */
        scales: { x: { title: { display: true, text: 'ScÃƒÂ©nario de Test', font: { size: 14 } } }, y: { beginAtZero: true, title: { display: true, font: { size: 14 } } } },
        responsive: true, maintainAspectRatio: false, interaction: { intersect: false, mode: 'index' },
        plugins: { legend: { position: 'top', labels: { font: { size: 13 } } }, title: { display: true, font: { size: 18, weight: 'bold' } } }
    };
    const createChart = (canvasId, config) => { if (document.getElementById(canvasId)) { new Chart(document.getElementById(canvasId).getContext('2d'), config); }};

    // Time Chart
    createChart('timeChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [ // Bar chart better for comparing distinct scenarios
        { label: 'Temps Ãƒâ€°coulÃƒÂ© Moyen (s)', data: $jsAvgTimes, backgroundColor: 'rgba(220, 53, 69, 0.7)', borderColor: 'rgb(220, 53, 69)', borderWidth: 1, yAxisID: 'yTime' },
        { label: 'Temps CPU Moyen (s)', data: $jsAvgCpu, backgroundColor: 'rgba(13, 110, 253, 0.7)', borderColor: 'rgb(13, 110, 253)', borderWidth: 1, yAxisID: 'yTime' } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Performance Temps par ScÃƒÂ©nario'} }, scales: { ...commonChartOptions.scales, yTime: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [ // Bar chart better here too
        { label: 'Working Set Moyen (MB)', data: $jsAvgWS, backgroundColor: 'rgba(25, 135, 84, 0.7)', borderColor: 'rgb(25, 135, 84)', borderWidth: 1, yAxisID: 'yMemory' },
        { label: 'MÃƒÂ©moire PrivÃƒÂ©e Moyenne (MB)', data: $jsAvgPM, backgroundColor: 'rgba(108, 117, 125, 0.7)', borderColor: 'rgb(108, 117, 125)', borderWidth: 1, yAxisID: 'yMemory' } ] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Utilisation MÃƒÂ©moire par ScÃƒÂ©nario'} }, scales: { ...commonChartOptions.scales, yMemory: { ...commonChartOptions.scales.y, title: { ...commonChartOptions.scales.y.title, text: 'MB'}}} }
    });

    // Success Rate Chart
    createChart('successRateChart', { type: 'bar', data: { labels: scenarioLabels, datasets: [{ label: 'Taux de SuccÃƒÂ¨s (%)', data: $jsSuccessRates, backgroundColor: 'rgba(255, 193, 7, 0.7)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1 }] },
        options: { ...commonChartOptions, plugins: { ...commonChartOptions.plugins, title: { ...commonChartOptions.plugins.title, text: 'Taux de SuccÃƒÂ¨s par ScÃƒÂ©nario'} }, scales: { ...commonChartOptions.scales, y: { ...commonChartOptions.scales.y, min: 0, max: 100, title: { ...commonChartOptions.scales.y.title, text: '%' } } } }
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
    }
}

#endregion

#region ExÃƒÂ©cution Principale du Benchmarking

Write-Host "`n=== DÃƒÂ©marrage des Tests par ScÃƒÂ©nario ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan

$allScenarioResultsList = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalScenarios = $OptimizationScenarios.Count
$currentScenarioIndex = 0

# Boucle sur chaque scÃƒÂ©nario dÃƒÂ©fini
foreach ($scenario in $OptimizationScenarios) {
    $currentScenarioIndex++
    $scenarioName = $scenario.Name
    $scenarioParameters = $scenario.Parameters

    $progressParams = @{
        Activity = "Optimisation MÃƒÂ©moire par ScÃƒÂ©narios"
        Status   = "Test ScÃƒÂ©nario '$scenarioName' ($currentScenarioIndex/$totalScenarios)"
        PercentComplete = (($currentScenarioIndex -1) / $totalScenarios) * 100
        CurrentOperation = "PrÃƒÂ©paration..."
    }
    Write-Progress @progressParams

    Write-Host "`n--- Test ScÃƒÂ©nario : '$scenarioName' ($currentScenarioIndex/$totalScenarios) ---" -ForegroundColor Yellow
    Write-Verbose "ParamÃƒÂ¨tres spÃƒÂ©cifiques pour ce scÃƒÂ©nario :"
    Write-Verbose ($scenarioParameters | Out-String)

    # Nom unique pour l'appel ÃƒÂ  Test-ParallelPerformance
    # Utiliser le nom du scÃƒÂ©nario pour identifier facilement les logs/rapports intermÃƒÂ©diaires
    $safeScenarioName = $scenarioName -replace '[^a-zA-Z0-9_.-]+', '_' -replace '^[_.-]+|[_.-]+$'
    $benchmarkTestName = $safeScenarioName # Utiliser directement le nom nettoyÃƒÂ© du scÃƒÂ©nario

    # PrÃƒÂ©parer les paramÃƒÂ¨tres pour Test-ParallelPerformance.ps1
    $benchmarkParams = @{
        ScriptBlock         = $ScriptBlock             # Le mÃƒÂªme pour tous les scÃƒÂ©narios
        Parameters          = $scenarioParameters      # ParamÃƒÂ¨tres SPÃƒâ€°CIFIQUES ÃƒÂ  ce scÃƒÂ©nario
        TestName            = $benchmarkTestName       # Nom basÃƒÂ© sur le scÃƒÂ©nario
        OutputPath          = $memoryOptRunOutputPath  # Sortie DANS le dossier global de l'optimisation
        Iterations          = $Iterations              # Nombre de rÃƒÂ©pÃƒÂ©titions pour ce scÃƒÂ©nario
        GenerateReport      = $false # Pas de rapport HTML individuel par scÃƒÂ©nario
        NoGarbageCollection = $true # Laisser Test-ParallelPerformance dÃƒÂ©cider (ou ajouter un switch ici si besoin)
        ErrorAction         = 'Continue'               # Capturer les erreurs de Test-ParallelPerformance
    }

    $scenarioResultSummary = $null
    $benchmarkError = $null

    try {
        Write-Progress @progressParams -CurrentOperation "ExÃƒÂ©cution de Test-ParallelPerformance ($Iterations itÃƒÂ©rations)..."
        Write-Verbose "Lancement de Test-ParallelPerformance.ps1 pour le scÃƒÂ©nario '$scenarioName'..."

        # ExÃƒÂ©cuter le benchmark pour ce scÃƒÂ©nario
        $scenarioResultSummary = & $benchmarkScriptPath @benchmarkParams -ErrorVariable +benchmarkError

        if ($benchmarkError) {
            Write-Warning "Erreurs non bloquantes lors de l'exÃƒÂ©cution du scÃƒÂ©nario '$scenarioName':"
            $benchmarkError | ForEach-Object { Write-Warning ('    ' + $_.ToString()) }
        }
         Write-Progress @progressParams -CurrentOperation "Benchmark terminÃƒÂ©"

    } catch {
        # Erreur critique arrÃƒÂªtant Test-ParallelPerformance
        Write-Error "Ãƒâ€°chec critique lors de l'exÃƒÂ©cution du scÃƒÂ©nario '$scenarioName'. Erreur : $($_.Exception.Message)"
        $benchmarkError = $_
    }

    # Traiter le rÃƒÂ©sultat du benchmark pour ce scÃƒÂ©nario
    if ($scenarioResultSummary -is [PSCustomObject] -and $scenarioResultSummary.PSObject.Properties.Name -contains 'AverageExecutionTimeS') {
        # RÃƒÂ©sultat valide
        $scenarioResultSummary | Add-Member -MemberType NoteProperty -Name "ScenarioName" -Value $scenarioName -Force # Ajouter le nom du scÃƒÂ©nario au rÃƒÂ©sultat
        $scenarioResultSummary | Add-Member -MemberType NoteProperty -Name "Status" -Value "Completed" -Force
        $allScenarioResultsList.Add($scenarioResultSummary)
        Write-Host ("RÃƒÂ©sultat enregistrÃƒÂ© pour ScÃƒÂ©nario '{0}': TempsMoyen={1:F3}s, SuccÃƒÂ¨s={2:F1}%, MemPrivMoy={3:F2}MB" -f `
            $scenarioName, $scenarioResultSummary.AverageExecutionTimeS,
            $scenarioResultSummary.SuccessRatePercent, $scenarioResultSummary.AveragePrivateMemoryMB) -ForegroundColor Green
    } else {
        # Ãƒâ€°chec ou rÃƒÂ©sultat invalide
        $failureReason = if($benchmarkError) { $benchmarkError[0].ToString() } else { "Test-ParallelPerformance n'a pas retournÃƒÂ© un objet de rÃƒÂ©sumÃƒÂ© valide." }
        Write-Warning "Le test pour le scÃƒÂ©nario '$scenarioName' a ÃƒÂ©chouÃƒÂ© ou n'a pas retournÃƒÂ© de rÃƒÂ©sumÃƒÂ© valide. Raison: $failureReason"
        $failedResult = [PSCustomObject]@{
            ScenarioName          = $scenarioName
            TestName              = $benchmarkTestName # Garder le nom passÃƒÂ© au benchmark
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
     Write-Progress @progressParams -PercentComplete ($currentScenarioIndex / $totalScenarios * 100) -CurrentOperation "TerminÃƒÂ©"

} # Fin de la boucle foreach ($scenario in $OptimizationScenarios)

Write-Progress @progressParams -Activity "Optimisation MÃƒÂ©moire par ScÃƒÂ©narios" -Status "Analyse finale des rÃƒÂ©sultats..." -Completed

#endregion

#region Analyse Finale et GÃƒÂ©nÃƒÂ©ration des Rapports

Write-Host "`n=== Analyse Finale des RÃƒÂ©sultats ($($allScenarioResultsList.Count) scÃƒÂ©narios testÃƒÂ©s) ===" -ForegroundColor Cyan

$finalResultsArray = $allScenarioResultsList.ToArray() # Convertir en tableau

if ($finalResultsArray.Length -eq 0) {
     Write-Warning "Aucun rÃƒÂ©sultat de scÃƒÂ©nario n'a ÃƒÂ©tÃƒÂ© collectÃƒÂ©. Impossible d'analyser ou de gÃƒÂ©nÃƒÂ©rer des rapports."
     return $null
}

# Identifier les meilleurs scÃƒÂ©narios (parmi ceux avec rÃƒÂ©sultats valides)
$validResults = $finalResultsArray | Where-Object { $_.AverageExecutionTimeS -ge 0 }
$fastestScenario = $null
$lowestMemoryScenario = $null

if ($validResults.Length -gt 0) {
    $fastestScenario = $validResults | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1
    $lowestMemoryScenario = $validResults | Where-Object {$_.AveragePrivateMemoryMB -ge 0} | Sort-Object -Property AveragePrivateMemoryMB | Select-Object -First 1

    Write-Host "--- Points ClÃƒÂ©s ---" -ForegroundColor Cyan
    if ($fastestScenario) {
        Write-Host ("  - ScÃƒÂ©nario le plus rapide : '{0}' ({1:F3}s)" -f $fastestScenario.TestName, $fastestScenario.AverageExecutionTimeS) -ForegroundColor Green
    } else { Write-Warning "  - Impossible de dÃƒÂ©terminer le scÃƒÂ©nario le plus rapide." }
    if ($lowestMemoryScenario) {
        Write-Host ("  - Consommation mÃƒÂ©moire privÃƒÂ©e la plus basse : '{0}' ({1:F2}MB)" -f $lowestMemoryScenario.TestName, $lowestMemoryScenario.AveragePrivateMemoryMB) -ForegroundColor Green
    } else { Write-Warning "  - Impossible de dÃƒÂ©terminer le scÃƒÂ©nario avec la plus basse mÃƒÂ©moire privÃƒÂ©e."}
} else {
     Write-Warning "Aucun scÃƒÂ©nario n'a produit de rÃƒÂ©sultats valides pour l'analyse."
}

# Enregistrer les rÃƒÂ©sultats agrÃƒÂ©gÃƒÂ©s en JSON
$resultsJsonFileName = "MemoryOptimization_Summary.json"
$resultsJsonPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath $resultsJsonFileName
try {
    # On peut inclure la config des scÃƒÂ©narios dans le JSON pour rÃƒÂ©fÃƒÂ©rence
    $outputJsonData = @{
        ExecutionTimestamp = $startTimestamp
        Configuration = @{
            IterationsPerScenario = $Iterations
            TestDataStatus = $testDataStatus
        }
        ScenariosTested = $OptimizationScenariosConfig # La config originale
        ResultsSummary = $finalResultsArray # Les rÃƒÂ©sumÃƒÂ©s de chaque scÃƒÂ©nario
    }
    ConvertTo-Json -InputObject $outputJsonData -Depth 6 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`nÃ°Å¸â€œÅ  RÃƒÂ©sumÃƒÂ© complet de la comparaison enregistrÃƒÂ© (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement du rÃƒÂ©sumÃƒÂ© JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# GÃƒÂ©nÃƒÂ©rer le rapport HTML comparatif si demandÃƒÂ©
if ($GenerateReport) {
    if ($finalResultsArray.Length -gt 0) {
        $reportHtmlFileName = "MemoryOptimization_Report.html"
        $reportHtmlPath = Join-Path -Path $memoryOptRunOutputPath -ChildPath $reportHtmlFileName
        $reportParams = @{
            AllScenarioResults        = $finalResultsArray
            ReportPath                = $reportHtmlPath
            FastestScenario           = $fastestScenario # Peut ÃƒÂªtre $null
            LowestMemoryScenario      = $lowestMemoryScenario # Peut ÃƒÂªtre $null
            OptimizationScenariosConfig = $OptimizationScenarios # Passer la config pour dÃƒÂ©tails
            IterationsPerScenario     = $Iterations
            TestDataInfo              = $testDataStatus
            OutputDirectory           = $memoryOptRunOutputPath
            ErrorAction               = 'Continue'
        }
        New-MemoryOptimizationHtmlReport @reportParams
    } else {
        Write-Warning "GÃƒÂ©nÃƒÂ©ration du rapport HTML annulÃƒÂ©e car aucun rÃƒÂ©sultat de scÃƒÂ©nario n'a ÃƒÂ©tÃƒÂ© collectÃƒÂ©."
    }
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Comparaison MÃƒÂ©moire/Performance par ScÃƒÂ©narios TerminÃƒÂ©e ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "DurÃƒÂ©e totale du script d'optimisation : $($totalDuration.ToString('g'))"

#endregion

# Retourner le tableau des rÃƒÂ©sultats rÃƒÂ©sumÃƒÂ©s pour chaque scÃƒÂ©nario
return $finalResultsArray