# Extract-TodayRelativeDeadlines.ps1
# Script pour extraire les expressions de delai relatif par rapport a aujourd'hui
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

# Fonction pour extraire les expressions de delai relatif par rapport a aujourd'hui
function Get-TodayRelativeExpressions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    $results = @()
    
    # Expressions regulieres pour capturer les delais relatifs par rapport a aujourd'hui
    $patterns = @(
        # Pattern pour "aujourd'hui"
        '(?i)(aujourd''hui|ce jour)'
        
        # Pattern pour "demain"
        '(?i)(demain)'
        
        # Pattern pour "apres-demain"
        '(?i)(apres-demain|apres demain)'
        
        # Pattern pour "hier"
        '(?i)(hier)'
        
        # Pattern pour "avant-hier"
        '(?i)(avant-hier|avant hier)'
        
        # Pattern pour "cette semaine"
        '(?i)(cette semaine)'
        
        # Pattern pour "la semaine prochaine"
        '(?i)(la semaine prochaine|semaine prochaine)'
        
        # Pattern pour "la semaine derniere"
        '(?i)(la semaine derniere|semaine derniere)'
        
        # Pattern pour "ce mois-ci"
        '(?i)(ce mois-ci|ce mois)'
        
        # Pattern pour "le mois prochain"
        '(?i)(le mois prochain|mois prochain)'
        
        # Pattern pour "le mois dernier"
        '(?i)(le mois dernier|mois dernier)'
        
        # Pattern pour "cette annee"
        '(?i)(cette annee|cette année)'
        
        # Pattern pour "l'annee prochaine"
        '(?i)(l''annee prochaine|l''année prochaine|annee prochaine|année prochaine)'
        
        # Pattern pour "l'annee derniere"
        '(?i)(l''annee derniere|l''année dernière|annee derniere|année dernière)'
    )
    
    foreach ($pattern in $patterns) {
        $regexMatches = [regex]::Matches($Text, $pattern)
        
        foreach ($match in $regexMatches) {
            $expression = $match.Value
            $startIndex = $match.Index
            $endIndex = $startIndex + $match.Length
            
            # Determiner le type d'expression et la valeur relative
            $relativeValue = 0
            $unit = "jours"
            $type = "Aujourd'hui"
            
            switch -Regex ($expression) {
                '(?i)aujourd''hui|ce jour' {
                    $relativeValue = 0
                    $unit = "jours"
                    $type = "Aujourd'hui"
                }
                '(?i)demain' {
                    $relativeValue = 1
                    $unit = "jours"
                    $type = "Futur"
                }
                '(?i)apres-demain|apres demain' {
                    $relativeValue = 2
                    $unit = "jours"
                    $type = "Futur"
                }
                '(?i)hier' {
                    $relativeValue = -1
                    $unit = "jours"
                    $type = "Passe"
                }
                '(?i)avant-hier|avant hier' {
                    $relativeValue = -2
                    $unit = "jours"
                    $type = "Passe"
                }
                '(?i)cette semaine' {
                    $relativeValue = 0
                    $unit = "semaines"
                    $type = "Aujourd'hui"
                }
                '(?i)la semaine prochaine|semaine prochaine' {
                    $relativeValue = 1
                    $unit = "semaines"
                    $type = "Futur"
                }
                '(?i)la semaine derniere|semaine derniere' {
                    $relativeValue = -1
                    $unit = "semaines"
                    $type = "Passe"
                }
                '(?i)ce mois-ci|ce mois' {
                    $relativeValue = 0
                    $unit = "mois"
                    $type = "Aujourd'hui"
                }
                '(?i)le mois prochain|mois prochain' {
                    $relativeValue = 1
                    $unit = "mois"
                    $type = "Futur"
                }
                '(?i)le mois dernier|mois dernier' {
                    $relativeValue = -1
                    $unit = "mois"
                    $type = "Passe"
                }
                '(?i)cette annee|cette année' {
                    $relativeValue = 0
                    $unit = "annees"
                    $type = "Aujourd'hui"
                }
                '(?i)l''annee prochaine|l''année prochaine|annee prochaine|année prochaine' {
                    $relativeValue = 1
                    $unit = "annees"
                    $type = "Futur"
                }
                '(?i)l''annee derniere|l''année dernière|annee derniere|année dernière' {
                    $relativeValue = -1
                    $unit = "annees"
                    $type = "Passe"
                }
            }
            
            # Calculer la date absolue
            $today = Get-Date
            $absoluteDate = switch ($unit) {
                "jours" { $today.AddDays($relativeValue) }
                "semaines" { $today.AddDays($relativeValue * 7) }
                "mois" { $today.AddMonths($relativeValue) }
                "annees" { $today.AddYears($relativeValue) }
                default { $today }
            }
            
            # Creer un objet pour stocker les informations
            $result = [PSCustomObject]@{
                Expression = $expression
                RelativeValue = $relativeValue
                Unit = $unit
                Type = $type
                AbsoluteDate = $absoluteDate.ToString("yyyy-MM-dd")
                StartIndex = $startIndex
                EndIndex = $endIndex
                Context = Get-TextContext -Text $Text -StartIndex $startIndex -EndIndex $endIndex -WindowSize 50
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
        Before = $beforeContext
        Expression = $expression
        After = $afterContext
        Full = "$beforeContext$expression$afterContext"
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

# Fonction principale pour extraire les expressions de delai relatif par rapport a aujourd'hui
function Get-TodayRelativeDeadlines {
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
    
    # Extraire les expressions de delai relatif par rapport a aujourd'hui
    $todayRelativeExpressions = Get-TodayRelativeExpressions -Text $Content
    
    # Associer les expressions aux identifiants de taches
    foreach ($expression in $todayRelativeExpressions) {
        $taskId = Get-TaskIdentifiers -Text $Content -Expression $expression
        $expression | Add-Member -MemberType NoteProperty -Name "TaskId" -Value $taskId
    }
    
    # Regrouper les expressions par identifiant de tache
    $taskExpressions = @{}
    
    foreach ($expression in $todayRelativeExpressions) {
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
        TodayRelativeDeadlines = [PSCustomObject]@{
            Expressions = $todayRelativeExpressions
        }
        TaskTodayRelativeDeadlines = $taskExpressions
        Stats = [PSCustomObject]@{
            TotalExpressions = $todayRelativeExpressions.Count
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
            $output = "# Expressions de delai relatif par rapport a aujourd'hui`n`n"
            $output += "## Statistiques`n`n"
            $output += "- Nombre total d'expressions: $($result.Stats.TotalExpressions)`n"
            $output += "- Taches avec delais: $($result.Stats.TasksWithDeadlines)`n`n"
            
            $output += "## Expressions par tache`n`n"
            
            foreach ($taskId in $result.TaskTodayRelativeDeadlines.Keys | Sort-Object) {
                $expressions = $result.TaskTodayRelativeDeadlines[$taskId]
                $output += "### Tache ${taskId}`n`n"
                
                foreach ($expression in $expressions) {
                    $output += "- $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.RelativeValue) $($expression.Unit), Date: $($expression.AbsoluteDate))`n"
                    $output += "  Contexte: ...$($expression.Context.Before)__$($expression.Context.Expression)__$($expression.Context.After)...`n`n"
                }
            }
        }
        "CSV" {
            $output = "TaskId,Expression,RelativeValue,Unit,Type,AbsoluteDate`n"
            
            foreach ($expression in $todayRelativeExpressions) {
                $taskId = if ($null -eq $expression.TaskId) { "N/A" } else { $expression.TaskId }
                $output += "$taskId,`"$($expression.Expression)`",$($expression.RelativeValue),$($expression.Unit),$($expression.Type),$($expression.AbsoluteDate)`n"
            }
        }
        "Text" {
            $output = "Expressions de delai relatif par rapport a aujourd'hui`n`n"
            $output += "Statistiques:`n"
            $output += "  Nombre total d'expressions: $($result.Stats.TotalExpressions)`n"
            $output += "  Taches avec delais: $($result.Stats.TasksWithDeadlines)`n`n"
            
            $output += "Expressions par tache:`n`n"
            
            foreach ($taskId in $result.TaskTodayRelativeDeadlines.Keys | Sort-Object) {
                $expressions = $result.TaskTodayRelativeDeadlines[$taskId]
                $output += "Tache ${taskId}:`n"
                
                foreach ($expression in $expressions) {
                    $output += "  - $($expression.Expression) (Type: $($expression.Type), Valeur: $($expression.RelativeValue) $($expression.Unit), Date: $($expression.AbsoluteDate))`n"
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
Get-TodayRelativeDeadlines -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
