# Test-DecimalValues.ps1
# Script de test pour l'extraction des valeurs d'estimation avec décimales
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$metadataDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "metadata"
$scriptPath = Join-Path -Path $metadataDir -ChildPath "Get-EstimationValues.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script à tester n'existe pas: $scriptPath"
    exit 1
}

# Créer un exemple de texte contenant des expressions d'estimation avec des valeurs décimales
$testText = @"
Cette tâche prendra environ 3,5 jours.
Le développement durera à peu près 2.5 semaines.
La mise en place devrait prendre plus ou moins 5,5 heures.
Cette fonctionnalité nécessitera autour de 10.25 jours de travail.
Le temps de développement est estimé à 4,75 jours.
"@

# Exécuter le script avec le texte de test
Write-Host "Exécution du script avec le texte de test:" -ForegroundColor Cyan
Write-Host $testText -ForegroundColor Gray
Write-Host ""

# Exécuter le script directement
Write-Host "Résultat de l'exécution du script:" -ForegroundColor Cyan
$result = & $scriptPath -InputText $testText
Write-Host $result -ForegroundColor Gray
