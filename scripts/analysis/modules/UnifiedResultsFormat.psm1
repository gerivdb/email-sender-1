#Requires -Version 5.1
<#
.SYNOPSIS
    Module définissant un format unifié pour les résultats d'analyse de différents outils.

.DESCRIPTION
    Ce module fournit des fonctions pour convertir les résultats d'analyse de différents outils
    (PSScriptAnalyzer, ESLint, Pylint, SonarQube, etc.) vers un format unifié, permettant
    ainsi de les comparer, fusionner et traiter de manière cohérente.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

# Format unifié pour les résultats d'analyse
# Chaque résultat d'analyse est représenté par un objet PSCustomObject avec les propriétés suivantes:
# - ToolName: Nom de l'outil d'analyse (PSScriptAnalyzer, ESLint, Pylint, etc.)
# - FilePath: Chemin complet du fichier analysé
# - FileName: Nom du fichier analysé
# - Line: Numéro de ligne où le problème a été détecté
# - Column: Numéro de colonne où le problème a été détecté
# - RuleId: Identifiant de la règle qui a détecté le problème
# - Severity: Sévérité du problème (Error, Warning, Information)
# - Message: Description du problème
# - Category: Catégorie du problème (Style, Performance, Security, etc.)
# - Suggestion: Suggestion de correction (si disponible)
# - OriginalObject: Objet original retourné par l'outil d'analyse

# Fonction pour créer un nouvel objet de résultat d'analyse unifié
function New-UnifiedAnalysisResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$FileName = (Split-Path -Path $FilePath -Leaf),
        
        [Parameter(Mandatory = $false)]
        [int]$Line = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$Column = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$RuleId = "",
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Error", "Warning", "Information")]
        [string]$Severity,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$Suggestion = "",
        
        [Parameter(Mandatory = $false)]
        [object]$OriginalObject = $null
    )
    
    return [PSCustomObject]@{
        ToolName = $ToolName
        FilePath = $FilePath
        FileName = $FileName
        Line = $Line
        Column = $Column
        RuleId = $RuleId
        Severity = $Severity
        Message = $Message
        Category = $Category
        Suggestion = $Suggestion
        OriginalObject = $OriginalObject
    }
}

# Fonction pour convertir les résultats de PSScriptAnalyzer vers le format unifié
function ConvertFrom-PSScriptAnalyzerResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Results
    )
    
    begin {
        $unifiedResults = @()
    }
    
    process {
        foreach ($result in $Results) {
            # Mapper la sévérité de PSScriptAnalyzer vers notre format unifié
            $severity = switch ($result.Severity) {
                "Error" { "Error" }
                "Warning" { "Warning" }
                "Information" { "Information" }
                default { "Information" }
            }
            
            $unifiedResult = New-UnifiedAnalysisResult -ToolName "PSScriptAnalyzer" `
                -FilePath $result.ScriptPath `
                -Line $result.Line `
                -Column $result.Column `
                -RuleId $result.RuleName `
                -Severity $severity `
                -Message $result.Message `
                -Category $result.RuleSuppressionID `
                -Suggestion $result.SuggestedCorrections `
                -OriginalObject $result
            
            $unifiedResults += $unifiedResult
        }
    }
    
    end {
        return $unifiedResults
    }
}

# Fonction pour convertir les résultats d'ESLint vers le format unifié
function ConvertFrom-ESLintResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Results
    )
    
    $unifiedResults = @()
    
    foreach ($file in $Results) {
        $filePath = $file.filePath
        
        foreach ($message in $file.messages) {
            # Mapper la sévérité d'ESLint vers notre format unifié
            $severity = switch ($message.severity) {
                2 { "Error" }
                1 { "Warning" }
                default { "Information" }
            }
            
            $unifiedResult = New-UnifiedAnalysisResult -ToolName "ESLint" `
                -FilePath $filePath `
                -Line $message.line `
                -Column $message.column `
                -RuleId $message.ruleId `
                -Severity $severity `
                -Message $message.message `
                -Category $message.ruleId.Split('/')[0] `
                -OriginalObject $message
            
            $unifiedResults += $unifiedResult
        }
    }
    
    return $unifiedResults
}

# Fonction pour convertir les résultats de Pylint vers le format unifié
function ConvertFrom-PylintResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results
    )
    
    $unifiedResults = @()
    
    foreach ($result in $Results) {
        # Extraire les informations du résultat Pylint
        # Format typique: "file.py:line:column: [C0111] Missing docstring (missing-docstring)"
        if ($result -match '(.*?):(\d+):(\d+): \[(.*?)\] (.*?) \((.*?)\)') {
            $filePath = $Matches[1]
            $line = [int]$Matches[2]
            $column = [int]$Matches[3]
            $ruleId = $Matches[4]
            $message = $Matches[5]
            $category = $Matches[6]
            
            # Mapper la sévérité de Pylint vers notre format unifié
            $severity = switch ($ruleId[0]) {
                "E" { "Error" }
                "F" { "Error" }
                "W" { "Warning" }
                "C" { "Information" }
                "R" { "Information" }
                default { "Information" }
            }
            
            $unifiedResult = New-UnifiedAnalysisResult -ToolName "Pylint" `
                -FilePath $filePath `
                -Line $line `
                -Column $column `
                -RuleId $ruleId `
                -Severity $severity `
                -Message $message `
                -Category $category `
                -OriginalObject $result
            
            $unifiedResults += $unifiedResult
        }
    }
    
    return $unifiedResults
}

# Fonction pour convertir les résultats de SonarQube vers le format unifié
function ConvertFrom-SonarQubeResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Results
    )
    
    $unifiedResults = @()
    
    foreach ($issue in $Results.issues) {
        # Mapper la sévérité de SonarQube vers notre format unifié
        $severity = switch ($issue.severity) {
            "BLOCKER" { "Error" }
            "CRITICAL" { "Error" }
            "MAJOR" { "Warning" }
            "MINOR" { "Information" }
            "INFO" { "Information" }
            default { "Information" }
        }
        
        $unifiedResult = New-UnifiedAnalysisResult -ToolName "SonarQube" `
            -FilePath $issue.component `
            -Line $issue.line `
            -RuleId $issue.rule `
            -Severity $severity `
            -Message $issue.message `
            -Category $issue.type `
            -OriginalObject $issue
        
        $unifiedResults += $unifiedResult
    }
    
    return $unifiedResults
}

