# Test-SimpleTimeConversion.ps1
# Script pour tester la conversion entre unites de temps (version simplifiee)
# Version: 1.0
# Date: 2025-05-15

# Fonction pour convertir une duree vers une unite standard
function Convert-ToStandardUnit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceUnit,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours", "Days", "Weeks", "Months")]
        [string]$TargetUnit = "Hours"
    )
    
    # Convertir d'abord en heures (unite de base)
    $hoursValue = switch -Regex ($SourceUnit) {
        '^minutes?$' { $Value / 60 }
        '^heures?$' { $Value }
        '^jours?$' { $Value * 8 }  # 8 heures par jour
        '^semaines?$' { $Value * 40 }  # 40 heures par semaine (5 jours * 8 heures)
        '^mois$' { $Value * 160 }  # 160 heures par mois (4 semaines * 40 heures)
        '^années?$' { $Value * 1920 }  # 1920 heures par annee (12 mois * 160 heures)
        default { $Value }  # Par defaut, on suppose que c'est deja en heures
    }
    
    # Convertir des heures vers l'unite cible
    $result = switch ($TargetUnit) {
        'Minutes' { $hoursValue * 60 }
        'Hours' { $hoursValue }
        'Days' { $hoursValue / 8 }
        'Weeks' { $hoursValue / 40 }
        'Months' { $hoursValue / 160 }
        default { $hoursValue }  # Par defaut, on retourne en heures
    }
    
    return $result
}

# Tester les conversions de base
Write-Host "Test des conversions de base..."

# Minutes vers heures
$minutesToHours = Convert-ToStandardUnit -Value 60 -SourceUnit "minutes" -TargetUnit "Hours"
Write-Host "60 minutes = $minutesToHours heures"

# Heures vers jours
$hoursToDays = Convert-ToStandardUnit -Value 8 -SourceUnit "heures" -TargetUnit "Days"
Write-Host "8 heures = $hoursToDays jours"

# Jours vers semaines
$daysToWeeks = Convert-ToStandardUnit -Value 5 -SourceUnit "jours" -TargetUnit "Weeks"
Write-Host "5 jours = $daysToWeeks semaines"

# Semaines vers mois
$weeksToMonths = Convert-ToStandardUnit -Value 4 -SourceUnit "semaines" -TargetUnit "Months"
Write-Host "4 semaines = $weeksToMonths mois"

# Tester les conversions composees
Write-Host "`nTest des conversions composees..."

# Minutes vers jours
$minutesToDays = Convert-ToStandardUnit -Value 480 -SourceUnit "minutes" -TargetUnit "Days"
Write-Host "480 minutes = $minutesToDays jours"

# Heures vers semaines
$hoursToWeeks = Convert-ToStandardUnit -Value 40 -SourceUnit "heures" -TargetUnit "Weeks"
Write-Host "40 heures = $hoursToWeeks semaines"

# Jours vers mois
$daysToMonths = Convert-ToStandardUnit -Value 20 -SourceUnit "jours" -TargetUnit "Months"
Write-Host "20 jours = $daysToMonths mois"

# Tester les conversions avec des valeurs decimales
Write-Host "`nTest des conversions avec des valeurs decimales..."

# 1.5 jours en heures
$decimalDaysToHours = Convert-ToStandardUnit -Value 1.5 -SourceUnit "jours" -TargetUnit "Hours"
Write-Host "1.5 jours = $decimalDaysToHours heures"

# 2.5 semaines en jours
$decimalWeeksToDays = Convert-ToStandardUnit -Value 2.5 -SourceUnit "semaines" -TargetUnit "Days"
Write-Host "2.5 semaines = $decimalWeeksToDays jours"

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

# Verifier les conversions avec des valeurs decimales
if ([Math]::Abs($decimalDaysToHours - 12) -gt 0.001) {
    Write-Host "Erreur: 1.5 jours devrait etre egal a 12 heures, mais a donne $decimalDaysToHours" -ForegroundColor Red
    $success = $false
}

if ([Math]::Abs($decimalWeeksToDays - 12.5) -gt 0.001) {
    Write-Host "Erreur: 2.5 semaines devrait etre egal a 12.5 jours, mais a donne $decimalWeeksToDays" -ForegroundColor Red
    $success = $false
}

if ($success) {
    Write-Host "`nTous les tests de conversion ont reussi!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nCertains tests de conversion ont echoue." -ForegroundColor Red
    exit 1
}
