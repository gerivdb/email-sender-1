<#
.SYNOPSIS
    Remplace un motif dans un texte.

.DESCRIPTION
    La fonction Replace-RoadmapText remplace un motif dans un texte.
    Elle prend en charge différents types de remplacement et peut être utilisée pour
    remplacer des motifs dans les textes du module RoadmapParser.

.PARAMETER Text
    Le texte dans lequel effectuer le remplacement.

.PARAMETER Pattern
    Le motif à rechercher.

.PARAMETER Replacement
    Le texte de remplacement.

.PARAMETER ReplaceType
    Le type de remplacement à effectuer. Valeurs possibles :
    - Simple : Remplacement simple (sensible à la casse)
    - CaseInsensitive : Remplacement insensible à la casse
    - Regex : Remplacement par expression régulière
    - Wildcard : Remplacement avec caractères génériques
    - WholeWord : Remplacement de mots entiers
    - FirstOccurrence : Remplacement de la première occurrence
    - LastOccurrence : Remplacement de la dernière occurrence
    - AllOccurrences : Remplacement de toutes les occurrences
    - Custom : Remplacement personnalisé

.PARAMETER CustomReplace
    La fonction de remplacement personnalisée à utiliser.
    Utilisé uniquement lorsque ReplaceType est "Custom".

.PARAMETER MaxReplacements
    Le nombre maximum de remplacements à effectuer.
    Par défaut, c'est 0 (tous les remplacements).

.PARAMETER Culture
    La culture à utiliser pour le remplacement.
    Par défaut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec du remplacement.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec du remplacement.

.EXAMPLE
    Replace-RoadmapText -Text "Hello World" -Pattern "world" -Replacement "Universe" -ReplaceType CaseInsensitive
    Remplace "world" par "Universe" dans "Hello World" de manière insensible à la casse.

.EXAMPLE
    Replace-RoadmapText -Text "Hello World" -Pattern "^Hello" -Replacement "Hi" -ReplaceType Regex
    Remplace le motif regex "^Hello" par "Hi" dans "Hello World".

.OUTPUTS
    [string] Le texte avec les remplacements effectués.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Replace-RoadmapText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern,

        [Parameter(Mandatory = $true, Position = 2)]
        [AllowEmptyString()]
        [string]$Replacement,

        [Parameter(Mandatory = $true, Position = 3)]
        [ValidateSet("Simple", "CaseInsensitive", "Regex", "Wildcard", "WholeWord", "FirstOccurrence", "LastOccurrence", "AllOccurrences", "Custom")]
        [string]$ReplaceType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomReplace,

        [Parameter(Mandatory = $false)]
        [int]$MaxReplacements = 0,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat du remplacement
    $result = $Text
    $replaceSucceeded = $false

    # Effectuer le remplacement selon le type
    try {
        switch ($ReplaceType) {
            "Simple" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $result = $Text
                } else {
                    if ($MaxReplacements -gt 0) {
                        $count = 0
                        $index = 0
                        $newText = ""

                        while ($count -lt $MaxReplacements -and ($index = $result.IndexOf($Pattern, $index)) -ge 0) {
                            $newText += $result.Substring($newText.Length, $index - $newText.Length) + $Replacement
                            $index += $Pattern.Length
                            $count++
                        }

                        if ($count -gt 0) {
                            $newText += $result.Substring($newText.Length)
                            $result = $newText
                        }
                    } else {
                        $result = $result.Replace($Pattern, $Replacement)
                    }
                }
                $replaceSucceeded = $true
            }
            "CaseInsensitive" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $result = $Text
                } else {
                    $regex = [regex]::new([regex]::Escape($Pattern), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

                    if ($MaxReplacements -gt 0) {
                        $result = $regex.Replace($result, $Replacement, $MaxReplacements)
                    } else {
                        $result = $regex.Replace($result, $Replacement)
                    }
                }
                $replaceSucceeded = $true
            }
            "Regex" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = $Text
                } else {
                    $regex = [regex]$Pattern

                    if ($MaxReplacements -gt 0) {
                        $result = $regex.Replace($result, $Replacement, $MaxReplacements)
                    } else {
                        $result = $regex.Replace($result, $Replacement)
                    }
                }
                $replaceSucceeded = $true
            }
            "Wildcard" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = $Text
                } else {
                    # Convertir le motif wildcard en regex
                    $regexPattern = "^" + [regex]::Escape($Pattern).Replace("\*", ".*").Replace("\?", ".") + "$"
                    $regex = [regex]$regexPattern

                    # Diviser le texte en lignes et remplacer dans chaque ligne
                    $lines = $result -split "`r`n|`r|`n"
                    $newLines = @()
                    $count = 0

                    foreach ($line in $lines) {
                        if ($regex.IsMatch($line) -and ($MaxReplacements -eq 0 -or $count -lt $MaxReplacements)) {
                            $newLines += $Replacement
                            $count++
                        } else {
                            $newLines += $line
                        }
                    }

                    $result = $newLines -join [Environment]::NewLine
                }
                $replaceSucceeded = $true
            }
            "WholeWord" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = $Text
                } else {
                    # Créer un motif regex pour les mots entiers
                    $regexPattern = "\b" + [regex]::Escape($Pattern) + "\b"
                    $regex = [regex]$regexPattern

                    if ($MaxReplacements -gt 0) {
                        $result = $regex.Replace($result, $Replacement, $MaxReplacements)
                    } else {
                        $result = $regex.Replace($result, $Replacement)
                    }
                }
                $replaceSucceeded = $true
            }
            "FirstOccurrence" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $result = $Text
                } else {
                    $index = $result.IndexOf($Pattern)

                    if ($index -ge 0) {
                        $result = $result.Substring(0, $index) + $Replacement + $result.Substring($index + $Pattern.Length)
                    }
                }
                $replaceSucceeded = $true
            }
            "LastOccurrence" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $result = $Text
                } else {
                    $index = $result.LastIndexOf($Pattern)

                    if ($index -ge 0) {
                        $result = $result.Substring(0, $index) + $Replacement + $result.Substring($index + $Pattern.Length)
                    }
                }
                $replaceSucceeded = $true
            }
            "AllOccurrences" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $result = $Text
                } else {
                    if ($MaxReplacements -gt 0) {
                        $count = 0
                        $index = 0
                        $newText = ""
                        $lastIndex = 0

                        while ($count -lt $MaxReplacements -and ($index = $result.IndexOf($Pattern, $index)) -ge 0) {
                            $newText += $result.Substring($lastIndex, $index - $lastIndex) + $Replacement
                            $lastIndex = $index + $Pattern.Length
                            $index = $lastIndex
                            $count++
                        }

                        if ($count -gt 0) {
                            $newText += $result.Substring($lastIndex)
                            $result = $newText
                        }
                    } else {
                        $result = $result.Replace($Pattern, $Replacement)
                    }
                }
                $replaceSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomReplace) {
                    throw "Le paramètre CustomReplace est requis lorsque le type de remplacement est Custom."
                } else {
                    $result = & $CustomReplace $Text $Pattern $Replacement
                }
                $replaceSucceeded = $true
            }
        }
    } catch {
        $replaceSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de remplacer le motif '$Pattern' par '$Replacement' dans le texte avec le type de remplacement $ReplaceType : $_"
        }
    }

    # Gérer l'échec du remplacement
    if (-not $replaceSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $Text
        }
    }

    return $result
}
