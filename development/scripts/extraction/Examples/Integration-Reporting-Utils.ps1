#Requires -Version 5.1
<#
.SYNOPSIS
Utilitaires pour le module d'intégration de reporting.

.DESCRIPTION
Ce module contient des fonctions utilitaires pour le module d'intégration de reporting.

.NOTES
Date de création : 2025-05-15
Auteur : Augment Code
Version : 1.0.0
#>

<#
.SYNOPSIS
Convertit un objet en tableau HTML.

.DESCRIPTION
La fonction ConvertTo-HtmlTable convertit un objet en tableau HTML.

.PARAMETER InputObject
L'objet à convertir en tableau HTML.

.PARAMETER Properties
Les propriétés à inclure dans le tableau. Si non spécifié, toutes les propriétés sont incluses.

.PARAMETER Caption
La légende du tableau.

.PARAMETER CssClass
La classe CSS à appliquer au tableau.

.EXAMPLE
$data = @(
    [PSCustomObject]@{ Name = "John"; Age = 30; City = "New York" },
    [PSCustomObject]@{ Name = "Jane"; Age = 25; City = "Boston" }
)
$htmlTable = ConvertTo-HtmlTable -InputObject $data -Caption "Liste des personnes"

.NOTES
Cette fonction est utilisée en interne par Export-ExtractedInfoReportToHtml.
#>
function ConvertTo-HtmlTable {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [string[]]$Properties,

        [Parameter(Mandatory = $false)]
        [string]$Caption = "",

        [Parameter(Mandatory = $false)]
        [string]$CssClass = "table table-striped table-bordered table-hover"
    )

    begin {
        $items = @()
    }

    process {
        if ($InputObject -is [array]) {
            $items += $InputObject
        }
        else {
            $items += $InputObject
        }
    }

    end {
        # Si aucun élément, retourner un tableau vide
        if ($items.Count -eq 0) {
            return "<table class=`"$CssClass`"><tr><td>Aucune donnée</td></tr></table>"
        }

        # Déterminer les propriétés à inclure
        if (-not $PSBoundParameters.ContainsKey("Properties")) {
            if ($items[0] -is [PSObject]) {
                $Properties = $items[0].PSObject.Properties.Name
            }
            elseif ($items[0] -is [hashtable]) {
                $Properties = $items[0].Keys
            }
            else {
                $Properties = @("Value")
            }
        }

        # Construire le tableau HTML
        $html = "<table class=`"$CssClass`">"

        # Ajouter la légende si spécifiée
        if (-not [string]::IsNullOrWhiteSpace($Caption)) {
            $html += "<caption>$Caption</caption>"
        }

        # Ajouter les en-têtes
        $html += "<thead><tr>"
        foreach ($property in $Properties) {
            $html += "<th>$property</th>"
        }
        $html += "</tr></thead>"

        # Ajouter les lignes
        $html += "<tbody>"
        foreach ($item in $items) {
            $html += "<tr>"
            foreach ($property in $Properties) {
                $value = if ($item -is [PSObject]) {
                    $item.$property
                }
                elseif ($item -is [hashtable] -and $item.ContainsKey($property)) {
                    $item[$property]
                }
                else {
                    $item
                }

                # Formater la valeur
                $formattedValue = if ($null -eq $value) {
                    "&nbsp;"
                }
                elseif ($value -is [DateTime]) {
                    $value.ToString("dd/MM/yyyy HH:mm:ss")
                }
                elseif ($value -is [bool]) {
                    if ($value) { "Oui" } else { "Non" }
                }
                elseif ($value -is [array]) {
                    $value -join ", "
                }
                else {
                    $value
                }

                $html += "<td>$formattedValue</td>"
            }
            $html += "</tr>"
        }
        $html += "</tbody></table>"

        return $html
    }
}

<#
.SYNOPSIS
Convertit un objet en liste HTML.

.DESCRIPTION
La fonction ConvertTo-HtmlList convertit un objet en liste HTML (ordonnée ou non ordonnée).

.PARAMETER InputObject
L'objet à convertir en liste HTML.

.PARAMETER Property
La propriété à utiliser pour les éléments de la liste. Si non spécifié, l'objet lui-même est utilisé.

.PARAMETER Ordered
Indique si la liste doit être ordonnée (ol) ou non ordonnée (ul).

.PARAMETER CssClass
La classe CSS à appliquer à la liste.

.EXAMPLE
$data = @("Item 1", "Item 2", "Item 3")
$htmlList = ConvertTo-HtmlList -InputObject $data -Ordered $true

