# Get-EstimationValues.ps1
# Script pour extraire les valeurs d'estimation de durée dans un texte
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InputText,

    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "Text"
)

# Fonction pour extraire les valeurs d'estimation
function Get-EstimationValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $results = @()

    # Définir les patterns pour trouver les valeurs numériques suivies d'unités de temps
    $patterns = @(
        # Nombre + unité (ex: 3 jours, 2 semaines)
        '(\d+(?:[.,]\d+)?)\s+(jours?|semaines?|mois|heures?|ans?|années?|jour-homme|jours-homme|homme-jour|hommes-jour)'
        # Nombre + unité en anglais (ex: 3 days, 2 weeks)
        '(\d+(?:[.,]\d+)?)\s+(days?|weeks?|months?|hours?|years?|man-days?|person-days?)'
        # Nombre + abréviation (ex: 3j, 2s, 4h)
        '(\d+(?:[.,]\d+)?)\s*(j|s|m|h|a|jh|hj)'
        # Nombre + abréviation en anglais (ex: 3d, 2w, 4h)
        '(\d+(?:[.,]\d+)?)\s*(d|w|m|h|y|md|pd)'
        # Nombre avec virgule + unité (ex: 3,5 jours, 2,5 semaines)
        '(\d+[,]\d+)\s+(jours?|semaines?|mois|heures?|ans?|années?|jour-homme|jours-homme|homme-jour|hommes-jour)'
        # Nombre avec point + unité (ex: 3.5 jours, 2.5 semaines)
        '(\d+[.]\d+)\s+(jours?|semaines?|mois|heures?|ans?|années?|jour-homme|jours-homme|homme-jour|hommes-jour)'
        # Nombre avec virgule + unité en anglais (ex: 3,5 days, 2,5 weeks)
        '(\d+[,]\d+)\s+(days?|weeks?|months?|hours?|years?|man-days?|person-days?)'
        # Nombre avec point + unité en anglais (ex: 3.5 days, 2.5 weeks)
        '(\d+[.]\d+)\s+(days?|weeks?|months?|hours?|years?|man-days?|person-days?)'
    )

    # Parcourir chaque pattern
    foreach ($pattern in $patterns) {
        $matchResults = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

        foreach ($match in $matchResults) {
            $value = $match.Groups[1].Value
            $unit = $match.Groups[2].Value.ToLower().Trim()

            # Convertir la valeur en nombre
            $numericValue = 0
            if ($value -match ",") {
                $value = $value -replace ",", "."
            }

            if ([double]::TryParse($value, [ref]$numericValue)) {
                # Déterminer l'unité de temps et le multiplicateur
                $normalizedUnit = $unit
                $multiplier = 1

                # Unités en français
                switch -Regex ($unit) {
                    '^h(eure)?s?$' { $normalizedUnit = "heure"; $multiplier = 1 }
                    '^j(our)?s?$' { $normalizedUnit = "jour"; $multiplier = 8 }
                    '^s(emaine)?s?$' { $normalizedUnit = "semaine"; $multiplier = 40 }
                    '^m(ois)?$' { $normalizedUnit = "mois"; $multiplier = 160 }
                    '^a(n|ns|nnée|nnées)$' { $normalizedUnit = "année"; $multiplier = 1920 }
                    '^(jour-homme|jours-homme|homme-jour|hommes-jour|jh|hj)$' { $normalizedUnit = "jour-homme"; $multiplier = 8 }

                    # Unités en anglais
                    '^(h(our|r)?s?)$' { $normalizedUnit = "hour"; $multiplier = 1 }
                    '^(d(ay)?s?)$' { $normalizedUnit = "day"; $multiplier = 8 }
                    '^(w(eek|k)?s?)$' { $normalizedUnit = "week"; $multiplier = 40 }
                    '^(m(onth|o)?s?)$' { $normalizedUnit = "month"; $multiplier = 160 }
                    '^(y(ear|r)?s?)$' { $normalizedUnit = "year"; $multiplier = 1920 }
                    '^(man-day|man-days|person-day|person-days|md|pd)$' { $normalizedUnit = "man-day"; $multiplier = 8 }
                }

                # Calculer la valeur en heures
                $hoursValue = $numericValue * $multiplier

                # Déterminer la catégorie d'estimation
                $category = "precise"

                # Vérifier si l'expression est dans un contexte approximatif
                $contextStart = [Math]::Max(0, $match.Index - 20)
                $contextLength = [Math]::Min($Text.Length - $contextStart, $match.Index - $contextStart + $match.Length + 20)
                $context = $Text.Substring($contextStart, $contextLength)

                if ($context -match "(environ|approximativement|à peu près|autour de|aux alentours de|plus ou moins|±|~)") {
                    $category = "approximate"
                } elseif ($context -match "(entre|de|à|-).*\d+.*\d+") {
                    $category = "range"
                } elseif ($context -match "(au moins|minimum|min|au minimum)") {
                    $category = "minimum"
                } elseif ($context -match "(au plus|maximum|max|au maximum)") {
                    $category = "maximum"
                }

                $result = [PSCustomObject]@{
                    Category   = $category
                    Value      = $numericValue
                    Unit       = $normalizedUnit
                    HoursValue = $hoursValue
                    Context    = $context
                }

                $results += $result
            }
        }
    }

    return $results
}

