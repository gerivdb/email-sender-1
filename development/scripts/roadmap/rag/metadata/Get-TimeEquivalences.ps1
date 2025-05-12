# Calculate-TimeEquivalences.ps1
# Script pour calculer les equivalences temporelles
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [double]$Value,

    [Parameter(Mandatory = $true)]
    [string]$Unit,

    [Parameter(Mandatory = $false)]
    [switch]$AllEquivalences,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "Markdown", "CSV")]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
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

# Fonction pour convertir entre unites de temps
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

    # Convertir d'abord en minutes (unite de base)
    $minutes = switch ($normalizedFromUnit) {
        "Minutes" { $Value }
        "Hours" { $Value * $ConversionRates.MinutesToHours }
        "Days" { $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay }
        "Weeks" { $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay * $ConversionRates.DaysToWeek }
        "Months" { $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay * $ConversionRates.DaysToWeek * $ConversionRates.WeeksToMonth }
        "Years" { $Value * $ConversionRates.MinutesToHours * $ConversionRates.HoursToDay * $ConversionRates.DaysToWeek * $ConversionRates.WeeksToMonth * $ConversionRates.MonthsToYear }
        default { throw "Unite non reconnue: $normalizedFromUnit" }
    }

    # Convertir des minutes vers l'unite cible
    $result = switch ($normalizedToUnit) {
        "Minutes" { $minutes }
        "Hours" { $minutes / $ConversionRates.MinutesToHours }
        "Days" { $minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay }
        "Weeks" { $minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay / $ConversionRates.DaysToWeek }
        "Months" { $minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay / $ConversionRates.DaysToWeek / $ConversionRates.WeeksToMonth }
        "Years" { $minutes / $ConversionRates.MinutesToHours / $ConversionRates.HoursToDay / $ConversionRates.DaysToWeek / $ConversionRates.WeeksToMonth / $ConversionRates.MonthsToYear }
        default { throw "Unite non reconnue: $normalizedToUnit" }
    }

    return $result
}

# Fonction pour calculer toutes les equivalences temporelles
function Get-AllTimeEquivalences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Unit
    )

    $units = @("Minutes", "Hours", "Days", "Weeks", "Months", "Years")
    $equivalences = @{}

    foreach ($targetUnit in $units) {
        try {
            $equivalences[$targetUnit] = Convert-TimeUnits -Value $Value -FromUnit $Unit -ToUnit $targetUnit
        } catch {
            Write-Warning "Erreur lors de la conversion de $Value $Unit vers $targetUnit : $_"
            $equivalences[$targetUnit] = $null
        }
    }

    return $equivalences
}

# Fonction pour calculer les equivalences temporelles les plus pertinentes
function Get-RelevantTimeEquivalences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Unit
    )

    $normalizedUnit = Get-NormalizedUnitName -Unit $Unit
    $equivalences = @{}

    # Determiner les unites pertinentes en fonction de l'unite source
    $relevantUnits = switch ($normalizedUnit) {
        "Minutes" { @("Hours", "Days") }
        "Hours" { @("Minutes", "Days", "Weeks") }
        "Days" { @("Hours", "Weeks", "Months") }
        "Weeks" { @("Days", "Months") }
        "Months" { @("Weeks", "Days", "Years") }
        "Years" { @("Months", "Weeks", "Days") }
        default { @("Minutes", "Hours", "Days", "Weeks", "Months", "Years") }
    }

    # Calculer les equivalences pour les unites pertinentes
    foreach ($targetUnit in $relevantUnits) {
        if ($targetUnit -ne $normalizedUnit) {
            try {
                $equivalences[$targetUnit] = Convert-TimeUnits -Value $Value -FromUnit $normalizedUnit -ToUnit $targetUnit
            } catch {
                Write-Warning "Erreur lors de la conversion de $Value $normalizedUnit vers $targetUnit : $_"
                $equivalences[$targetUnit] = $null
            }
        }
    }

    return $equivalences
}

# Fonction pour formater les equivalences temporelles
function Format-TimeEquivalences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Equivalences,

        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Unit,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "Markdown", "CSV")]
        [string]$OutputFormat = "Text"
    )

    $normalizedUnit = Get-NormalizedUnitName -Unit $Unit

    switch ($OutputFormat) {
        "Text" {
            $output = "Equivalences temporelles pour $Value $normalizedUnit :`n`n"

            foreach ($targetUnit in $Equivalences.Keys | Sort-Object) {
                $equivalentValue = $Equivalences[$targetUnit]

                if ($null -ne $equivalentValue) {
                    $output += "- $Value $normalizedUnit = $($equivalentValue.ToString('F2')) $targetUnit`n"
                }
            }

            return $output
        }
        "JSON" {
            $result = [PSCustomObject]@{
                SourceValue  = $Value
                SourceUnit   = $normalizedUnit
                Equivalences = $Equivalences
            }

            return $result | ConvertTo-Json -Depth 3
        }
        "Markdown" {
            $output = "# Equivalences temporelles pour $Value $normalizedUnit`n`n"
            $output += "| Unite | Valeur equivalente |`n"
            $output += "|-------|-------------------:|`n"

            foreach ($targetUnit in $Equivalences.Keys | Sort-Object) {
                $equivalentValue = $Equivalences[$targetUnit]

                if ($null -ne $equivalentValue) {
                    $output += "| $targetUnit | $($equivalentValue.ToString('F2')) |`n"
                }
            }

            return $output
        }
        "CSV" {
            $output = "SourceValue,SourceUnit,TargetUnit,EquivalentValue`n"

            foreach ($targetUnit in $Equivalences.Keys | Sort-Object) {
                $equivalentValue = $Equivalences[$targetUnit]

                if ($null -ne $equivalentValue) {
                    $output += "$Value,$normalizedUnit,$targetUnit,$equivalentValue`n"
                }
            }

            return $output
        }
    }
}

# Fonction principale pour calculer les equivalences temporelles
function Get-TimeEquivalences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Unit,

        [Parameter(Mandatory = $false)]
        [switch]$AllEquivalences,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "Markdown", "CSV")]
        [string]$OutputFormat = "Text",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Calculer les equivalences temporelles
    if ($AllEquivalences) {
        $equivalences = Get-AllTimeEquivalences -Value $Value -Unit $Unit
    } else {
        $equivalences = Get-RelevantTimeEquivalences -Value $Value -Unit $Unit
    }

    # Formater les equivalences temporelles
    $output = Format-TimeEquivalences -Equivalences $equivalences -Value $Value -Unit $Unit -OutputFormat $OutputFormat

    # Sauvegarder la sortie si un chemin est specifie
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $output | Out-File -FilePath $OutputPath -Encoding utf8
    }

    return $output
}

# Executer la fonction principale avec les parametres fournis
Get-TimeEquivalences -Value $Value -Unit $Unit -AllEquivalences:$AllEquivalences -OutputFormat $OutputFormat -OutputPath $OutputPath
