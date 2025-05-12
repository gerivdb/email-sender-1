<#
.SYNOPSIS
    Analyse les expressions de durée effective dans un texte.

.DESCRIPTION
    Ce script analyse un texte pour détecter les expressions qui indiquent une durée réelle
    (par opposition à une estimation). Il utilise un script Python pour l'analyse et retourne
    les résultats sous forme d'objets PowerShell.

.PARAMETER InputText
    Le texte à analyser.

.PARAMETER FilePath
    Le chemin vers un fichier à analyser.

.PARAMETER OutputFormat
    Le format de sortie des résultats (Text, JSON, CSV, Object). Par défaut: Object.

.PARAMETER IncludeContext
    Indique si le contexte des expressions doit être inclus dans les résultats.

.PARAMETER ConfidenceThreshold
    Seuil de confiance minimal pour les expressions détectées (entre 0 et 1). Par défaut: 0.5.

.EXAMPLE
    Analyze-ActualDurationExpressions -InputText "Tâche: Développer la fonctionnalité X (a pris 4 heures)"

.EXAMPLE
    Analyze-ActualDurationExpressions -FilePath "chemin/vers/fichier.txt" -OutputFormat "JSON"

.EXAMPLE
    Analyze-ActualDurationExpressions -InputText "Tâche: 2.5 jours réels" -ConfidenceThreshold 0.7
#>

[CmdletBinding(DefaultParameterSetName = "Text")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Text", Position = 0)]
    [string]$InputText,

    [Parameter(Mandatory = $true, ParameterSetName = "File")]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "CSV", "Object")]
    [string]$OutputFormat = "Object",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeContext,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [double]$ConfidenceThreshold = 0.5
)

# Obtenir le répertoire du script
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
}
if (-not $scriptDir) {
    $scriptDir = Get-Location
}

# Vérifier si le script Python existe
$pythonScript = Join-Path -Path $scriptDir -ChildPath "analyze_actual_duration_expressions.py"

if (-not (Test-Path -Path $pythonScript)) {
    Write-Error "Le script Python n'existe pas: $pythonScript"
    return
}

# Exécuter le script Python
try {
    # Déterminer le format de sortie Python en fonction du format demandé
    $pythonFormat = if ($OutputFormat -eq "Object" -or $OutputFormat -eq "JSON") { "json" } else { "text" }

    # Exécuter le script Python avec le format approprié
    if ($PSCmdlet.ParameterSetName -eq "Text") {
        if ($OutputFormat -eq "Object" -or $OutputFormat -eq "JSON") {
            $output = & python $pythonScript -t "$InputText" --format $pythonFormat
            $result = $output | ConvertFrom-Json
        } else {
            $output = & python $pythonScript -t "$InputText" --format $pythonFormat
            return $output
        }
    } else {
        if ($OutputFormat -eq "Object" -or $OutputFormat -eq "JSON") {
            $output = & python $pythonScript -i "$FilePath" --format $pythonFormat
            $result = $output | ConvertFrom-Json
        } else {
            $output = & python $pythonScript -i "$FilePath" --format $pythonFormat
            return $output
        }
    }

    if (-not $result) {
        Write-Verbose "Aucune expression de durée effective trouvée."
        return @()
    }

    # Filtrer les résultats selon le seuil de confiance
    $filteredDurations = $result.actual_durations | Where-Object { $_.confidence -ge $ConfidenceThreshold }

    # Supprimer le contexte si non demandé
    if (-not $IncludeContext) {
        $filteredDurations = $filteredDurations | ForEach-Object {
            $_ | Select-Object -Property * -ExcludeProperty context
        }
    }

    # Formater la sortie selon le format demandé
    switch ($OutputFormat) {
        "Text" {
            $output = "Expressions de durée effective trouvées: $($filteredDurations.Count)`n"

            foreach ($duration in $filteredDurations) {
                $output += "Type: $($duration.type)`n"

                if ($duration.type -eq "duration") {
                    $output += "Valeur: $($duration.value) $($duration.unit)`n"
                } elseif ($duration.type -eq "completion_date") {
                    $output += "Date de réalisation: $($duration.date)`n"
                } elseif ($duration.type -eq "date_range") {
                    $output += "Période: du $($duration.start_date) au $($duration.end_date)`n"
                }

                $output += "Texte original: $($duration.original_text)`n"

                if ($IncludeContext) {
                    $output += "Contexte: $($duration.context)`n"
                }

                $output += "Confiance: $($duration.confidence)`n`n"
            }

            return $output
        }
        "JSON" {
            return $filteredDurations | ConvertTo-Json -Depth 5
        }
        "CSV" {
            $csvData = $filteredDurations | ForEach-Object {
                $props = @{
                    Type           = $_.type
                    Value          = if ($_.type -eq "duration") { $_.value } else { "" }
                    Unit           = if ($_.type -eq "duration") { $_.unit } else { "" }
                    StartDate      = if ($_.type -eq "date_range") { $_.start_date } else { "" }
                    EndDate        = if ($_.type -eq "date_range") { $_.end_date } else { "" }
                    CompletionDate = if ($_.type -eq "completion_date") { $_.date } else { "" }
                    OriginalText   = $_.original_text
                    Confidence     = $_.confidence
                }

                if ($IncludeContext) {
                    $props.Context = $_.context
                }

                New-Object -TypeName PSObject -Property $props
            }

            return $csvData | ConvertTo-Csv -NoTypeInformation
        }
        "Object" {
            return $filteredDurations
        }
    }
} catch {
    Write-Error "Erreur lors de l'exécution du script Python: $_"
    return
}
