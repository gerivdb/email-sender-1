<#
.SYNOPSIS
    Framework pour l'exécution progressive des tests Pester.

.DESCRIPTION
    Ce module fournit une infrastructure pour organiser et exécuter les tests Pester
    de manière progressive, en les divisant en 4 phases distinctes:
    - Phase 1 (P1): Tests basiques pour les fonctionnalités essentielles
    - Phase 2 (P2): Tests de robustesse avec valeurs limites et cas particuliers
    - Phase 3 (P3): Tests d'exceptions pour la gestion des erreurs
    - Phase 4 (P4): Tests avancés pour les scénarios complexes

    Cette approche permet de structurer les tests de manière cohérente et de les
    exécuter progressivement, en commençant par les tests les plus simples et en
    terminant par les tests les plus complexes.

.NOTES
    Version:        1.0.0
    Auteur:         UnifiedParallel Team
    Date création:  2023-05-20
#>

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

# Constantes pour les phases de test
New-Variable -Name 'TEST_PHASE_BASIC' -Value 'P1' -Option Constant -Scope Script
New-Variable -Name 'TEST_PHASE_ROBUST' -Value 'P2' -Option Constant -Scope Script
New-Variable -Name 'TEST_PHASE_EXCEPTION' -Value 'P3' -Option Constant -Scope Script
New-Variable -Name 'TEST_PHASE_ADVANCED' -Value 'P4' -Option Constant -Scope Script

# Constantes pour les descriptions des phases
New-Variable -Name 'TEST_PHASE_DESCRIPTIONS' -Value @{
    'P1' = 'Tests basiques pour les fonctionnalités essentielles'
    'P2' = 'Tests de robustesse avec valeurs limites et cas particuliers'
    'P3' = 'Tests d''exceptions pour la gestion des erreurs'
    'P4' = 'Tests avancés pour les scénarios complexes'
} -Option Constant -Scope Script

<#
.SYNOPSIS
    Exécute les tests Pester pour une phase spécifique.

.DESCRIPTION
    Cette fonction exécute les tests Pester pour une phase spécifique en utilisant
    les tags définis dans les fichiers de test.

.PARAMETER Path
    Chemin vers le répertoire ou le fichier contenant les tests Pester.

.PARAMETER Phase
    Phase de test à exécuter. Valeurs possibles: P1, P2, P3, P4, All.
    Par défaut: All (toutes les phases).

.PARAMETER PassThru
    Indique si la fonction doit retourner l'objet de résultat Pester.
    Par défaut: $false.

.PARAMETER CodeCoverage
    Indique si la couverture de code doit être mesurée.
    Par défaut: $false.

.PARAMETER CodeCoveragePath
    Chemin vers les fichiers à inclure dans la mesure de couverture de code.
    Par défaut: $null.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour les résultats des tests.
    Par défaut: $null.

.PARAMETER OutputFormat
    Format du fichier de sortie. Valeurs possibles: NUnitXml, JUnitXml.
    Par défaut: NUnitXml.

.EXAMPLE
    Invoke-ProgressiveTest -Path ".\tests" -Phase P1

    Exécute les tests de phase 1 (tests basiques) dans le répertoire ".\tests".

.EXAMPLE
    Invoke-ProgressiveTest -Path ".\tests" -Phase All -CodeCoverage -CodeCoveragePath ".\src"

    Exécute tous les tests dans le répertoire ".\tests" et mesure la couverture de code
    pour les fichiers dans le répertoire ".\src".

.OUTPUTS
    Si PassThru est spécifié, retourne l'objet de résultat Pester.
#>
function Invoke-ProgressiveTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet('P1', 'P2', 'P3', 'P4', 'All')]
        [string]$Phase = 'All',

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [switch]$CodeCoverage,

        [Parameter(Mandatory = $false)]
        [string[]]$CodeCoveragePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet('NUnitXml', 'JUnitXml')]
        [string]$OutputFormat = 'NUnitXml'
    )

    # Configurer les options Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $Path
    $pesterConfig.Output.Verbosity = 'Detailed'

    # Configurer les tags en fonction de la phase
    if ($Phase -ne 'All') {
        $pesterConfig.Filter.Tag = $Phase
    }

    # Configurer la couverture de code si demandée
    if ($CodeCoverage -and $CodeCoveragePath) {
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = $CodeCoveragePath
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
        $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "coverage_$Phase.xml"
    }

    # Configurer le fichier de sortie si spécifié
    if ($OutputFile) {
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = $OutputFormat
        $pesterConfig.TestResult.OutputPath = $OutputFile
    }

    # Afficher les informations sur la phase de test
    if ($Phase -eq 'All') {
        Write-Host "Exécution de tous les tests dans $Path" -ForegroundColor Cyan
    } else {
        Write-Host "Exécution des tests de phase $Phase ($($TEST_PHASE_DESCRIPTIONS[$Phase])) dans $Path" -ForegroundColor Cyan
    }

    # Exécuter les tests
    $results = Invoke-Pester -Configuration $pesterConfig

    # Afficher un résumé des résultats
    Write-Host "Résultats des tests:" -ForegroundColor Cyan
    Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor White
    Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
    Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor Red
    Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Durée totale: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

    # Retourner les résultats si demandé
    if ($PassThru) {
        return $results
    }
}