# Fonction pour formater les résultats
function Format-EstimationResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Results,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "CSV", "Markdown", "HTML")]
        [string]$Format = "Text"
    )

    # Si aucun résultat n'est fourni, retourner un message d'erreur
    if ($null -eq $Results -or $Results.Count -eq 0) {
        return "Aucune valeur d'estimation trouvée."
    }

    # Formater les résultats selon le format demandé
    switch ($Format) {
        "Text" {
            $output = "Résultats de l'analyse des valeurs d'estimation:`n"
            $output += "=============================================`n"
            $output += "Nombre total de valeurs trouvées: $($Results.Count)`n`n"

            # Regrouper les résultats par catégorie
            $groupedResults = $Results | Group-Object -Property Category

            foreach ($group in $groupedResults) {
                $output += "Catégorie: $($group.Name) ($($group.Count) valeurs)`n"
                $output += "-" * 50 + "`n"

                foreach ($result in $group.Group) {
                    $output += "  Valeur: $($result.Value) $($result.Unit) (= $($result.HoursValue) heures)`n"
                    $output += "  Contexte: $($result.Context)`n"
                    $output += "`n"
                }
            }

            return $output
        }

        "JSON" {
            return $Results | ConvertTo-Json -Depth 3
        }

        "CSV" {
            return $Results | ConvertTo-Csv -NoTypeInformation
        }

        "Markdown" {
            $output = "# Résultats de l'analyse des valeurs d'estimation`n`n"
            $output += "Nombre total de valeurs trouvées: **$($Results.Count)**`n`n"

            # Regrouper les résultats par catégorie
            $groupedResults = $Results | Group-Object -Property Category

            foreach ($group in $groupedResults) {
                $output += "## Catégorie: $($group.Name) ($($group.Count) valeurs)`n`n"

                $output += "| Valeur | Unité | Heures | Contexte |`n"
                $output += "| --- | --- | --- | --- |`n"

                foreach ($result in $group.Group) {
                    $output += "| $($result.Value) | $($result.Unit) | $($result.HoursValue) | $($result.Context) |`n"
                }

                $output += "`n"
            }

            return $output
        }

        "HTML" {
            $output = "<html>`n<head>`n<title>Résultats de l'analyse des valeurs d'estimation</title>`n"
            $output += "<style>`n"
            $output += "body { font-family: Arial, sans-serif; margin: 20px; }`n"
            $output += "h1 { color: #333; }`n"
            $output += "h2 { color: #666; margin-top: 20px; }`n"
            $output += "table { border-collapse: collapse; width: 100%; }`n"
            $output += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $output += "th { background-color: #f2f2f2; }`n"
            $output += "tr:nth-child(even) { background-color: #f9f9f9; }`n"
            $output += "</style>`n</head>`n<body>`n"

            $output += "<h1>Résultats de l'analyse des valeurs d'estimation</h1>`n"
            $output += "<p>Nombre total de valeurs trouvées: <strong>$($Results.Count)</strong></p>`n"

            # Regrouper les résultats par catégorie
            $groupedResults = $Results | Group-Object -Property Category

            foreach ($group in $groupedResults) {
                $output += "<h2>Catégorie: $($group.Name) ($($group.Count) valeurs)</h2>`n"

                $output += "<table>`n<tr>`n"
                $output += "<th>Valeur</th>`n<th>Unité</th>`n<th>Heures</th>`n<th>Contexte</th>`n"
                $output += "</tr>`n"

                foreach ($result in $group.Group) {
                    $output += "<tr>`n"
                    $output += "<td>$($result.Value)</td>`n<td>$($result.Unit)</td>`n<td>$($result.HoursValue)</td>`n<td>$($result.Context)</td>`n"
                    $output += "</tr>`n"
                }

                $output += "</table>`n"
            }

            $output += "</body>`n</html>"

            return $output
        }

        default {
            return "Format de sortie non pris en charge: $Format"
        }
    }
}

# Fonction principale
function Main {
    # Vérifier si un texte d'entrée ou un chemin de fichier a été fourni
    if (-not $InputText -and -not $FilePath) {
        Write-Error "Vous devez fournir soit un texte d'entrée, soit un chemin de fichier."
        return
    }

    # Lire le texte d'entrée
    $text = $InputText

    if ($FilePath) {
        if (Test-Path -Path $FilePath) {
            $text = Get-Content -Path $FilePath -Raw
        } else {
            Write-Error "Le fichier spécifié n'existe pas: $FilePath"
            return
        }
    }

    # Vérifier si le texte est vide
    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Error "Le texte d'entrée est vide."
        return "Aucune valeur d'estimation trouvée."
    }

    # Extraire les valeurs d'estimation
    try {
        $results = Get-EstimationValues -Text $text

        # Vérifier si des résultats ont été trouvés
        if ($null -eq $results -or $results.Count -eq 0) {
            return "Aucune valeur d'estimation trouvée."
        }
    } catch {
        Write-Error "Une erreur s'est produite lors de l'extraction des valeurs d'estimation: $_"
        return "Aucune valeur d'estimation trouvée."
    }

    # Formater les résultats
    $formattedResults = Format-EstimationResults -Results $results -Format $OutputFormat

    # Afficher les résultats
    return $formattedResults
}

# Exécuter la fonction principale
Main
