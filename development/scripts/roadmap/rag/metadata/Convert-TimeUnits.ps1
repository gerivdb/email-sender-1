# Convert-TimeUnits.ps1
# Script pour convertir entre differentes unites de temps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [double]$Value,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Minutes", "Hours", "Days", "Weeks", "Months", "Years")]
    [string]$FromUnit,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Minutes", "Hours", "Days", "Weeks", "Months", "Years")]
    [string]$ToUnit,

    [Parameter(Mandatory = $false)]
    [hashtable]$ConversionRates = @{
        "MinutesToHours" = 60
        "HoursToDay"     = 8
        "DaysToWeek"     = 5
        "WeeksToMonth"   = 4
        "MonthsToYear"   = 12
    }
)

# Fonction pour normaliser les noms d'unites
function Get-NormalizedUnitName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Unit
    )

    switch -Regex ($Unit) {
        '^minute|min$' { return "Minutes" }
        '^heure|hour|hr|h$' { return "Hours" }
        '^jour|day|j|d$' { return "Days" }
        '^semaine|week|sem|w$' { return "Weeks" }
        '^mois|month|m$' { return "Months" }
        '^an|annee|year|y$' { return "Years" }
        default { return $Unit }
    }
}

# Fonction pour convertir en minutes (unite de base)
function Convert-ToMinutes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$FromUnit,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionRates
    )

    $normalizedUnit = Get-NormalizedUnitName -Unit $FromUnit

    switch ($normalizedUnit) {
        "Minutes" { return $Value }
        "Hours" { return $Value * $ConversionRates.MinutesToHours }
        "Days" { return $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay }
        "Weeks" { return $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay * $ConversionRates.DaysToWeek }
        "Months" { return $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay * $ConversionRates.DaysToWeek * $ConversionRates.WeeksToMonth }
        "Years" { return $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay * $ConversionRates.DaysToWeek * $ConversionRates.WeeksToMonth * $ConversionRates.MonthsToYear }
        default { throw "Unite non reconnue: $FromUnit" }
    }
}

# Fonction pour convertir des minutes vers une autre unite
function Convert-FromMinutes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Minutes,

        [Parameter(Mandatory = $true)]
        [string]$ToUnit,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionRates
    )

    $normalizedUnit = Get-NormalizedUnitName -Unit $ToUnit

    switch ($normalizedUnit) {
        "Minutes" { return $Minutes }
        "Hours" { return $Minutes / $ConversionRates.MinutesToHours }
        "Days" { return $Minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay }
        "Weeks" { return $Minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay / $ConversionRates.DaysToWeek }
        "Months" { return $Minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay / $ConversionRates.DaysToWeek / $ConversionRates.WeeksToMonth }
        "Years" { return $Minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay / $ConversionRates.DaysToWeek / $ConversionRates.WeeksToMonth / $ConversionRates.MonthsToYear }
        default { throw "Unite non reconnue: $ToUnit" }
    }
}

# Fonction principale pour convertir entre unites de temps
function Convert-TimeUnits {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$FromUnit,

        [Parameter(Mandatory = $true)]
        [string]$ToUnit,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionRates = @{
            "MinutesToHours" = 60
            "HoursToDay"     = 8
            "DaysToWeek"     = 5
            "WeeksToMonth"   = 4
            "MonthsToYear"   = 12
        }
    )

    # Normaliser les noms d'unites
    $normalizedFromUnit = Get-NormalizedUnitName -Unit $FromUnit
    $normalizedToUnit = Get-NormalizedUnitName -Unit $ToUnit

    # Si les unites sont identiques, retourner la valeur telle quelle
    if ($normalizedFromUnit -eq $normalizedToUnit) {
        return $Value
    }

    # Convertir en minutes (unite de base)
    $minutes = Convert-ToMinutes -Value $Value -FromUnit $normalizedFromUnit -ConversionRates $ConversionRates

    # Convertir des minutes vers l'unite cible
    $result = Convert-FromMinutes -Minutes $minutes -ToUnit $normalizedToUnit -ConversionRates $ConversionRates

    return $result
}

