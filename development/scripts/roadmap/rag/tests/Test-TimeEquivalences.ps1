# Test-TimeEquivalences.ps1
# Script pour tester le calcul des equivalences temporelles
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param ()

# Importer le script de calcul des equivalences temporelles
$scriptPath = $PSScriptRoot
$getTimeEquivalencesScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Get-TimeEquivalences.ps1"

if (-not (Test-Path -Path $getTimeEquivalencesScriptPath)) {
    Write-Host "Le script de calcul des equivalences temporelles n'existe pas: $getTimeEquivalencesScriptPath"
    exit 1
}

# Tester le calcul des equivalences temporelles
Write-Host "Test du calcul des equivalences temporelles..."

# Test 1: 8 heures en format texte
Write-Host "`nTest 1: 8 heures en format texte"
$result1 = & $getTimeEquivalencesScriptPath -Value 8 -Unit "heures" -OutputFormat "Text"
Write-Host $result1

# Test 2: 5 jours avec toutes les equivalences en format JSON
Write-Host "`nTest 2: 5 jours avec toutes les equivalences en format JSON"
$result2 = & $getTimeEquivalencesScriptPath -Value 5 -Unit "jours" -AllEquivalences -OutputFormat "JSON"
$result2Obj = $result2 | ConvertFrom-Json
Write-Host "Source: $($result2Obj.SourceValue) $($result2Obj.SourceUnit)"
Write-Host "Equivalences:"
foreach ($unit in $result2Obj.Equivalences.PSObject.Properties.Name | Sort-Object) {
    $value = $result2Obj.Equivalences.$unit
    Write-Host "  - ${unit}: $value"
}

# Test 3: 2 semaines en format Markdown
Write-Host "`nTest 3: 2 semaines en format Markdown"
$result3 = & $getTimeEquivalencesScriptPath -Value 2 -Unit "semaines" -OutputFormat "Markdown"
Write-Host $result3

# Test 4: 3 mois en format CSV
Write-Host "`nTest 4: 3 mois en format CSV"
$result4 = & $getTimeEquivalencesScriptPath -Value 3 -Unit "mois" -OutputFormat "CSV"
Write-Host $result4

# Verifier les resultats
$success = $true

# Verifier que les resultats ne sont pas vides
if ([string]::IsNullOrEmpty($result1)) {
    Write-Host "Erreur: Le resultat du test 1 est vide." -ForegroundColor Red
    $success = $false
}

if ([string]::IsNullOrEmpty($result2)) {
    Write-Host "Erreur: Le resultat du test 2 est vide." -ForegroundColor Red
    $success = $false
}

if ([string]::IsNullOrEmpty($result3)) {
    Write-Host "Erreur: Le resultat du test 3 est vide." -ForegroundColor Red
    $success = $false
}

if ([string]::IsNullOrEmpty($result4)) {
    Write-Host "Erreur: Le resultat du test 4 est vide." -ForegroundColor Red
    $success = $false
}

# Verifier que les equivalences sont correctes
if ($result2Obj) {
    # 5 jours = 40 heures
    $hoursValue = $result2Obj.Equivalences.Hours
    if ([Math]::Abs($hoursValue - 40) -gt 0.1) {
        Write-Host "Erreur: 5 jours devrait etre egal a 40 heures, mais a donne $hoursValue" -ForegroundColor Red
        $success = $false
    }

    # 5 jours = 1 semaine
    $weeksValue = $result2Obj.Equivalences.Weeks
    if ([Math]::Abs($weeksValue - 1) -gt 0.1) {
        Write-Host "Erreur: 5 jours devrait etre egal a 1 semaine, mais a donne $weeksValue" -ForegroundColor Red
        $success = $false
    }
}

if ($success) {
    Write-Host "`nTous les tests d'equivalences temporelles ont reussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests d'equivalences temporelles ont echoue." -ForegroundColor Red
    exit 1
}
