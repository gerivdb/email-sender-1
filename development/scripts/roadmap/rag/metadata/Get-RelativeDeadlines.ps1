# Extract-RelativeDeadlines.ps1
# Script pour extraire les expressions de delai relatif
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$Content,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV", "Text")]
    [string]$OutputFormat = "JSON"
)

# Fonction pour extraire les expressions de delai relatif du type "dans X jours/semaines"
function Get-InXTimeExpressions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $results = @()

    # Expressions regulieres pour capturer les delais relatifs
    $patterns = @(
        # Pattern pour "dans X jours/semaines/mois/annees"
        '(?i)dans\s+(\d+(?:[,.]\d+)?)\s+(jour|jours|semaine|semaines|mois|an|ans|annee|annees)'

        # Pattern pour "d'ici X jours/semaines/mois/annees"
        '(?i)d''ici\s+(\d+(?:[,.]\d+)?)\s+(jour|jours|semaine|semaines|mois|an|ans|annee|annees)'

        # Pattern pour "sous X jours/semaines/mois/annees"
        '(?i)sous\s+(\d+(?:[,.]\d+)?)\s+(jour|jours|semaine|semaines|mois|an|ans|annee|annees)'

        # Pattern pour "en X jours/semaines/mois/annees"
        '(?i)en\s+(\d+(?:[,.]\d+)?)\s+(jour|jours|semaine|semaines|mois|an|ans|annee|annees)'

        # Pattern pour "X jours/semaines/mois/annees plus tard"
        '(?i)(\d+(?:[,.]\d+)?)\s+(jour|jours|semaine|semaines|mois|an|ans|annee|annees)\s+plus\s+tard'

        # Pattern pour "apres X jours/semaines/mois/annees"
        '(?i)apres\s+(\d+(?:[,.]\d+)?)\s+(jour|jours|semaine|semaines|mois|an|ans|annee|annees)'
    )

    foreach ($pattern in $patterns) {
        $regexMatches = [regex]::Matches($Text, $pattern)

        foreach ($match in $regexMatches) {
            $value = $match.Groups[1].Value
            $unit = $match.Groups[2].Value
            $fullMatch = $match.Value
            $startIndex = $match.Index
            $endIndex = $startIndex + $match.Length

            # Normaliser la valeur (remplacer la virgule par un point)
            $normalizedValue = $value -replace ',', '.'

            # Convertir en nombre
            try {
                $numericValue = [double]$normalizedValue
            } catch {
                Write-Warning "Erreur lors de la conversion de la valeur '$value' en nombre: $_"
                $numericValue = 0
            }

            # Normaliser l'unite
            $normalizedUnit = switch -Regex ($unit) {
                '^jour$|^jours$' { "jours" }
                '^semaine$|^semaines$' { "semaines" }
                '^mois$' { "mois" }
                '^an$|^ans$|^annee$|^annees$' { "annees" }
                default { $unit }
            }

            # Determiner le type d'expression
            $expressionType = switch -Regex ($fullMatch) {
                '^dans|^d''ici' { "Futur" }
                '^sous|^en' { "Delai" }
                'plus tard|apres' { "Relatif" }
                default { "Inconnu" }
            }

            # Creer un objet pour stocker les informations
            $result = [PSCustomObject]@{
                Expression = $fullMatch
                Value      = $numericValue
                Unit       = $normalizedUnit
                Type       = $expressionType
                StartIndex = $startIndex
                EndIndex   = $endIndex
                Context    = Get-TextContext -Text $Text -StartIndex $startIndex -EndIndex $endIndex -WindowSize 50
            }

            $results += $result
        }
    }

    return $results
}

# Fonction pour extraire le contexte autour d'une expression
function Get-TextContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [int]$StartIndex,

        [Parameter(Mandatory = $true)]
        [int]$EndIndex,

        [Parameter(Mandatory = $false)]
        [int]$WindowSize = 50
    )

    $contextStart = [Math]::Max(0, $StartIndex - $WindowSize)
    $contextEnd = [Math]::Min($Text.Length, $EndIndex + $WindowSize)

    $beforeContext = $Text.Substring($contextStart, $StartIndex - $contextStart)
    $expression = $Text.Substring($StartIndex, $EndIndex - $StartIndex)
    $afterContext = $Text.Substring($EndIndex, $contextEnd - $EndIndex)

    return [PSCustomObject]@{
        Before     = $beforeContext
        Expression = $expression
        After      = $afterContext
        Full       = "$beforeContext$expression$afterContext"
    }
}

