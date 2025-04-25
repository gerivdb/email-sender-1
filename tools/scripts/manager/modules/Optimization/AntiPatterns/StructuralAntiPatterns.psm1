# Module de détection des anti-patterns structurels pour le Script Manager
# Ce module détecte les anti-patterns liés à la structure du code
# Author: Script Manager
# Version: 1.0
# Tags: optimization, anti-patterns, structure

function Find-LongMethods {
    <#
    .SYNOPSIS
        Détecte les méthodes trop longues
    .DESCRIPTION
        Analyse le script pour détecter les méthodes trop longues
    .PARAMETER Script
        Objet script à analyser
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-LongMethods -Script $script -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    # Créer un tableau pour stocker les méthodes trop longues
    $LongMethods = @()
    
    # Définir la longueur maximale acceptable pour une méthode
    $MaxMethodLength = 50
    
    # Traiter selon le type de script
    switch ($Script.Type) {
        "PowerShell" {
            # Rechercher les fonctions PowerShell
            $FunctionMatches = [regex]::Matches($Content, "function\s+(\w+[-\w]*)\s*\{([^}]*)\}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($Match in $FunctionMatches) {
                $FunctionName = $Match.Groups[1].Value
                $FunctionBody = $Match.Groups[2].Value
                $FunctionLines = $FunctionBody -split "`n"
                
                if ($FunctionLines.Count -gt $MaxMethodLength) {
                    # Calculer les numéros de ligne
                    $StartLine = ($Content.Substring(0, $Match.Index) -split "`n").Length
                    $EndLine = $StartLine + $FunctionLines.Count
                    $LineNumbers = $StartLine..$EndLine
                    
                    $LongMethods += [PSCustomObject]@{
                        Name = $FunctionName
                        LineNumbers = $LineNumbers
                        CodeSnippet = $Match.Value.Substring(0, [Math]::Min(500, $Match.Value.Length)) + "..."
                    }
                }
            }
        }
        "Python" {
            # Rechercher les fonctions Python
            $FunctionMatches = [regex]::Matches($Content, "def\s+(\w+)\s*\([^)]*\):[^:]*?(?:\n\s+[^\n]+)+", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($Match in $FunctionMatches) {
                $FunctionName = $Match.Groups[1].Value
                $FunctionBody = $Match.Value
                $FunctionLines = $FunctionBody -split "`n"
                
                if ($FunctionLines.Count -gt $MaxMethodLength) {
                    # Calculer les numéros de ligne
                    $StartLine = ($Content.Substring(0, $Match.Index) -split "`n").Length
                    $EndLine = $StartLine + $FunctionLines.Count
                    $LineNumbers = $StartLine..$EndLine
                    
                    $LongMethods += [PSCustomObject]@{
                        Name = $FunctionName
                        LineNumbers = $LineNumbers
                        CodeSnippet = $Match.Value.Substring(0, [Math]::Min(500, $Match.Value.Length)) + "..."
                    }
                }
            }
        }
        "Batch" {
            # Rechercher les labels Batch
            $LabelMatches = [regex]::Matches($Content, ":([\w-]+)([^:]*?)(?=:\w+|\z)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($Match in $LabelMatches) {
                $LabelName = $Match.Groups[1].Value
                $LabelBody = $Match.Groups[2].Value
                $LabelLines = $LabelBody -split "`n"
                
                if ($LabelLines.Count -gt $MaxMethodLength) {
                    # Calculer les numéros de ligne
                    $StartLine = ($Content.Substring(0, $Match.Index) -split "`n").Length
                    $EndLine = $StartLine + $LabelLines.Count
                    $LineNumbers = $StartLine..$EndLine
                    
                    $LongMethods += [PSCustomObject]@{
                        Name = $LabelName
                        LineNumbers = $LineNumbers
                        CodeSnippet = $Match.Value.Substring(0, [Math]::Min(500, $Match.Value.Length)) + "..."
                    }
                }
            }
        }
        "Shell" {
            # Rechercher les fonctions Shell
            $FunctionMatches = [regex]::Matches($Content, "(\w+)\s*\(\)\s*\{([^}]*)\}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($Match in $FunctionMatches) {
                $FunctionName = $Match.Groups[1].Value
                $FunctionBody = $Match.Groups[2].Value
                $FunctionLines = $FunctionBody -split "`n"
                
                if ($FunctionLines.Count -gt $MaxMethodLength) {
                    # Calculer les numéros de ligne
                    $StartLine = ($Content.Substring(0, $Match.Index) -split "`n").Length
                    $EndLine = $StartLine + $FunctionLines.Count
                    $LineNumbers = $StartLine..$EndLine
                    
                    $LongMethods += [PSCustomObject]@{
                        Name = $FunctionName
                        LineNumbers = $LineNumbers
                        CodeSnippet = $Match.Value.Substring(0, [Math]::Min(500, $Match.Value.Length)) + "..."
                    }
                }
            }
        }
    }
    
    return $LongMethods
}

function Find-DeepNestings {
    <#
    .SYNOPSIS
        Détecte les imbrications profondes
    .DESCRIPTION
        Analyse le contenu pour détecter les imbrications profondes
    .PARAMETER Content
        Contenu du script
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Find-DeepNestings -Content $content -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un tableau pour stocker les imbrications profondes
    $DeepNestings = @()
    
    # Définir la profondeur maximale acceptable
    $MaxNestingDepth = 3
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Définir les motifs d'imbrication selon le type de script
    $NestingPatterns = switch ($ScriptType) {
        "PowerShell" { @("if\s*\(", "foreach\s*\(", "while\s*\(", "switch\s*\(", "do\s*\{") }
        "Python" { @("if\s+", "for\s+", "while\s+", "def\s+", "with\s+", "try\s*:") }
        "Batch" { @("if\s+", "for\s+", "goto\s+") }
        "Shell" { @("if\s+", "for\s+", "while\s+", "case\s+", "until\s+") }
        default { @("if", "for", "while") }
    }
    
    # Parcourir les lignes
    $CurrentNestingDepth = 0
    $MaxDepthFound = 0
    $NestingStart = 0
    $NestingLines = @()
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Vérifier si la ligne contient un motif d'imbrication
        $ContainsNestingPattern = $false
        foreach ($Pattern in $NestingPatterns) {
            if ($Line -match $Pattern) {
                $ContainsNestingPattern = $true
                break
            }
        }
        
        # Mettre à jour la profondeur d'imbrication
        if ($ContainsNestingPattern) {
            $CurrentNestingDepth++
            
            if ($CurrentNestingDepth -gt $MaxDepthFound) {
                $MaxDepthFound = $CurrentNestingDepth
                $NestingStart = $LineNumber
                $NestingLines = @($LineNumber)
            } elseif ($CurrentNestingDepth -eq $MaxDepthFound) {
                $NestingLines += $LineNumber
            }
        }
        
        # Vérifier si la ligne contient une fermeture d'imbrication
        if ($Line -match "(\}|\)|\bend\b|\bfi\b|\bdone\b)") {
            $CurrentNestingDepth = [Math]::Max(0, $CurrentNestingDepth - 1)
        }
    }
    
    # Ajouter l'imbrication profonde si elle dépasse la profondeur maximale
    if ($MaxDepthFound -gt $MaxNestingDepth) {
        # Extraire un extrait du code
        $StartLine = [Math]::Max(0, $NestingStart - 2)
        $EndLine = [Math]::Min($Lines.Count - 1, $NestingStart + 5)
        $CodeSnippet = $Lines[$StartLine..$EndLine] -join "`n"
        
        $DeepNestings += [PSCustomObject]@{
            Depth = $MaxDepthFound
            LineNumbers = $NestingLines
            CodeSnippet = $CodeSnippet
        }
    }
    
    return $DeepNestings
}

