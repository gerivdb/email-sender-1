# Extract-EstimationValues.ps1
# Script pour extraire les valeurs numériques associées aux expressions d'estimation
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InputText,

    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeContext = $false,

    [Parameter(Mandatory = $false)]
    [int]$ContextSize = 10
)

# Importer les modules nécessaires
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "utils"

# Importer les fonctions utilitaires
. (Join-Path -Path $utilsDir -ChildPath "Format-EstimationOutput.ps1")

# Définir la fonction Find-EstimationExpressions directement ici au lieu d'importer Analyze-EstimationExpressions.ps1
function Find-EstimationExpressions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    # Définir les expressions d'estimation explicites
    $estimationExpressions = @{
        # Expressions d'estimation précises
        "precise"     = @(
            "estimé à",
            "estimation de",
            "estimé",
            "estimation",
            "évalué à",
            "évaluation de",
            "évalué",
            "évaluation",
            "prévu pour",
            "prévu",
            "prévision de",
            "prévision",
            "devrait prendre",
            "devrait durer",
            "durée estimée",
            "temps estimé",
            "temps prévu",
            "durée prévue"
        );

        # Expressions d'estimation approximatives
        "approximate" = @(
            "environ",
            "approximativement",
            "à peu près",
            "autour de",
            "aux alentours de",
            "plus ou moins",
            "±",
            "~"
        );

        # Expressions d'estimation avec plage
        "range"       = @(
            "entre",
            "de",
            "à",
            "-"
        );

        # Expressions d'estimation avec minimum
        "minimum"     = @(
            "au moins",
            "minimum",
            "min",
            "min.",
            "au minimum"
        );

        # Expressions d'estimation avec maximum
        "maximum"     = @(
            "au plus",
            "maximum",
            "max",
            "max.",
            "au maximum"
        )
    }

    $results = @()

    # Parcourir chaque catégorie d'expressions
    foreach ($category in $estimationExpressions.Keys) {
        $expressions = $estimationExpressions[$category]

        # Parcourir chaque expression dans la catégorie
        foreach ($expression in $expressions) {
            # Échapper les caractères spéciaux pour l'expression régulière
            $escapedExpression = [regex]::Escape($expression)

            # Créer un pattern qui capture l'expression et son contexte
            $pattern = "(\b$escapedExpression\b)"

            # Rechercher toutes les occurrences de l'expression
            $matchResults = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

            # Ajouter chaque occurrence aux résultats
            foreach ($match in $matchResults) {
                $startIndex = [Math]::Max(0, $match.Index - 10)
                $endIndex = [Math]::Min($Text.Length, $match.Index + $match.Length + 10)
                $contextBefore = $Text.Substring($startIndex, $match.Index - $startIndex)
                $contextAfter = $Text.Substring($match.Index + $match.Length, $endIndex - ($match.Index + $match.Length))

                $result = [PSCustomObject]@{
                    Category      = $category
                    Expression    = $expression
                    Match         = $match.Value
                    Index         = $match.Index
                    Length        = $match.Length
                    ContextBefore = $contextBefore
                    ContextAfter  = $contextAfter
                    FullContext   = "$contextBefore$($match.Value)$contextAfter"
                }

                $results += $result
            }
        }
    }

    return $results
}

# Les unités de temps sont maintenant définies directement dans la fonction Get-EstimationValues

# Fonction pour extraire les valeurs numériques associées aux expressions d'estimation
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

    # Extraire les valeurs numériques associées aux expressions d'estimation
    $results = Get-EstimationValues -Text $text

    # Formater les résultats selon le format de sortie demandé
    $formattedResults = Format-Output -Data $results -Format $OutputFormat -IncludeContext:$IncludeContext

    # Afficher les résultats
    return $formattedResults
}

# Exécuter la fonction principale
Main
