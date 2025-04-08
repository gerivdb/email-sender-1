# Module d'analyse statique pour le Script Manager
# Ce module effectue une analyse statique du code des scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, static, code

function Invoke-StaticAnalysis {
    <#
    .SYNOPSIS
        Effectue une analyse statique du code
    .DESCRIPTION
        Analyse le code pour extraire des informations sur sa structure et son contenu
    .PARAMETER Content
        Contenu du script à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .PARAMETER Depth
        Niveau de profondeur de l'analyse (Basic, Standard, Advanced)
    .EXAMPLE
        Invoke-StaticAnalysis -Content $scriptContent -ScriptType "PowerShell" -Depth "Standard"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("PowerShell", "Python", "Batch", "Shell", "Unknown")]
        [string]$ScriptType,
        
        [ValidateSet("Basic", "Standard", "Advanced")]
        [string]$Depth = "Standard"
    )
    
    # Initialiser l'objet d'analyse
    $Analysis = @{
        LineCount = 0
        CommentCount = 0
        FunctionCount = 0
        VariableCount = 0
        ComplexityScore = 0
        Imports = @()
        Functions = @()
        Variables = @()
        Classes = @()
        Conditionals = 0
        Loops = 0
    }
    
    # Compter les lignes (non vides)
    $Lines = $Content -split "`n" | Where-Object { $_.Trim() -ne "" }
    $Analysis.LineCount = $Lines.Count
    
    # Analyse spécifique au type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Compter les commentaires
            $Analysis.CommentCount = ($Content -split "`n" | Where-Object { $_.Trim() -match "^#" }).Count
            
            # Compter les fonctions
            $FunctionMatches = [regex]::Matches($Content, "function\s+([a-zA-Z0-9_-]+)")
            $Analysis.FunctionCount = $FunctionMatches.Count
            $Analysis.Functions = $FunctionMatches | ForEach-Object { $_.Groups[1].Value }
            
            # Compter les variables (déclarations)
            $VariableMatches = [regex]::Matches($Content, "\$([a-zA-Z0-9_-]+)\s*=")
            $Analysis.VariableCount = $VariableMatches.Count
            $Analysis.Variables = $VariableMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            
            # Compter les imports
            $ImportMatches = [regex]::Matches($Content, "Import-Module\s+([a-zA-Z0-9_\.-]+)")
            $Analysis.Imports = $ImportMatches | ForEach-Object { $_.Groups[1].Value }
            
            # Compter les conditionnels
            $Analysis.Conditionals = ([regex]::Matches($Content, "if\s*\(")).Count + ([regex]::Matches($Content, "elseif\s*\(")).Count + ([regex]::Matches($Content, "switch\s*\(")).Count
            
            # Compter les boucles
            $Analysis.Loops = ([regex]::Matches($Content, "foreach\s*\(")).Count + ([regex]::Matches($Content, "for\s*\(")).Count + ([regex]::Matches($Content, "while\s*\(")).Count + ([regex]::Matches($Content, "do\s*\{")).Count
            
            # Calculer la complexité (formule simple)
            $Analysis.ComplexityScore = $Analysis.FunctionCount + $Analysis.Conditionals + $Analysis.Loops
            
            # Analyse avancée si demandée
            if ($Depth -eq "Advanced") {
                # Détecter les classes
                $ClassMatches = [regex]::Matches($Content, "class\s+([a-zA-Z0-9_-]+)")
                $Analysis.Classes = $ClassMatches | ForEach-Object { $_.Groups[1].Value }
                
                # Analyse plus approfondie des fonctions (paramètres, etc.)
                # Cette partie pourrait être développée davantage
            }
        }
        "Python" {
            # Compter les commentaires
            $Analysis.CommentCount = ($Content -split "`n" | Where-Object { $_.Trim() -match "^#" }).Count
            
            # Compter les fonctions
            $FunctionMatches = [regex]::Matches($Content, "def\s+([a-zA-Z0-9_]+)")
            $Analysis.FunctionCount = $FunctionMatches.Count
            $Analysis.Functions = $FunctionMatches | ForEach-Object { $_.Groups[1].Value }
            
            # Compter les imports
            $ImportMatches = [regex]::Matches($Content, "import\s+([a-zA-Z0-9_\.]+)|from\s+([a-zA-Z0-9_\.]+)\s+import")
            $Analysis.Imports = $ImportMatches | ForEach-Object { 
                if ($_.Groups[1].Value) { $_.Groups[1].Value } else { $_.Groups[2].Value }
            }
            
            # Compter les conditionnels
            $Analysis.Conditionals = ([regex]::Matches($Content, "if\s+")).Count + ([regex]::Matches($Content, "elif\s+")).Count
            
            # Compter les boucles
            $Analysis.Loops = ([regex]::Matches($Content, "for\s+")).Count + ([regex]::Matches($Content, "while\s+")).Count
            
            # Calculer la complexité (formule simple)
            $Analysis.ComplexityScore = $Analysis.FunctionCount + $Analysis.Conditionals + $Analysis.Loops
            
            # Analyse avancée si demandée
            if ($Depth -eq "Advanced") {
                # Détecter les classes
                $ClassMatches = [regex]::Matches($Content, "class\s+([a-zA-Z0-9_]+)")
                $Analysis.Classes = $ClassMatches | ForEach-Object { $_.Groups[1].Value }
            }
        }
        "Batch" {
            # Compter les commentaires
            $Analysis.CommentCount = ($Content -split "`n" | Where-Object { $_.Trim() -match "^(rem|::)" }).Count
            
            # Compter les labels (comme des fonctions)
            $LabelMatches = [regex]::Matches($Content, "^:([a-zA-Z0-9_-]+)")
            $Analysis.FunctionCount = $LabelMatches.Count
            $Analysis.Functions = $LabelMatches | ForEach-Object { $_.Groups[1].Value }
            
            # Compter les variables (déclarations)
            $VariableMatches = [regex]::Matches($Content, "set\s+([a-zA-Z0-9_-]+)=")
            $Analysis.VariableCount = $VariableMatches.Count
            $Analysis.Variables = $VariableMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            
            # Compter les conditionnels
            $Analysis.Conditionals = ([regex]::Matches($Content, "if\s+")).Count
            
            # Compter les boucles
            $Analysis.Loops = ([regex]::Matches($Content, "for\s+")).Count
            
            # Calculer la complexité (formule simple)
            $Analysis.ComplexityScore = $Analysis.FunctionCount + $Analysis.Conditionals + $Analysis.Loops
        }
        "Shell" {
            # Compter les commentaires
            $Analysis.CommentCount = ($Content -split "`n" | Where-Object { $_.Trim() -match "^#" }).Count
            
            # Compter les fonctions
            $FunctionMatches = [regex]::Matches($Content, "function\s+([a-zA-Z0-9_-]+)|([a-zA-Z0-9_-]+)\(\)")
            $Analysis.FunctionCount = $FunctionMatches.Count
            $Analysis.Functions = $FunctionMatches | ForEach-Object { 
                if ($_.Groups[1].Value) { $_.Groups[1].Value } else { $_.Groups[2].Value }
            }
            
            # Compter les variables (déclarations)
            $VariableMatches = [regex]::Matches($Content, "([a-zA-Z0-9_-]+)=")
            $Analysis.VariableCount = $VariableMatches.Count
            $Analysis.Variables = $VariableMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            
            # Compter les imports
            $ImportMatches = [regex]::Matches($Content, "source\s+([a-zA-Z0-9_\.-]+)|.\s+([a-zA-Z0-9_\.-]+)")
            $Analysis.Imports = $ImportMatches | ForEach-Object { 
                if ($_.Groups[1].Value) { $_.Groups[1].Value } else { $_.Groups[2].Value }
            }
            
            # Compter les conditionnels
            $Analysis.Conditionals = ([regex]::Matches($Content, "if\s+")).Count + ([regex]::Matches($Content, "elif\s+")).Count + ([regex]::Matches($Content, "case\s+")).Count
            
            # Compter les boucles
            $Analysis.Loops = ([regex]::Matches($Content, "for\s+")).Count + ([regex]::Matches($Content, "while\s+")).Count + ([regex]::Matches($Content, "until\s+")).Count
            
            # Calculer la complexité (formule simple)
            $Analysis.ComplexityScore = $Analysis.FunctionCount + $Analysis.Conditionals + $Analysis.Loops
        }
        default {
            # Analyse basique pour les types inconnus
            $Analysis.CommentCount = ($Content -split "`n" | Where-Object { $_.Trim() -match "^(#|//|/\*|\*|rem|::)" }).Count
        }
    }
    
    return $Analysis
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-StaticAnalysis
