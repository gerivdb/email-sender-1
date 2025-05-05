# Script pour gÃ©nÃ©rer un badge de couverture de code pour le README.md

# DÃ©finir les paramÃ¨tres
param (
    [Parameter(Mandatory = $false)]
    [string]$CoverageReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\tests\mode-manager-coverage.xml"),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\badges"),

    [Parameter(Mandatory = $false)]
    [string]$ReadmePath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\README.md")
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

# Lire le fichier de rapport de couverture
$coverageReport = [xml](Get-Content -Path $CoverageReportPath -Encoding UTF8)

# Calculer le pourcentage de couverture
$totalLines = 0
$coveredLines = 0

foreach ($package in $coverageReport.report.package) {
    foreach ($class in $package.class) {
        foreach ($line in $class.line) {
            $totalLines++
            if ($line.ci -eq "true") {
                $coveredLines++
            }
        }
    }
}

$coveragePercentage = if ($totalLines -gt 0) { [math]::Round(($coveredLines / $totalLines) * 100, 2) } else { 0 }

# DÃ©terminer la couleur du badge
$color = switch ($coveragePercentage) {
    { $_ -ge 90 } { "brightgreen" }
    { $_ -ge 80 } { "green" }
    { $_ -ge 70 } { "yellowgreen" }
    { $_ -ge 60 } { "yellow" }
    { $_ -ge 50 } { "orange" }
    default { "red" }
}

# GÃ©nÃ©rer l'URL du badge
$badgeUrl = "https://img.shields.io/badge/coverage-$coveragePercentage%25-$color"

# TÃ©lÃ©charger le badge
$badgePath = Join-Path -Path $OutputPath -ChildPath "coverage-badge.svg"
Invoke-WebRequest -Uri $badgeUrl -OutFile $badgePath

# Afficher les informations
Write-Host "Couverture de code : $coveragePercentage%" -ForegroundColor Cyan
Write-Host "Badge gÃ©nÃ©rÃ© : $badgePath" -ForegroundColor Cyan

# Mettre Ã  jour le README.md si le fichier existe
if (Test-Path -Path $ReadmePath) {
    $readme = Get-Content -Path $ReadmePath -Raw
    
    # VÃ©rifier si le badge existe dÃ©jÃ 
    $badgePattern = "!\[Coverage\]\(https://img\.shields\.io/badge/coverage-[0-9\.]+%25-[a-z]+\)"
    
    if ($readme -match $badgePattern) {
        # Mettre Ã  jour le badge existant
        $newBadge = "![Coverage]($badgeUrl)"
        $readme = $readme -replace $badgePattern, $newBadge
    } else {
        # Ajouter le badge
        $newBadge = "![Coverage]($badgeUrl)"
        $readme = $readme -replace "# Mode Manager", "# Mode Manager`n`n$newBadge"
    }
    
    # Enregistrer le README.md
    $readme | Set-Content -Path $ReadmePath -Encoding UTF8
    
    Write-Host "README.md mis Ã  jour avec le badge de couverture" -ForegroundColor Green
}

# GÃ©nÃ©rer un fichier JSON pour les services de badge
$jsonPath = Join-Path -Path $OutputPath -ChildPath "coverage.json"
@{
    schemaVersion = 1
    label = "coverage"
    message = "$coveragePercentage%"
    color = $color
} | ConvertTo-Json | Set-Content -Path $jsonPath -Encoding UTF8

Write-Host "Fichier JSON gÃ©nÃ©rÃ© : $jsonPath" -ForegroundColor Cyan

exit 0