.NOTES
Cette fonction est utilisée en interne par Export-ExtractedInfoReportToHtml.
#>
function ConvertTo-HtmlList {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [string]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$Ordered,

        [Parameter(Mandatory = $false)]
        [string]$CssClass = ""
    )

    begin {
        $items = @()
    }

    process {
        if ($InputObject -is [array]) {
            $items += $InputObject
        }
        else {
            $items += $InputObject
        }
    }

    end {
        # Si aucun élément, retourner une liste vide
        if ($items.Count -eq 0) {
            return "<ul><li>Aucun élément</li></ul>"
        }

        # Déterminer le type de liste
        $listTag = if ($Ordered) { "ol" } else { "ul" }

        # Ajouter la classe CSS si spécifiée
        $cssAttribute = if (-not [string]::IsNullOrWhiteSpace($CssClass)) { " class=`"$CssClass`"" } else { "" }

        # Construire la liste HTML
        $html = "<$listTag$cssAttribute>"

        # Ajouter les éléments
        foreach ($item in $items) {
            $value = if ($PSBoundParameters.ContainsKey("Property") -and $item -is [PSObject]) {
                $item.$Property
            }
            elseif ($PSBoundParameters.ContainsKey("Property") -and $item -is [hashtable] -and $item.ContainsKey($Property)) {
                $item[$Property]
            }
            else {
                $item
            }

            # Formater la valeur
            $formattedValue = if ($null -eq $value) {
                "&nbsp;"
            }
            elseif ($value -is [DateTime]) {
                $value.ToString("dd/MM/yyyy HH:mm:ss")
            }
            elseif ($value -is [bool]) {
                if ($value) { "Oui" } else { "Non" }
            }
            elseif ($value -is [array]) {
                $value -join ", "
            }
            else {
                $value
            }

            $html += "<li>$formattedValue</li>"
        }

        $html += "</$listTag>"

        return $html
    }
}

<#
.SYNOPSIS
Convertit un objet en code HTML.

.DESCRIPTION
La fonction ConvertTo-HtmlCode convertit un objet en bloc de code HTML avec coloration syntaxique.

.PARAMETER InputObject
L'objet à convertir en bloc de code HTML.

.PARAMETER Language
Le langage de programmation pour la coloration syntaxique.

.PARAMETER CssClass
La classe CSS à appliquer au bloc de code.

.EXAMPLE
$code = "function hello() { return 'Hello, world!'; }"
$htmlCode = ConvertTo-HtmlCode -InputObject $code -Language "javascript"

.NOTES
Cette fonction est utilisée en interne par Export-ExtractedInfoReportToHtml.
#>
function ConvertTo-HtmlCode {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [string]$Language = "plaintext",

        [Parameter(Mandatory = $false)]
        [string]$CssClass = "code-block"
    )

    # Convertir l'objet en chaîne de caractères
    $code = if ($InputObject -is [string]) {
        $InputObject
    }
    elseif ($InputObject -is [scriptblock]) {
        $InputObject.ToString()
    }
    else {
        $InputObject | Out-String
    }

    # Échapper les caractères spéciaux HTML
    $code = $code.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("`"", "&quot;").Replace("'", "&#39;")

    # Construire le bloc de code HTML
    $html = "<pre><code class=`"$CssClass language-$Language`">$code</code></pre>"

    return $html
}

<#
.SYNOPSIS
Convertit un objet en graphique HTML.

.DESCRIPTION
La fonction ConvertTo-HtmlChart convertit un objet en graphique HTML utilisant Chart.js.

.PARAMETER InputObject
L'objet à convertir en graphique HTML.

.PARAMETER ChartType
Le type de graphique. Les valeurs possibles sont "Bar", "Line", "Pie", "Scatter", "Area", "Histogram".

.PARAMETER LabelProperty
La propriété à utiliser pour les labels du graphique.

.PARAMETER ValueProperty
La propriété à utiliser pour les valeurs du graphique.

.PARAMETER Title
Le titre du graphique.

.PARAMETER Id
L'ID du graphique. Si non spécifié, un ID unique est généré.

.PARAMETER Width
La largeur du graphique en pixels.

.PARAMETER Height
La hauteur du graphique en pixels.

.PARAMETER Options
Options supplémentaires pour le graphique.

.EXAMPLE
$data = @(
    [PSCustomObject]@{ Category = "A"; Value = 10 },
    [PSCustomObject]@{ Category = "B"; Value = 20 },
    [PSCustomObject]@{ Category = "C"; Value = 15 }
)
$htmlChart = ConvertTo-HtmlChart -InputObject $data -ChartType "Bar" -LabelProperty "Category" -ValueProperty "Value" -Title "Répartition par catégorie"

.NOTES
Cette fonction est utilisée en interne par Export-ExtractedInfoReportToHtml.
#>
function ConvertTo-HtmlChart {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Bar", "Line", "Pie", "Scatter", "Area", "Histogram")]
        [string]$ChartType,

        [Parameter(Mandatory = $false)]
        [string]$LabelProperty,

        [Parameter(Mandatory = $false)]
        [string]$ValueProperty,

        [Parameter(Mandatory = $false)]
        [string]$Title = "",

        [Parameter(Mandatory = $false)]
        [string]$Id = "chart-$([guid]::NewGuid().ToString())",

        [Parameter(Mandatory = $false)]
        [int]$Width = 800,

        [Parameter(Mandatory = $false)]
        [int]$Height = 400,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{}
    )

    begin {
        $items = @()
    }

    process {
        if ($InputObject -is [array]) {
            $items += $InputObject
        }
        else {
            $items += $InputObject
        }
    }

    end {
        # Si aucun élément, retourner un message d'erreur
        if ($items.Count -eq 0) {
            return "<div class=`"alert alert-warning`">Aucune donnée pour le graphique</div>"
        }

        # Déterminer les propriétés à utiliser
        if (-not $PSBoundParameters.ContainsKey("LabelProperty") -and $items[0] -is [PSObject]) {
            $LabelProperty = $items[0].PSObject.Properties.Name[0]
        }
        elseif (-not $PSBoundParameters.ContainsKey("LabelProperty") -and $items[0] -is [hashtable]) {
            $LabelProperty = $items[0].Keys | Select-Object -First 1
        }

        if (-not $PSBoundParameters.ContainsKey("ValueProperty") -and $items[0] -is [PSObject]) {
            $ValueProperty = $items[0].PSObject.Properties.Name[1]
        }
        elseif (-not $PSBoundParameters.ContainsKey("ValueProperty") -and $items[0] -is [hashtable]) {
            $ValueProperty = $items[0].Keys | Select-Object -Skip 1 -First 1
        }

        # Extraire les labels et les valeurs
        $labels = @()
        $values = @()

        foreach ($item in $items) {
            if ($item -is [PSObject]) {
                $labels += $item.$LabelProperty
                $values += $item.$ValueProperty
            }
            elseif ($item -is [hashtable]) {
                $labels += $item[$LabelProperty]
                $values += $item[$ValueProperty]
            }
            else {
                $labels += "Item $($items.IndexOf($item) + 1)"
                $values += $item
            }
        }

        # Convertir les labels et les valeurs en JSON
        $labelsJson = $labels | ConvertTo-Json
        $valuesJson = $values | ConvertTo-Json

        # Construire le graphique HTML
        $html = @"
