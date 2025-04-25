# Test-ProjectConventions.ps1
# Script pour tester l'analyse des conventions spécifiques au projet

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
)

# Importer le module RoadmapAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapAnalyzer.psm1"
Import-Module $modulePath -Force

# Vérifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Analyser les conventions spécifiques au projet
Write-Host "Analyse des conventions spécifiques au projet dans: $RoadmapFilePath" -ForegroundColor Cyan
$conventions = Get-ProjectConventions -Content $content

# Afficher les résultats
Write-Host "`nConventions spécifiques au projet détectées:" -ForegroundColor Green

# Identifiants de tâches
Write-Host "`n1. Identifiants de tâches:" -ForegroundColor Yellow
if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tâche spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.TaskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de priorité
Write-Host "`n2. Indicateurs de priorité:" -ForegroundColor Yellow
if ($null -eq $conventions.PriorityIndicators.Pattern) {
    Write-Host "  Aucun indicateur de priorité spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.PriorityIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Indicateurs de statut
Write-Host "`n3. Indicateurs de statut:" -ForegroundColor Yellow
if ($null -eq $conventions.StatusIndicators.Pattern) {
    Write-Host "  Aucun indicateur de statut spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.StatusIndicators.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        Write-Host "    - $example"
    }
}

# Sections spéciales
Write-Host "`n4. Sections spéciales:" -ForegroundColor Yellow
if ($conventions.SpecialSections.Count -eq 0) {
    Write-Host "  Aucune section spéciale détectée."
} else {
    Write-Host "  Sections détectées:"
    foreach ($section in $conventions.SpecialSections) {
        Write-Host "    - $section"
    }
}

# Format des métadonnées
Write-Host "`n5. Format des métadonnées:" -ForegroundColor Yellow
if ($null -eq $conventions.MetadataFormat) {
    Write-Host "  Aucun format de métadonnées spécifique détecté."
} else {
    Write-Host "  Format détecté: $($conventions.MetadataFormat)"
}

Write-Host "`nAnalyse terminée." -ForegroundColor Cyan
