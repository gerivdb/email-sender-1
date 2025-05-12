# Format-EstimationOutput.ps1
# Script utilitaire pour formater les résultats d'analyse des expressions d'estimation
# Version: 1.0
# Date: 2025-05-15

function Format-Output {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "CSV", "Markdown", "HTML")]
        [string]$Format = "Text",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext = $false
    )

    # Si aucune donnée n'est fournie, retourner un message d'erreur
    if ($null -eq $Data -or $Data.Count -eq 0) {
        return "Aucune donnée à formater."
    }

    # Formater les données selon le format demandé
    switch ($Format) {
        "Text" {
            $output = "Résultats de l'analyse:`n"
            $output += "=====================`n"
            $output += "Nombre total d'expressions trouvées: $($Data.Count)`n`n"

            # Regrouper les résultats par catégorie
            $groupedData = $Data | Group-Object -Property Category

            foreach ($group in $groupedData) {
                $output += "Catégorie: $($group.Name) ($($group.Count) occurrences)`n"
                $output += "-" * 50 + "`n"

                foreach ($item in $group.Group) {
                    $output += "  Expression: $($item.Expression)`n"
                    $output += "  Correspondance: $($item.Match)`n"
                    $output += "  Position: $($item.Index)`n"

                    if ($IncludeContext) {
                        $output += "  Contexte: $($item.FullContext)`n"
                    }

                    $output += "`n"
                }
            }

            return $output
        }

        "JSON" {
            # Filtrer les propriétés si le contexte n'est pas demandé
            if (-not $IncludeContext) {
                $filteredData = $Data | Select-Object Category, Expression, Match, Index, Length
                return $filteredData | ConvertTo-Json -Depth 3
            } else {
                return $Data | ConvertTo-Json -Depth 3
            }
        }

        "CSV" {
            # Filtrer les propriétés si le contexte n'est pas demandé
            if (-not $IncludeContext) {
                $filteredData = $Data | Select-Object Category, Expression, Match, Index, Length
                return $filteredData | ConvertTo-Csv -NoTypeInformation
            } else {
                return $Data | ConvertTo-Csv -NoTypeInformation
            }
        }

        "Markdown" {
            $output = "# Résultats de l'analyse`n`n"
            $output += "Nombre total d'expressions trouvées: **$($Data.Count)**`n`n"

            # Regrouper les résultats par catégorie
            $groupedData = $Data | Group-Object -Property Category

            foreach ($group in $groupedData) {
                $output += "## Catégorie: $($group.Name) ($($group.Count) occurrences)`n`n"

                $output += "| Expression | Correspondance | Position |"
                if ($IncludeContext) {
                    $output += " Contexte |"
                }
                $output += "`n"

                $output += "| --- | --- | --- |"
                if ($IncludeContext) {
                    $output += " --- |"
                }
                $output += "`n"

                foreach ($item in $group.Group) {
                    $output += "| $($item.Expression) | $($item.Match) | $($item.Index) |"
                    if ($IncludeContext) {
                        $output += " $($item.FullContext) |"
                    }
                    $output += "`n"
                }

                $output += "`n"
            }

            return $output
        }

        "HTML" {
            $output = "<html>`n<head>`n<title>Résultats de l'analyse</title>`n"
            $output += "<style>`n"
            $output += "body { font-family: Arial, sans-serif; margin: 20px; }`n"
            $output += "h1 { color: #333; }`n"
            $output += "h2 { color: #666; margin-top: 20px; }`n"
            $output += "table { border-collapse: collapse; width: 100%; }`n"
            $output += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $output += "th { background-color: #f2f2f2; }`n"
            $output += "tr:nth-child(even) { background-color: #f9f9f9; }`n"
            $output += "</style>`n</head>`n<body>`n"

            $output += "<h1>Résultats de l'analyse</h1>`n"
            $output += "<p>Nombre total d'expressions trouvées: <strong>$($Data.Count)</strong></p>`n"

            # Regrouper les résultats par catégorie
            $groupedData = $Data | Group-Object -Property Category

            foreach ($group in $groupedData) {
                $output += "<h2>Catégorie: $($group.Name) ($($group.Count) occurrences)</h2>`n"

                $output += "<table>`n<tr>`n"
                $output += "<th>Expression</th>`n<th>Correspondance</th>`n<th>Position</th>`n"
                if ($IncludeContext) {
                    $output += "<th>Contexte</th>`n"
                }
                $output += "</tr>`n"

                foreach ($item in $group.Group) {
                    $output += "<tr>`n"
                    $output += "<td>$($item.Expression)</td>`n<td>$($item.Match)</td>`n<td>$($item.Index)</td>`n"
                    if ($IncludeContext) {
                        $output += "<td>$($item.FullContext)</td>`n"
                    }
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

# Pas besoin d'exporter la fonction car ce n'est pas un module
