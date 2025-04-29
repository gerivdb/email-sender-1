# Script pour générer un rapport de couverture de code détaillé

# Définir les paramètres
param (
    [Parameter(Mandatory = $false)]
    [string]$CoverageReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\tests\mode-manager-coverage.xml"),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\coverage"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Html", "HtmlSummary", "Cobertura", "SonarQube", "Badges")]
    [string[]]$ReportTypes = @("Html", "HtmlSummary", "Badges")
)

# Vérifier que le fichier de rapport de couverture existe
if (-not (Test-Path -Path $CoverageReportPath)) {
    Write-Error "Le fichier de rapport de couverture est introuvable à l'emplacement : $CoverageReportPath"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Vérifier si le module ReportGenerator est installé
if (-not (Get-Module -Name ReportGenerator -ListAvailable)) {
    Write-Warning "Le module ReportGenerator n'est pas installé. Installation en cours..."
    Install-Module -Name ReportGenerator -Force -SkipPublisherCheck
}

# Générer le rapport de couverture
try {
    Import-Module -Name ReportGenerator
    
    $reportTypesString = $ReportTypes -join ";"
    
    ConvertTo-ReportGeneratorReport -InputFile $CoverageReportPath -OutputFile $OutputPath -ReportType $reportTypesString
    
    Write-Host "Rapport de couverture généré : $OutputPath" -ForegroundColor Green
} catch {
    Write-Error "Impossible de générer le rapport de couverture : $_"
    exit 1
}

# Générer un fichier de synthèse
$summaryPath = Join-Path -Path $OutputPath -ChildPath "summary.md"

# Lire le fichier de rapport de couverture
$coverageReport = [xml](Get-Content -Path $CoverageReportPath -Encoding UTF8)

# Calculer le pourcentage de couverture
$totalLines = 0
$coveredLines = 0
$classCoverage = @{}

foreach ($package in $coverageReport.report.package) {
    foreach ($class in $package.class) {
        $className = $class.name
        $classLines = 0
        $classCoveredLines = 0
        
        foreach ($line in $class.line) {
            $totalLines++
            $classLines++
            
            if ($line.ci -eq "true") {
                $coveredLines++
                $classCoveredLines++
            }
        }
        
        $classPercentage = if ($classLines -gt 0) { [math]::Round(($classCoveredLines / $classLines) * 100, 2) } else { 0 }
        $classCoverage[$className] = @{
            Lines = $classLines
            CoveredLines = $classCoveredLines
            Percentage = $classPercentage
        }
    }
}

$coveragePercentage = if ($totalLines -gt 0) { [math]::Round(($coveredLines / $totalLines) * 100, 2) } else { 0 }

# Générer le contenu du fichier de synthèse
$summaryContent = @"
# Rapport de couverture de code

## Résumé

- **Date de génération** : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Fichier de rapport** : $CoverageReportPath
- **Lignes totales** : $totalLines
- **Lignes couvertes** : $coveredLines
- **Pourcentage de couverture** : $coveragePercentage%

## Couverture par fichier

| Fichier | Lignes | Couvertes | Pourcentage |
|---------|--------|-----------|-------------|
"@

foreach ($className in ($classCoverage.Keys | Sort-Object)) {
    $coverage = $classCoverage[$className]
    $summaryContent += "| $className | $($coverage.Lines) | $($coverage.CoveredLines) | $($coverage.Percentage)% |`n"
}

$summaryContent | Set-Content -Path $summaryPath -Encoding UTF8

Write-Host "Fichier de synthèse généré : $summaryPath" -ForegroundColor Green

# Ouvrir le rapport HTML si disponible
if ($ReportTypes -contains "Html") {
    $htmlReportPath = Join-Path -Path $OutputPath -ChildPath "index.htm"
    if (Test-Path -Path $htmlReportPath) {
        Write-Host "Ouverture du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
        Start-Process $htmlReportPath
    }
}

exit 0
