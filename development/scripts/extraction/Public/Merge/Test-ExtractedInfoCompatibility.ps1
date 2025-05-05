#Requires -Version 5.1
<#
.SYNOPSIS
Vérifie la compatibilité entre deux objets d'information extraite pour la fusion.

.DESCRIPTION
La fonction Test-ExtractedInfoCompatibility vérifie si deux objets d'information extraite sont
compatibles pour être fusionnés. Elle vérifie notamment que les objets sont du même type et
qu'ils proviennent de la même source.

.PARAMETER Info1
Le premier objet d'information extraite à vérifier.

.PARAMETER Info2
Le deuxième objet d'information extraite à vérifier.

.PARAMETER Force
Indique si la vérification doit être moins stricte, permettant la fusion d'objets de types différents
mais compatibles.

.OUTPUTS
[PSCustomObject] Un objet contenant les résultats de la vérification avec les propriétés suivantes :
- IsCompatible : Indique si les objets sont compatibles pour la fusion.
- Reasons : Un tableau de chaînes expliquant pourquoi les objets ne sont pas compatibles (si applicable).
- CompatibilityLevel : Un niveau de compatibilité (0-100) indiquant à quel point les objets sont compatibles.

.EXAMPLE
$text1 = New-TextExtractedInfo -Source "document.txt" -Text "Texte 1" -Language "fr"
$text2 = New-TextExtractedInfo -Source "document.txt" -Text "Texte 2" -Language "fr"
$result = Test-ExtractedInfoCompatibility -Info1 $text1 -Info2 $text2

Vérifie la compatibilité entre deux objets TextExtractedInfo.

.EXAMPLE
$text = New-TextExtractedInfo -Source "document.txt" -Text "Texte" -Language "fr"
$data = New-StructuredDataExtractedInfo -Source "document.txt" -Data @{ Key = "Value" } -DataFormat "Hashtable"
$result = Test-ExtractedInfoCompatibility -Info1 $text -Info2 $data -Force

Vérifie la compatibilité entre un objet TextExtractedInfo et un objet StructuredDataExtractedInfo
avec l'option Force activée.

.NOTES
Date de création : 2025-05-15
#>
function Test-ExtractedInfoCompatibility {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Info1,

        [Parameter(Mandatory = $true, Position = 1)]
        [hashtable]$Info2,

        [Parameter(Mandatory = $false)]
        [switch]$Force = $false
    )

    # Initialiser le résultat
    $result = [PSCustomObject]@{
        IsCompatible       = $true
        Reasons            = @()
        CompatibilityLevel = 100
    }

    # Vérifier que les deux objets sont des objets d'information extraite valides
    if (-not $Info1.ContainsKey('_Type') -or -not $Info1._Type.EndsWith('ExtractedInfo')) {
        $result.IsCompatible = $false
        $result.Reasons += "Le premier objet n'est pas un objet d'information extraite valide."
        $result.CompatibilityLevel = 0
        return $result
    }

    if (-not $Info2.ContainsKey('_Type') -or -not $Info2._Type.EndsWith('ExtractedInfo')) {
        $result.IsCompatible = $false
        $result.Reasons += "Le deuxième objet n'est pas un objet d'information extraite valide."
        $result.CompatibilityLevel = 0
        return $result
    }

    # Vérifier que les objets sont du même type
    if ($Info1._Type -ne $Info2._Type) {
        if (-not $Force) {
            $result.IsCompatible = $false
            $result.Reasons += "Les objets sont de types différents ($($Info1._Type) et $($Info2._Type))."
            $result.CompatibilityLevel = 0
        } else {
            $result.IsCompatible = $true
            $result.Reasons += "Les objets sont de types différents, mais la fusion est forcée."
            $result.CompatibilityLevel = 50
        }
    }

    # Vérifier que les objets proviennent de la même source
    if ($Info1.ContainsKey('Source') -and $Info2.ContainsKey('Source') -and $Info1.Source -ne $Info2.Source) {
        if (-not $Force) {
            $result.IsCompatible = $false
            $result.Reasons += "Les objets proviennent de sources différentes ($($Info1.Source) et $($Info2.Source))."
            $result.CompatibilityLevel -= 30
        } else {
            $result.Reasons += "Les objets proviennent de sources différentes, mais la fusion est forcée."
            $result.CompatibilityLevel -= 10
        }
    }

    # Vérifications spécifiques selon le type d'objet
    switch ($Info1._Type) {
        "TextExtractedInfo" {
            # Vérifier la compatibilité des langues
            if ($Info1.ContainsKey('Language') -and $Info2.ContainsKey('Language') -and $Info1.Language -ne $Info2.Language) {
                $result.Reasons += "Les objets ont des langues différentes ($($Info1.Language) et $($Info2.Language))."
                $result.CompatibilityLevel -= 20
            }
        }
        "StructuredDataExtractedInfo" {
            # Vérifier la compatibilité des formats de données
            if ($Info1.ContainsKey('DataFormat') -and $Info2.ContainsKey('DataFormat') -and $Info1.DataFormat -ne $Info2.DataFormat) {
                $result.Reasons += "Les objets ont des formats de données différents ($($Info1.DataFormat) et $($Info2.DataFormat))."
                $result.CompatibilityLevel -= 20
            }
        }
        "GeoLocationExtractedInfo" {
            # Vérifier la proximité des coordonnées
            if ($Info1.ContainsKey('Latitude') -and $Info1.ContainsKey('Longitude') -and
                $Info2.ContainsKey('Latitude') -and $Info2.ContainsKey('Longitude')) {

                $distance = [Math]::Sqrt([Math]::Pow($Info1.Latitude - $Info2.Latitude, 2) + [Math]::Pow($Info1.Longitude - $Info2.Longitude, 2))
                if ($distance -gt 0.1) {
                    # Seuil arbitraire pour la proximité
                    $result.Reasons += "Les coordonnées géographiques sont éloignées (distance: $([Math]::Round($distance, 4)))."
                    $result.CompatibilityLevel -= [Math]::Min(30, [Math]::Round($distance * 10))
                }
            }
        }
        "MediaExtractedInfo" {
            # Vérifier la compatibilité des types de médias
            if ($Info1.ContainsKey('MediaType') -and $Info2.ContainsKey('MediaType') -and $Info1.MediaType -ne $Info2.MediaType) {
                $result.Reasons += "Les objets ont des types de médias différents ($($Info1.MediaType) et $($Info2.MediaType))."
                $result.CompatibilityLevel -= 20
            }
        }
    }

    # Ajuster le niveau de compatibilité final
    if ([int]$result.CompatibilityLevel -le 0) {
        $result.CompatibilityLevel = 0
    }

    # Déterminer la compatibilité finale
    if (([int]$result.CompatibilityLevel -le 50) -and (-not $Force)) {
        $result.IsCompatible = $false
    }

    return $result
}

# La fonction sera exportée par le module principal
