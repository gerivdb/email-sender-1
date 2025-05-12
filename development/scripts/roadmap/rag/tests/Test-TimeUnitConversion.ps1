# Test-TimeUnitConversion.ps1
# Script pour tester la conversion entre unites de temps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param ()

# Importer le script de conversion
$scriptPath = $PSScriptRoot
$convertTimeUnitsScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Convert-TimeUnits.ps1"

if (-not (Test-Path -Path $convertTimeUnitsScriptPath)) {
    Write-Host "Le script de conversion des unites de temps n'existe pas: $convertTimeUnitsScriptPath"
    exit 1
}

# Importer les fonctions du script
. $convertTimeUnitsScriptPath

# Tester les conversions de base
Write-Host "Test des conversions de base..."

# Minutes vers heures
$minutesToHours = Convert-TimeUnits -Value 60 -FromUnit "Minutes" -ToUnit "Hours"
Write-Host "60 minutes = $minutesToHours heures"

# Heures vers jours
$hoursToDays = Convert-TimeUnits -Value 8 -FromUnit "Hours" -ToUnit "Days"
Write-Host "8 heures = $hoursToDays jours"

# Jours vers semaines
$daysToWeeks = Convert-TimeUnits -Value 5 -FromUnit "Days" -ToUnit "Weeks"
Write-Host "5 jours = $daysToWeeks semaines"

# Semaines vers mois
$weeksToMonths = Convert-TimeUnits -Value 4 -FromUnit "Weeks" -ToUnit "Months"
Write-Host "4 semaines = $weeksToMonths mois"

# Mois vers annees
$monthsToYears = Convert-TimeUnits -Value 12 -FromUnit "Months" -ToUnit "Years"
Write-Host "12 mois = $monthsToYears annees"

# Tester les conversions composees
Write-Host "`nTest des conversions composees..."

# Minutes vers jours
$minutesToDays = Convert-TimeUnits -Value 480 -FromUnit "Minutes" -ToUnit "Days"
Write-Host "480 minutes = $minutesToDays jours"

# Heures vers semaines
$hoursToWeeks = Convert-TimeUnits -Value 40 -FromUnit "Hours" -ToUnit "Weeks"
Write-Host "40 heures = $hoursToWeeks semaines"

# Jours vers mois
$daysToMonths = Convert-TimeUnits -Value 20 -FromUnit "Days" -ToUnit "Months"
Write-Host "20 jours = $daysToMonths mois"

# Semaines vers annees
$weeksToYears = Convert-TimeUnits -Value 52 -FromUnit "Weeks" -ToUnit "Years"
Write-Host "52 semaines = $weeksToYears annees"

# Tester les conversions inverses
Write-Host "`nTest des conversions inverses..."

# Annees vers mois
$yearsToMonths = Convert-TimeUnits -Value 1 -FromUnit "Years" -ToUnit "Months"
Write-Host "1 annee = $yearsToMonths mois"

# Mois vers semaines
$monthsToWeeks = Convert-TimeUnits -Value 1 -FromUnit "Months" -ToUnit "Weeks"
Write-Host "1 mois = $monthsToWeeks semaines"

# Semaines vers jours
$weeksToDays = Convert-TimeUnits -Value 1 -FromUnit "Weeks" -ToUnit "Days"
Write-Host "1 semaine = $weeksToDays jours"

# Jours vers heures
$daysToHours = Convert-TimeUnits -Value 1 -FromUnit "Days" -ToUnit "Hours"
Write-Host "1 jour = $daysToHours heures"

# Heures vers minutes
$hoursToMinutes = Convert-TimeUnits -Value 1 -FromUnit "Hours" -ToUnit "Minutes"
Write-Host "1 heure = $hoursToMinutes minutes"

# Tester les conversions avec des valeurs decimales
Write-Host "`nTest des conversions avec des valeurs decimales..."

# 1.5 jours en heures
$decimalDaysToHours = Convert-TimeUnits -Value 1.5 -FromUnit "Days" -ToUnit "Hours"
Write-Host "1.5 jours = $decimalDaysToHours heures"

# 2.5 semaines en jours
$decimalWeeksToDays = Convert-TimeUnits -Value 2.5 -FromUnit "Weeks" -ToUnit "Days"
Write-Host "2.5 semaines = $decimalWeeksToDays jours"

# Tester les conversions avec des taux personnalises
Write-Host "`nTest des conversions avec des taux personnalises..."

$customRates = @{
    "MinutesToHours" = 60
    "HoursToDay"     = 7.5  # Journee de travail de 7.5 heures
    "DaysToWeek"     = 5    # Semaine de 5 jours
    "WeeksToMonth"   = 4.33  # Environ 4.33 semaines par mois
    "MonthsToYear"   = 12
}

# 1 jour en heures avec taux personnalises
$customDaysToHours = Convert-TimeUnits -Value 1 -FromUnit "Days" -ToUnit "Hours" -ConversionRates $customRates
Write-Host "1 jour = $customDaysToHours heures (avec journee de travail de 7.5 heures)"

# 1 mois en jours avec taux personnalises
$customMonthsToDays = Convert-TimeUnits -Value 1 -FromUnit "Months" -ToUnit "Days" -ConversionRates $customRates
Write-Host "1 mois = $customMonthsToDays jours (avec 4.33 semaines par mois)"

# Afficher la table de conversion
Write-Host "`nTable de conversion des unites de temps:"
$conversionTable = Show-ConversionTable -OutputFormat "Text"
Write-Host $conversionTable

# Verifier les resultats
$success = $true

# Verifier les conversions de base
if ([Math]::Abs($minutesToHours - 1) -gt 0.001) {
    Write-Host "Erreur: 60 minutes devrait etre egal a 1 heure, mais a donne $minutesToHours" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($hoursToDays - 1) -gt 0.001) {
    Write-Host "Erreur: 8 heures devrait etre egal a 1 jour, mais a donne $hoursToDays" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($daysToWeeks - 1) -gt 0.001) {
    Write-Host "Erreur: 5 jours devrait etre egal a 1 semaine, mais a donne $daysToWeeks" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($weeksToMonths - 1) -gt 0.001) {
    Write-Host "Erreur: 4 semaines devrait etre egal a 1 mois, mais a donne $weeksToMonths" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($monthsToYears - 1) -gt 0.001) {
    Write-Host "Erreur: 12 mois devrait etre egal a 1 annee, mais a donne $monthsToYears" -ForegroundColor Red
    $success = $false
}

# Verifier les conversions composees
if ([Math]::Abs($minutesToDays - 1) -gt 0.001) {
    Write-Host "Erreur: 480 minutes devrait etre egal a 1 jour, mais a donne $minutesToDays" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($hoursToWeeks - 1) -gt 0.001) {
    Write-Host "Erreur: 40 heures devrait etre egal a 1 semaine, mais a donne $hoursToWeeks" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($daysToMonths - 1) -gt 0.001) {
    Write-Host "Erreur: 20 jours devrait etre egal a 1 mois, mais a donne $daysToMonths" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($weeksToYears - 1) -gt 0.001) {
    Write-Host "Erreur: 52 semaines devrait etre egal a 1 annee, mais a donne $weeksToYears" -ForegroundColor Red
    $success = $false
}

if ($success) {
    Write-Host "`nTous les tests de conversion ont reussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests de conversion ont echoue." -ForegroundColor Red
    exit 1
}