# Fonction pour fusionner les résultats d'analyse de différentes sources
function Merge-AnalysisResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveDuplicates
    )
    
    begin {
        $mergedResults = @()
    }
    
    process {
        foreach ($result in $Results) {
            $mergedResults += $result
        }
    }
    
    end {
        # Supprimer les doublons si demandé
        if ($RemoveDuplicates) {
            $uniqueResults = @()
            $seen = @{}
            
            foreach ($result in $mergedResults) {
                $key = "$($result.FilePath)|$($result.Line)|$($result.Message)"
                
                if (-not $seen.ContainsKey($key)) {
                    $seen[$key] = $true
                    $uniqueResults += $result
                }
            }
            
            return $uniqueResults
        }
        else {
            return $mergedResults
        }
    }
}

# Fonction pour filtrer les résultats d'analyse par sévérité
function Filter-AnalysisResultsBySeverity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Information", "All")]
        [string[]]$Severity = @("Error", "Warning", "Information")
    )
    
    begin {
        $filteredResults = @()
    }
    
    process {
        foreach ($result in $Results) {
            if ($Severity -contains "All" -or $Severity -contains $result.Severity) {
                $filteredResults += $result
            }
        }
    }
    
    end {
        return $filteredResults
    }
}

# Fonction pour filtrer les résultats d'analyse par outil
function Filter-AnalysisResultsByTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [string[]]$ToolName
    )
    
    begin {
        $filteredResults = @()
    }
    
    process {
        foreach ($result in $Results) {
            if ($ToolName -contains $result.ToolName) {
                $filteredResults += $result
            }
        }
    }
    
    end {
        return $filteredResults
    }
}

# Fonction pour filtrer les résultats d'analyse par catégorie
function Filter-AnalysisResultsByCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Category
    )
    
    begin {
        $filteredResults = @()
    }
    
    process {
        foreach ($result in $Results) {
            if ($Category -contains $result.Category) {
                $filteredResults += $result
            }
        }
    }
    
    end {
        return $filteredResults
    }
}

# Exporter les fonctions du module
Export-ModuleMember -Function New-UnifiedAnalysisResult
Export-ModuleMember -Function ConvertFrom-PSScriptAnalyzerResult
Export-ModuleMember -Function ConvertFrom-ESLintResult
Export-ModuleMember -Function ConvertFrom-PylintResult
Export-ModuleMember -Function ConvertFrom-SonarQubeResult
Export-ModuleMember -Function Merge-AnalysisResults
Export-ModuleMember -Function Filter-AnalysisResultsBySeverity
Export-ModuleMember -Function Filter-AnalysisResultsByTool
Export-ModuleMember -Function Filter-AnalysisResultsByCategory