function Find-HardcodedPaths {
    <#
    .SYNOPSIS
        Détecte les chemins codés en dur
    .DESCRIPTION
        Analyse le contenu pour détecter les chemins codés en dur
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-HardcodedPaths -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    # Créer un tableau pour stocker les chemins codés en dur
    $HardcodedPaths = @()
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Définir les motifs de chemins
    $PathPatterns = @(
        # Chemins Windows
        "[A-Z]:\\(?:[^:*?`"<>|\r\n]+\\)*[^:*?`"<>|\r\n]*",
        # Chemins Unix
        "/(?:home|usr|var|etc|opt)/[^:*?`"<>|\r\n]+"
    )
    
    # Parcourir les lignes
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Ignorer les lignes de commentaires
        if ($Line -match "^\s*(#|//|REM|::)") {
            continue
        }
        
        # Rechercher les chemins
        foreach ($Pattern in $PathPatterns) {
            $PathMatches = [regex]::Matches($Line, $Pattern)
            
            foreach ($Match in $PathMatches) {
                $Path = $Match.Value
                
                # Ignorer les chemins courts ou variables
                if ($Path.Length -lt 5 -or $Path -match "\$\w+") {
                    continue
                }
                
                # Ajouter le chemin codé en dur
                $HardcodedPaths += [PSCustomObject]@{
                    Value = $Path
                    LineNumber = $LineNumber
                    CodeSnippet = $Line
                }
            }
        }
    }
    
    return $HardcodedPaths
}

# Exporter les fonctions
Export-ModuleMember -Function Find-LongMethods, Find-DeepNestings, Find-HardcodedPaths
