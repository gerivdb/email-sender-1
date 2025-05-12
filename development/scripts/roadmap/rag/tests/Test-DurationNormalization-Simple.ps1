# Test-DurationNormalization-Simple.ps1
# Script pour tester la normalisation des durees (version simplifiee)
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param ()

# Importer le script de normalisation
$scriptPath = $PSScriptRoot
$normalizeDurationScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Normalize-DurationValues.ps1"

if (-not (Test-Path -Path $normalizeDurationScriptPath)) {
    Write-Host "Le script de normalisation des durees n'existe pas: $normalizeDurationScriptPath"
    exit 1
}

# Creer un contenu de test simple
$testContent = @"
# Test simple

- [ ] **1.1** Tache avec duree en jours (duree: 5 jours)
- [ ] **2.1** Tache avec duree en heures (duree: 8 heures)
"@

# Tester la fonction de conversion directement
Write-Host "Test de la fonction Convert-ToStandardUnit..."

# Importer la fonction depuis le script
. $normalizeDurationScriptPath

# Tester la conversion de jours en heures
$joursEnHeures = Convert-ToStandardUnit -Value 5 -SourceUnit "jours" -TargetUnit "Hours"
Write-Host "5 jours = $joursEnHeures heures"

# Tester la conversion d'heures en jours
$heuresEnJours = Convert-ToStandardUnit -Value 8 -SourceUnit "heures" -TargetUnit "Days"
Write-Host "8 heures = $heuresEnJours jours"

# Tester la conversion de semaines en heures
$semainesEnHeures = Convert-ToStandardUnit -Value 2 -SourceUnit "semaines" -TargetUnit "Hours"
Write-Host "2 semaines = $semainesEnHeures heures"

# Tester la conversion de mois en jours
$moisEnJours = Convert-ToStandardUnit -Value 1 -SourceUnit "mois" -TargetUnit "Days"
Write-Host "1 mois = $moisEnJours jours"

# Verifier les resultats
$success = $true

if ($joursEnHeures -ne 40) {
    Write-Host "Erreur: 5 jours devrait etre egal a 40 heures, mais a donne $joursEnHeures"
    $success = $false
}

if ($heuresEnJours -ne 1) {
    Write-Host "Erreur: 8 heures devrait etre egal a 1 jour, mais a donne $heuresEnJours"
    $success = $false
}

if ($semainesEnHeures -ne 80) {
    Write-Host "Erreur: 2 semaines devrait etre egal a 80 heures, mais a donne $semainesEnHeures"
    $success = $false
}

if ($moisEnJours -ne 20) {
    Write-Host "Erreur: 1 mois devrait etre egal a 20 jours, mais a donne $moisEnJours"
    $success = $false
}

if ($success) {
    Write-Host "Tous les tests de conversion ont reussi!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Certains tests de conversion ont echoue." -ForegroundColor Red
    exit 1
}
