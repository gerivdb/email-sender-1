# Script pour gÃ©nÃ©rer un rapport de couverture de code dÃ©taillÃ©

# DÃ©finir les paramÃ¨tres
param (
    [Parameter(Mandatory = $false)]
    [string]$CoverageReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\tests\mode-manager-coverage.xml"),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\coverage"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Html", "HtmlSummary", "Cobertura", "SonarQube", "Badges")]
    [string[]]$ReportTypes = @("Html", "HtmlSummary", "Badges")
)

# VÃ©rifier que le fichier de rapport de couverture existe
if (-not (Test-Path -Path $CoverageReportPath)) {
    Write-Error "Le fichier de rapport de couverture est introuvable Ã  l'emplacement : $CoverageReportPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# VÃ©rifier si le module ReportGenerator est installÃ©
if (-not (Get-Module -Name ReportGenerator -ListAvailable)) {
    Write-Warning "Le module ReportGenerator n'est pas installÃ©. Installation en cours..."
    Install-Module -Name ReportGenerator -Force -SkipPublisherCheck
}

# GÃ©nÃ©rer le rapport de couverture
try {
    Import-Module -Name ReportGenerator
    
    $reportTypesString = $ReportTypes -join ";"
    
    ConvertTo-ReportGeneratorReport -InputFile $CoverageReportPath -OutputFile $OutputPath -ReportType $reportTypesString
    
    Write-Host "Rapport de couverture gÃ©nÃ©rÃ© : $OutputPath" -ForegroundColor Green
} catch {
    Write-Error "Impossible de gÃ©nÃ©rer le rapport de couverture : $_"
    exit 1
}

# GÃ©nÃ©rer un fichier de synthÃ¨se
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

# GÃ©nÃ©rer le contenu du fichier de synthÃ¨se
$summaryContent = @"
# Rapport de couverture de code

## RÃ©sumÃ©

- **Date de gÃ©nÃ©ration** : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
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

Write-Host "Fichier de synthÃ¨se gÃ©nÃ©rÃ© : $summaryPath" -ForegroundColor Green

# Ouvrir le rapport HTML si disponible
if ($ReportTypes -contains "Html") {
    $htmlReportPath = Join-Path -Path $OutputPath -ChildPath "index.htm"
    if (Test-Path -Path $htmlReportPath) {
        Write-Host "Ouverture du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
        Start-Process $htmlReportPath
    }
}

exit 0
