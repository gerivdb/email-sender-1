# Module d'analyse de la qualitÃ© du code pour le Script Manager
# Ce module Ã©value la qualitÃ© du code des scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, quality, code

function Measure-CodeQuality {
    <#
    .SYNOPSIS
        Ã‰value la qualitÃ© du code d'un script
    .DESCRIPTION
        Analyse le code pour Ã©valuer sa qualitÃ© selon plusieurs critÃ¨res
    .PARAMETER Content
        Contenu du script Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Measure-CodeQuality -Content $scriptContent -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("PowerShell", "Python", "Batch", "Shell", "Unknown")]
        [string]$ScriptType
    )
    
    # Initialiser l'objet de qualitÃ©
    $Quality = @{
        Score = 0
        MaxScore = 100
        Metrics = @{}
        Issues = @()
        Recommendations = @()
    }
    
    # DÃ©finir les mÃ©triques de base
    $Metrics = @{
        LineCount = 0
        CommentRatio = 0
        AverageLineLength = 0
        MaxLineLength = 0
        EmptyLineRatio = 0
        FunctionCount = 0
        ComplexityScore = 0
        DuplicationScore = 0
    }
    
    # Analyser les lignes
    $Lines = $Content -split "`n"
    $NonEmptyLines = $Lines | Where-Object { $_.Trim() -ne "" }
    $Metrics.LineCount = $Lines.Count
    $Metrics.EmptyLineRatio = if ($Lines.Count -gt 0) { ($Lines.Count - $NonEmptyLines.Count) / $Lines.Count } else { 0 }
    
    # Calculer la longueur moyenne et maximale des lignes
    $LineLengths = $NonEmptyLines | ForEach-Object { $_.Length }
    $Metrics.AverageLineLength = if ($LineLengths.Count -gt 0) { ($LineLengths | Measure-Object -Average).Average } else { 0 }
    $Metrics.MaxLineLength = if ($LineLengths.Count -gt 0) { ($LineLengths | Measure-Object -Maximum).Maximum } else { 0 }
    
    # Analyse spÃ©cifique au type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Compter les commentaires et calculer le ratio
            $CommentLines = $Lines | Where-Object { $_.Trim() -match "^#" }
            $Metrics.CommentRatio = if ($NonEmptyLines.Count -gt 0) { $CommentLines.Count / $NonEmptyLines.Count } else { 0 }
            
            # Compter les fonctions
            $FunctionMatches = [regex]::Matches($Content, "function\s+([a-zA-Z0-9_-]+)")
            $Metrics.FunctionCount = $FunctionMatches.Count
            
            # Calculer la complexitÃ©
            $Conditionals = ([regex]::Matches($Content, "if\s*\(")).Count + ([regex]::Matches($Content, "elseif\s*\(")).Count + ([regex]::Matches($Content, "switch\s*\(")).Count
            $Loops = ([regex]::Matches($Content, "foreach\s*\(")).Count + ([regex]::Matches($Content, "for\s*\(")).Count + ([regex]::Matches($Content, "while\s*\(")).Count + ([regex]::Matches($Content, "do\s*\{")).Count
            $Metrics.ComplexityScore = $Metrics.FunctionCount + $Conditionals + $Loops
            
            # VÃ©rifier les problÃ¨mes courants
            if ($Metrics.MaxLineLength -gt 120) {
                $Quality.Issues += "Lignes trop longues (max: $($Metrics.MaxLineLength) caractÃ¨res)"
                $Quality.Recommendations += "Limiter la longueur des lignes Ã  120 caractÃ¨res maximum"
            }
            
            if ($Metrics.CommentRatio -lt 0.1) {
                $Quality.Issues += "Ratio de commentaires faible ($([math]::Round($Metrics.CommentRatio * 100, 1))%)"
                $Quality.Recommendations += "Ajouter plus de commentaires pour expliquer le code"
            }
            
            if ($Metrics.EmptyLineRatio -gt 0.3) {
                $Quality.Issues += "Trop de lignes vides ($([math]::Round($Metrics.EmptyLineRatio * 100, 1))%)"
                $Quality.Recommendations += "RÃ©duire le nombre de lignes vides"
            }
            
            # VÃ©rifier l'utilisation de $null Ã  gauche des comparaisons
            $NullComparisons = [regex]::Matches($Content, "if\s*\(\s*(\$\w+)\s*-eq\s*\$null\s*\)")
            if ($NullComparisons.Count -gt 0) {
                $Quality.Issues += "Comparaisons avec `$null du mauvais cÃ´tÃ©"
                $Quality.Recommendations += "Placer `$null Ã  gauche des comparaisons: if (`$null -eq `$variable)"
            }
            
            # VÃ©rifier l'utilisation des verbes approuvÃ©s
            $UnapprovedVerbs = @()
            $FunctionNames = $FunctionMatches | ForEach-Object { $_.Groups[1].Value }
            foreach ($Function in $FunctionNames) {
                $Verb = $Function -split "-" | Select-Object -First 1
                if ($Verb -and -not (Get-Verb | Where-Object { $_.Verb -eq $Verb })) {
                    $UnapprovedVerbs += $Verb
                }
            }
            
            if ($UnapprovedVerbs.Count -gt 0) {
                $Quality.Issues += "Utilisation de verbes non approuvÃ©s: $($UnapprovedVerbs -join ", ")"
                $Quality.Recommendations += "Utiliser uniquement des verbes approuvÃ©s pour les fonctions PowerShell"
            }
        }
        "Python" {
            # Compter les commentaires et calculer le ratio
            $CommentLines = $Lines | Where-Object { $_.Trim() -match "^#" }
            $Metrics.CommentRatio = if ($NonEmptyLines.Count -gt 0) { $CommentLines.Count / $NonEmptyLines.Count } else { 0 }
            
            # Compter les fonctions
            $FunctionMatches = [regex]::Matches($Content, "def\s+([a-zA-Z0-9_]+)")
            $Metrics.FunctionCount = $FunctionMatches.Count
            
            # Calculer la complexitÃ©
            $Conditionals = ([regex]::Matches($Content, "if\s+")).Count + ([regex]::Matches($Content, "elif\s+")).Count
            $Loops = ([regex]::Matches($Content, "for\s+")).Count + ([regex]::Matches($Content, "while\s+")).Count
            $Metrics.ComplexityScore = $Metrics.FunctionCount + $Conditionals + $Loops
            
            # VÃ©rifier les problÃ¨mes courants
            if ($Metrics.MaxLineLength -gt 79) {
                $Quality.Issues += "Lignes trop longues (max: $($Metrics.MaxLineLength) caractÃ¨res)"
                $Quality.Recommendations += "Limiter la longueur des lignes Ã  79 caractÃ¨res (PEP 8)"
            }
            
            if ($Metrics.CommentRatio -lt 0.1) {
                $Quality.Issues += "Ratio de commentaires faible ($([math]::Round($Metrics.CommentRatio * 100, 1))%)"
                $Quality.Recommendations += "Ajouter plus de commentaires pour expliquer le code"
            }
            
            # VÃ©rifier l'utilisation de docstrings
            $DocstringCount = ([regex]::Matches($Content, '""".*?"""')).Count + ([regex]::Matches($Content, "'''.*?'''")).Count
            if ($Metrics.FunctionCount > 0 -and $DocstringCount < $Metrics.FunctionCount) {
                $Quality.Issues += "Manque de docstrings pour certaines fonctions"
                $Quality.Recommendations += "Ajouter des docstrings Ã  toutes les fonctions"
            }
        }
        "Batch" {
            # Compter les commentaires et calculer le ratio
            $CommentLines = $Lines | Where-Object { $_.Trim() -match "^(rem|::)" }
            $Metrics.CommentRatio = if ($NonEmptyLines.Count -gt 0) { $CommentLines.Count / $NonEmptyLines.Count } else { 0 }
            
            # Compter les labels (comme des fonctions)
            $LabelMatches = [regex]::Matches($Content, "^:([a-zA-Z0-9_-]+)")
            $Metrics.FunctionCount = $LabelMatches.Count
            
            # Calculer la complexitÃ©
            $Conditionals = ([regex]::Matches($Content, "if\s+")).Count
            $Loops = ([regex]::Matches($Content, "for\s+")).Count
            $Metrics.ComplexityScore = $Metrics.FunctionCount + $Conditionals + $Loops
            
            # VÃ©rifier les problÃ¨mes courants
            if ($Metrics.CommentRatio -lt 0.1) {
                $Quality.Issues += "Ratio de commentaires faible ($([math]::Round($Metrics.CommentRatio * 100, 1))%)"
                $Quality.Recommendations += "Ajouter plus de commentaires pour expliquer le code"
            }
            
            # VÃ©rifier l'utilisation de chemins absolus
            $AbsolutePaths = [regex]::Matches($Content, "[C-Z]:\\")
            if ($AbsolutePaths.Count -gt 0) {
                $Quality.Issues += "Utilisation de chemins absolus"
                $Quality.Recommendations += "Utiliser des chemins relatifs ou des variables d'environnement"
            }
        }
        "Shell" {
            # Compter les commentaires et calculer le ratio
            $CommentLines = $Lines | Where-Object { $_.Trim() -match "^#" }
            $Metrics.CommentRatio = if ($NonEmptyLines.Count -gt 0) { $CommentLines.Count / $NonEmptyLines.Count } else { 0 }
            
            # Compter les fonctions
            $FunctionMatches = [regex]::Matches($Content, "function\s+([a-zA-Z0-9_-]+)|([a-zA-Z0-9_-]+)\(\)")
            $Metrics.FunctionCount = $FunctionMatches.Count
            
            # Calculer la complexitÃ©
            $Conditionals = ([regex]::Matches($Content, "if\s+")).Count + ([regex]::Matches($Content, "elif\s+")).Count + ([regex]::Matches($Content, "case\s+")).Count
            $Loops = ([regex]::Matches($Content, "for\s+")).Count + ([regex]::Matches($Content, "while\s+")).Count + ([regex]::Matches($Content, "until\s+")).Count
            $Metrics.ComplexityScore = $Metrics.FunctionCount + $Conditionals + $Loops
            
            # VÃ©rifier les problÃ¨mes courants
            if ($Metrics.CommentRatio -lt 0.1) {
                $Quality.Issues += "Ratio de commentaires faible ($([math]::Round($Metrics.CommentRatio * 100, 1))%)"
                $Quality.Recommendations += "Ajouter plus de commentaires pour expliquer le code"
            }
            
            # VÃ©rifier l'utilisation de chemins absolus
            $AbsolutePaths = [regex]::Matches($Content, "^/")
            if ($AbsolutePaths.Count -gt 0) {
                $Quality.Issues += "Utilisation de chemins absolus"
                $Quality.Recommendations += "Utiliser des chemins relatifs ou des variables d'environnement"
            }
        }
    }
    
    # Calculer le score de qualitÃ© (formule simple)
    $BaseScore = 100
    
    # PÃ©nalitÃ©s pour les problÃ¨mes
    $Penalties = @{
        LongLines = if ($Metrics.MaxLineLength -gt 120) { 10 } else { 0 }
        LowCommentRatio = if ($Metrics.CommentRatio -lt 0.1) { 15 } else { 0 }
        HighComplexity = [math]::Min(30, $Metrics.ComplexityScore / 2)
        Issues = $Quality.Issues.Count * 5
    }
    
    # Bonus pour les bonnes pratiques
    $Bonuses = @{
        GoodCommentRatio = if ($Metrics.CommentRatio -gt 0.2) { 10 } else { 0 }
        ModularCode = if ($Metrics.FunctionCount -gt 3) { 10 } else { 0 }
    }
    
    # Calculer le score final
    $TotalPenalties = ($Penalties.Values | Measure-Object -Sum).Sum
    $TotalBonuses = ($Bonuses.Values | Measure-Object -Sum).Sum
    $Quality.Score = [math]::Max(0, [math]::Min(100, $BaseScore - $TotalPenalties + $TotalBonuses))
    
    # Ajouter les mÃ©triques Ã  l'objet de qualitÃ©
    $Quality.Metrics = $Metrics
    
    return $Quality
}

# Exporter les fonctions
Export-ModuleMember -Function Measure-CodeQuality