<#
.SYNOPSIS
    Génère un rapport de couverture de code par phase de test.

.DESCRIPTION
    Cette fonction génère un rapport de couverture de code pour chaque phase de test
    et un rapport global pour toutes les phases.

.PARAMETER CoveragePath
    Chemin vers les fichiers de couverture de code générés par Invoke-ProgressiveTest.

.PARAMETER OutputPath
    Chemin vers le répertoire où les rapports de couverture seront générés.
    Par défaut: le répertoire courant.

.PARAMETER ModulePath
    Chemin vers les fichiers du module à inclure dans le rapport de couverture.
    Par défaut: $null.

.EXAMPLE
    Get-ProgressiveTestCoverage -CoveragePath ".\coverage" -OutputPath ".\reports" -ModulePath ".\src"

    Génère des rapports de couverture de code pour chaque phase de test et un rapport global
    à partir des fichiers de couverture dans le répertoire ".\coverage", et les enregistre
    dans le répertoire ".\reports".

.OUTPUTS
    PSCustomObject avec les informations de couverture par phase.
#>
function Get-ProgressiveTestCoverage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CoveragePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = '.',

        [Parameter(Mandatory = $false)]
        [string]$ModulePath
    )

    # Vérifier que le répertoire de couverture existe
    if (-not (Test-Path -Path $CoveragePath)) {
        throw "Le répertoire de couverture $CoveragePath n'existe pas."
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Récupérer les fichiers de couverture par phase
    $coverageFiles = @{
        'P1'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P1.xml" -ErrorAction SilentlyContinue
        'P2'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P2.xml" -ErrorAction SilentlyContinue
        'P3'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P3.xml" -ErrorAction SilentlyContinue
        'P4'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P4.xml" -ErrorAction SilentlyContinue
        'All' = Get-ChildItem -Path $CoveragePath -Filter "coverage_All.xml" -ErrorAction SilentlyContinue
    }

    # Initialiser l'objet de résultat
    $coverageResults = [PSCustomObject]@{
        P1  = $null
        P2  = $null
        P3  = $null
        P4  = $null
        All = $null
    }

    # Traiter chaque phase
    foreach ($phase in @('P1', 'P2', 'P3', 'P4', 'All')) {
        $file = $coverageFiles[$phase]
        if ($file) {
            # Analyser le fichier de couverture
            $coverageXml = [xml](Get-Content -Path $file.FullName)
            $totalLines = 0
            $coveredLines = 0

            # Calculer la couverture
            foreach ($package in $coverageXml.report.package) {
                foreach ($class in $package.class) {
                    foreach ($line in $class.line) {
                        $totalLines++
                        if ([int]$line.ci -gt 0) {
                            $coveredLines++
                        }
                    }
                }
            }

            # Calculer le pourcentage de couverture
            $coveragePercent = if ($totalLines -gt 0) { [math]::Round(($coveredLines / $totalLines) * 100, 2) } else { 0 }

            # Stocker les résultats
            $coverageResults.$phase = [PSCustomObject]@{
                TotalLines      = $totalLines
                CoveredLines    = $coveredLines
                CoveragePercent = $coveragePercent
                FilePath        = $file.FullName
            }

            # Générer un rapport HTML
            $reportPath = Join-Path -Path $OutputPath -ChildPath "coverage_$phase.html"

            # Déterminer la classe CSS pour le pourcentage de couverture
            $coverageClass = if ($coveragePercent -ge 80) { 'good' } elseif ($coveragePercent -ge 60) { 'warning' } else { 'bad' }

            # Créer le contenu HTML
            $reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de couverture de code - Phase $phase</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .good { color: green; }
        .warning { color: orange; }
        .bad { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de couverture de code - Phase $phase</h1>
    <div class="summary">
        <p>Total des lignes: $totalLines</p>
        <p>Lignes couvertes: $coveredLines</p>
        <p>Pourcentage de couverture: <span class="$coverageClass">$coveragePercent%</span></p>
    </div>
</body>
</html>
"@
            Set-Content -Path $reportPath -Value $reportContent
            Write-Host "Rapport de couverture pour la phase $phase genere: $reportPath" -ForegroundColor Green
        } else {
            Write-Host "Aucun fichier de couverture trouvé pour la phase $phase" -ForegroundColor Yellow
        }
    }

    return $coverageResults
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Invoke-ProgressiveTest, Get-ProgressiveTestCoverage
