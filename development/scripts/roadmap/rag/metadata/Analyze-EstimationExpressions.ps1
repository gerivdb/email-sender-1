# Analyze-EstimationExpressions.ps1
# Script pour analyser les expressions d'estimation explicites dans les textes de tâches
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
$metadataDir = $scriptDir
$utilsDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "utils"

# Importer les fonctions utilitaires
. (Join-Path -Path $utilsDir -ChildPath "Format-EstimationOutput.ps1")

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
        "durée prévue",
        "estimated at",
        "estimated to",
        "estimated",
        "estimate of",
        "estimate",
        "evaluated at",
        "evaluated to",
        "evaluated",
        "evaluation of",
        "evaluation",
        "expected to take",
        "expected duration",
        "expected time",
        "should take",
        "should last",
        "will take",
        "will last"
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
        "±",
        "approximately",
        "about",
        "around",
        "roughly",
        "more or less",
        "circa",
        "ca.",
        "c.",
        "~"
    );

    # Expressions d'estimation avec plage
    "range"       = @(
        "entre",
        "de",
        "à",
        "from",
        "to",
        "between",
        "and",
        "-"
    );

    # Expressions d'estimation avec minimum
    "minimum"     = @(
        "au moins",
        "minimum",
        "min",
        "min.",
        "au minimum",
        "at least",
        "minimum of",
        "min of",
        "no less than"
    );

    # Expressions d'estimation avec maximum
    "maximum"     = @(
        "au plus",
        "maximum",
        "max",
        "max.",
        "au maximum",
        "at most",
        "maximum of",
        "max of",
        "no more than",
        "up to"
    )
}

# Fonction pour analyser les expressions d'estimation dans un texte
function Find-EstimationExpressions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

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
            $matches = [regex]::Matches($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

            # Ajouter chaque occurrence aux résultats
            foreach ($match in $matches) {
                $startIndex = [Math]::Max(0, $match.Index - $ContextSize)
                $endIndex = [Math]::Min($Text.Length, $match.Index + $match.Length + $ContextSize)
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

    # Analyser les expressions d'estimation dans le texte
    $results = Find-EstimationExpressions -Text $text

    # Formater les résultats selon le format de sortie demandé
    $formattedResults = Format-Output -Data $results -Format $OutputFormat -IncludeContext:$IncludeContext

    # Afficher les résultats
    return $formattedResults
}

# Exécuter la fonction principale
Main