# Fonction pour obtenir les facteurs de conversion entre unites
function Get-ConversionFactors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionRates = @{
            "MinutesToHours" = 60
            "HoursToDay"     = 8
            "DaysToWeek"     = 5
            "WeeksToMonth"   = 4
            "MonthsToYear"   = 12
        }
    )

    $factors = @{}

    # Calculer les facteurs de conversion directs
    $factors["MinutesToHours"] = 1 / $ConversionRates.MinutesToHours
    $factors["HoursToMinutes"] = $ConversionRates.MinutesToHours

    $factors["HoursToDays"] = 1 / $ConversionRates.HoursToDay
    $factors["DaysToHours"] = $ConversionRates.HoursToDay

    $factors["DaysToWeeks"] = 1 / $ConversionRates.DaysToWeek
    $factors["WeeksToDays"] = $ConversionRates.DaysToWeek

    $factors["WeeksToMonths"] = 1 / $ConversionRates.WeeksToMonth
    $factors["MonthsToWeeks"] = $ConversionRates.WeeksToMonth

    $factors["MonthsToYears"] = 1 / $ConversionRates.MonthsToYear
    $factors["YearsToMonths"] = $ConversionRates.MonthsToYear

    # Calculer les facteurs de conversion composes
    $factors["MinutesToDays"] = $factors.MinutesToHours * $factors.HoursToDays
    $factors["DaysToMinutes"] = $factors.DaysToHours * $factors.HoursToMinutes

    $factors["MinutesToWeeks"] = $factors.MinutesToDays * $factors.DaysToWeeks
    $factors["WeeksToMinutes"] = $factors.WeeksToDays * $factors.DaysToMinutes

    $factors["MinutesToMonths"] = $factors.MinutesToWeeks * $factors.WeeksToMonths
    $factors["MonthsToMinutes"] = $factors.MonthsToWeeks * $factors.WeeksToMinutes

    $factors["MinutesToYears"] = $factors.MinutesToMonths * $factors.MonthsToYears
    $factors["YearsToMinutes"] = $factors.YearsToMonths * $factors.MonthsToMinutes

    $factors["HoursToWeeks"] = $factors.HoursToDays * $factors.DaysToWeeks
    $factors["WeeksToHours"] = $factors.WeeksToDays * $factors.DaysToHours

    $factors["HoursToMonths"] = $factors.HoursToWeeks * $factors.WeeksToMonths
    $factors["MonthsToHours"] = $factors.MonthsToWeeks * $factors.WeeksToHours

    $factors["HoursToYears"] = $factors.HoursToMonths * $factors.MonthsToYears
    $factors["YearsToHours"] = $factors.YearsToMonths * $factors.MonthsToHours

    $factors["DaysToMonths"] = $factors.DaysToWeeks * $factors.WeeksToMonths
    $factors["MonthsToDays"] = $factors.MonthsToWeeks * $factors.WeeksToDays

    $factors["DaysToYears"] = $factors.DaysToMonths * $factors.MonthsToYears
    $factors["YearsToDays"] = $factors.YearsToMonths * $factors.MonthsToDays

    $factors["WeeksToYears"] = $factors.WeeksToMonths * $factors.MonthsToYears
    $factors["YearsToWeeks"] = $factors.YearsToMonths * $factors.MonthsToWeeks

    return $factors
}

# Fonction pour afficher une table de conversion entre unites
function Show-ConversionTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$ConversionRates = @{
            "MinutesToHours" = 60
            "HoursToDay"     = 8
            "DaysToWeek"     = 5
            "WeeksToMonth"   = 4
            "MonthsToYear"   = 12
        },

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "JSON", "Markdown")]
        [string]$OutputFormat = "Text"
    )

    $units = @("Minutes", "Hours", "Days", "Weeks", "Months", "Years")
    $table = @{}

    foreach ($fromUnit in $units) {
        $table[$fromUnit] = @{}

        foreach ($toUnit in $units) {
            if ($fromUnit -eq $toUnit) {
                $table[$fromUnit][$toUnit] = 1
            } else {
                $table[$fromUnit][$toUnit] = Convert-TimeUnits -Value 1 -FromUnit $fromUnit -ToUnit $toUnit -ConversionRates $ConversionRates
            }
        }
    }

    # Formater la sortie selon le format demande
    switch ($OutputFormat) {
        "Text" {
            $output = "Table de conversion des unites de temps:`n`n"
            $output += "De \ Vers".PadRight(12)

            foreach ($toUnit in $units) {
                $output += $toUnit.PadRight(12)
            }

            $output += "`n" + "-" * (12 * ($units.Count + 1)) + "`n"

            foreach ($fromUnit in $units) {
                $output += $fromUnit.PadRight(12)

                foreach ($toUnit in $units) {
                    $value = $table[$fromUnit][$toUnit]
                    $output += $value.ToString("F4").PadRight(12)
                }

                $output += "`n"
            }

            return $output
        }
        "CSV" {
            $output = "FromUnit,ToUnit,ConversionFactor`n"

            foreach ($fromUnit in $units) {
                foreach ($toUnit in $units) {
                    $value = $table[$fromUnit][$toUnit]
                    $output += "$fromUnit,$toUnit,$value`n"
                }
            }

            return $output
        }
        "JSON" {
            return $table | ConvertTo-Json -Depth 3
        }
        "Markdown" {
            $output = "# Table de conversion des unites de temps`n`n"
            $output += "| De \ Vers |"

            foreach ($toUnit in $units) {
                $output += " $toUnit |"
            }

            $output += "`n|" + "-" * 11 + "|"

            foreach ($toUnit in $units) {
                $output += "-" * 11 + "|"
            }

            $output += "`n"

            foreach ($fromUnit in $units) {
                $output += "| $fromUnit |"

                foreach ($toUnit in $units) {
                    $value = $table[$fromUnit][$toUnit]
                    $output += " " + $value.ToString("F4") + " |"
                }

                $output += "`n"
            }

            return $output
        }
    }
}

# Si le script est execute directement, effectuer la conversion
if ($MyInvocation.InvocationName -ne ".") {
    # Seulement si tous les paramètres sont fournis
    if ($PSBoundParameters.ContainsKey('Value') -and $PSBoundParameters.ContainsKey('FromUnit') -and $PSBoundParameters.ContainsKey('ToUnit')) {
        $result = Convert-TimeUnits -Value $Value -FromUnit $FromUnit -ToUnit $ToUnit -ConversionRates $ConversionRates
        return $result
    }
}