# Fonction pour extraire les identifiants de taches associes aux expressions de delai
function Get-TaskIdentifiers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Expression
    )

    $taskIdPattern = '\*\*([0-9.]+)\*\*'
    $context = $Expression.Context.Full

    $taskMatches = [regex]::Matches($context, $taskIdPattern)

    if ($taskMatches.Count -gt 0) {
        # Prendre l'identifiant de tache le plus proche de l'expression
        $closestTaskId = $null
        $minDistance = [int]::MaxValue

        foreach ($taskMatch in $taskMatches) {
            $taskId = $taskMatch.Groups[1].Value
            $taskIndex = $taskMatch.Index

            # Calculer la distance entre l'expression et l'identifiant de tache
            $expressionPosition = $context.IndexOf($Expression.Expression)
            $distance = [Math]::Abs($expressionPosition - $taskIndex)

            if ($distance -lt $minDistance) {
                $minDistance = $distance
                $closestTaskId = $taskId
            }
        }

        return $closestTaskId
    }

    return $null
}

# Fonction principale pour extraire les expressions de delai relatif
function Get-RelativeDeadlines {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "CSV", "Text")]
        [string]$OutputFormat = "JSON"
    )

    # Charger le contenu si un chemin de fichier est specifie
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Le fichier specifie n'existe pas: $FilePath"
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    if ([string]::IsNullOrEmpty($Content)) {
        Write-Error "Aucun contenu a analyser."
        return $null
    }

    # Extraire les expressions de delai relatif
    $inXTimeExpressions = Get-InXTimeExpressions -Text $Content

    # Associer les expressions aux identifiants de taches
    foreach ($expression in $inXTimeExpressions) {
        $taskId = Get-TaskIdentifiers -Text $Content -Expression $expression
        $expression | Add-Member -MemberType NoteProperty -Name "TaskId" -Value $taskId
    }

    # Regrouper les expressions par identifiant de tache
    $taskExpressions = @{}

    foreach ($expression in $inXTimeExpressions) {
        $taskId = $expression.TaskId

        if ($null -ne $taskId) {
            if (-not $taskExpressions.ContainsKey($taskId)) {
                $taskExpressions[$taskId] = @()
            }

            $taskExpressions[$taskId] += $expression
        }
    }

    # Creer l'objet de resultat
    $result = [PSCustomObject]@{
        RelativeDeadlines     = [PSCustomObject]@{
            InXTimeExpressions = $inXTimeExpressions
        }
        TaskRelativeDeadlines = $taskExpressions
        Stats                 = [PSCustomObject]@{
            TotalExpressions   = $inXTimeExpressions.Count
            TasksWithDeadlines = $taskExpressions.Count
        }
    }

    # Formater la sortie selon le format demande
    $output = $null

    switch ($OutputFormat) {
        "JSON" {
            $output = $result | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $output = "# Expressions de delai relatif`n`n"
            $output += "## Statistiques`n`n"
            $output += "- Nombre total d'expressions: $($result.Stats.TotalExpressions)`n"
            $output += "- Taches avec delais: $($result.Stats.TasksWithDeadlines)`n`n"

            $output += "## Expressions par tache`n`n"

            foreach ($taskId in $result.TaskRelativeDeadlines.Keys | Sort-Object) {
                $expressions = $result.TaskRelativeDeadlines[$taskId]
                $output += "### Tache $taskId`n`n"

                foreach ($expression in $expressions) {
                    $output += "- $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.Value) $($expression.Unit))`n"
                    $output += "  Contexte: ...$($expression.Context.Before)__$($expression.Context.Expression)__$($expression.Context.After)...`n`n"
                }
            }
        }
        "CSV" {
            $output = "TaskId,Expression,Value,Unit,Type`n"

            foreach ($expression in $inXTimeExpressions) {
                $taskId = if ($null -eq $expression.TaskId) { "N/A" } else { $expression.TaskId }
                $output += "$taskId,`"$($expression.Expression)`",$($expression.Value),$($expression.Unit),$($expression.Type)`n"
            }
        }
        "Text" {
            $output = "Expressions de delai relatif`n`n"
            $output += "Statistiques:`n"
            $output += "  Nombre total d'expressions: $($result.Stats.TotalExpressions)`n"
            $output += "  Taches avec delais: $($result.Stats.TasksWithDeadlines)`n`n"

            $output += "Expressions par tache:`n`n"

            foreach ($taskId in $result.TaskRelativeDeadlines.Keys | Sort-Object) {
                $expressions = $result.TaskRelativeDeadlines[$taskId]
                $output += "Tache ${taskId}:`n"

                foreach ($expression in $expressions) {
                    $output += "  - $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.Value) $($expression.Unit))`n"
                    $output += "    Contexte: ...$($expression.Context.Before)__$($expression.Context.Expression)__$($expression.Context.After)...`n`n"
                }
            }
        }
    }

    # Sauvegarder la sortie si un chemin est specifie
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $output | Out-File -FilePath $OutputPath -Encoding utf8
    }

    return $output
}

# Executer la fonction principale avec les parametres fournis
Get-RelativeDeadlines -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