<div class="chart-container" style="position: relative; width: ${Width}px; height: ${Height}px;">
    <canvas id="$Id"></canvas>
</div>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        var ctx = document.getElementById('$Id').getContext('2d');
        var chart = new Chart(ctx, {
            type: '$(($ChartType).ToLower())',
            data: {
                labels: $labelsJson,
                datasets: [{
                    label: '$Title',
                    data: $valuesJson,
                    backgroundColor: [
                        'rgba(78, 121, 167, 0.7)',
                        'rgba(242, 142, 44, 0.7)',
                        'rgba(225, 87, 89, 0.7)',
                        'rgba(118, 183, 178, 0.7)',
                        'rgba(89, 161, 79, 0.7)',
                        'rgba(237, 201, 73, 0.7)',
                        'rgba(175, 122, 161, 0.7)',
                        'rgba(255, 157, 167, 0.7)',
                        'rgba(156, 117, 95, 0.7)',
                        'rgba(186, 176, 171, 0.7)'
                    ],
                    borderColor: [
                        'rgba(78, 121, 167, 1)',
                        'rgba(242, 142, 44, 1)',
                        'rgba(225, 87, 89, 1)',
                        'rgba(118, 183, 178, 1)',
                        'rgba(89, 161, 79, 1)',
                        'rgba(237, 201, 73, 1)',
                        'rgba(175, 122, 161, 1)',
                        'rgba(255, 157, 167, 1)',
                        'rgba(156, 117, 95, 1)',
                        'rgba(186, 176, 171, 1)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    title: {
                        display: true,
                        text: '$Title'
                    }
                }
            }
        });
    });
</script>
"@

        return $html
    }
}

# Exporter les fonctions
Export-ModuleMember -Function ConvertTo-HtmlTable, ConvertTo-HtmlList, ConvertTo-HtmlCode, ConvertTo-HtmlChart
