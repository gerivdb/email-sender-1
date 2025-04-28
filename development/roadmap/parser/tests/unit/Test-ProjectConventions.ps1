# Test-ProjectConventions.ps1
# Script pour tester l'analyse des conventions spÃ©cifiques au projet

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
)

# Importer le module RoadmapAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapAnalyzer.psm1"
Import-Module $modulePath -Force

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Analyser les conventions spÃ©cifiques au projet
Write-Host "Analyse des conventions spÃ©cifiques au projet dans: $RoadmapFilePath" -ForegroundColor Cyan
$conventions = Get-ProjectConventions -Content $content

# Afficher les rÃ©sultats
Write-Host "`nConventions spÃ©cifiques au projet dÃ©tectÃ©es:" -ForegroundColor Green

# Identifiants de tÃ¢ches
Write-Host "`n1. Identifiants de tÃ¢ches:" -ForegroundColor Yellow
if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tÃ¢che spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.TaskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de prioritÃ©
Write-Host "`n2. Indicateurs de prioritÃ©:" -ForegroundColor Yellow
if ($null -eq $conventions.PriorityIndicators.Pattern) {
    Write-Host "  Aucun indicateur de prioritÃ© spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.PriorityIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de statut
Write-Host "`n3. Indicateurs de statut:" -ForegroundColor Yellow
if ($null -eq $conventions.StatusIndicators.Pattern) {
    Write-Host "  Aucun indicateur de statut spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.StatusIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Sections spÃ©ciales
Write-Host "`n4. Sections spÃ©ciales:" -ForegroundColor Yellow
if ($conventions.SpecialSections.Count -eq 0) {
    Write-Host "  Aucune section spÃ©ciale dÃ©tectÃ©e."
} else {
    Write-Host "  Sections dÃ©tectÃ©es:"
    foreach ($section in $conventions.SpecialSections) {
        Write-Host "    - $section"
    }
}

# Format des mÃ©tadonnÃ©es
Write-Host "`n5. Format des mÃ©tadonnÃ©es:" -ForegroundColor Yellow
if ($null -eq $conventions.MetadataFormat) {
    Write-Host "  Aucun format de mÃ©tadonnÃ©es spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($conventions.MetadataFormat)"
}

Write-Host "`nAnalyse terminÃ©e." -ForegroundColor Cyan
