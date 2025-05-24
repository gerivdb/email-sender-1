#Requires -Version 5.1
<#
.SYNOPSIS
    Module dÃ©finissant un format unifiÃ© pour les rÃ©sultats d'analyse de diffÃ©rents outils.

.DESCRIPTION
    Ce module fournit des fonctions pour convertir les rÃ©sultats d'analyse de diffÃ©rents outils
    (PSScriptAnalyzer, ESLint, Pylint, SonarQube, etc.) vers un format unifiÃ©, permettant
    ainsi de les comparer, fusionner et traiter de maniÃ¨re cohÃ©rente.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

# Format unifiÃ© pour les rÃ©sultats d'analyse
# Chaque rÃ©sultat d'analyse est reprÃ©sentÃ© par un objet PSCustomObject avec les propriÃ©tÃ©s suivantes:
# - ToolName: Nom de l'outil d'analyse (PSScriptAnalyzer, ESLint, Pylint, etc.)
# - FilePath: Chemin complet du fichier analysÃ©
# - FileName: Nom du fichier analysÃ©
# - Line: NumÃ©ro de ligne oÃ¹ le problÃ¨me a Ã©tÃ© dÃ©tectÃ©
# - Column: NumÃ©ro de colonne oÃ¹ le problÃ¨me a Ã©tÃ© dÃ©tectÃ©
# - RuleId: Identifiant de la rÃ¨gle qui a dÃ©tectÃ© le problÃ¨me
# - Severity: SÃ©vÃ©ritÃ© du problÃ¨me (Error, Warning, Information)
# - Message: Description du problÃ¨me
# - Category: CatÃ©gorie du problÃ¨me (Style, Performance, Security, etc.)
# - Suggestion: Suggestion de correction (si disponible)
# - OriginalObject: Objet original retournÃ© par l'outil d'analyse

# Fonction pour crÃ©er un nouvel objet de rÃ©sultat d'analyse unifiÃ©
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

# Fonction pour convertir les rÃ©sultats de PSScriptAnalyzer vers le format unifiÃ©
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
            # Mapper la sÃ©vÃ©ritÃ© de PSScriptAnalyzer vers notre format unifiÃ©
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

# Fonction pour convertir les rÃ©sultats d'ESLint vers le format unifiÃ©
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
            # Mapper la sÃ©vÃ©ritÃ© d'ESLint vers notre format unifiÃ©
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

# Fonction pour convertir les rÃ©sultats de Pylint vers le format unifiÃ©
function ConvertFrom-PylintResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results
    )
    
    $unifiedResults = @()
    
    foreach ($result in $Results) {
        # Extraire les informations du rÃ©sultat Pylint
        # Format typique: "file.py:line:column: [C0111] Missing docstring (missing-docstring)"
        if ($result -match '(.*?):(\d+):(\d+): \[(.*?)\] (.*?) \((.*?)\)') {
            $filePath = $Matches[1]
            $line = [int]$Matches[2]
            $column = [int]$Matches[3]
            $ruleId = $Matches[4]
            $message = $Matches[5]
            $category = $Matches[6]
            
            # Mapper la sÃ©vÃ©ritÃ© de Pylint vers notre format unifiÃ©
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

# Fonction pour convertir les rÃ©sultats de SonarQube vers le format unifiÃ©
function ConvertFrom-SonarQubeResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Results
    )
    
    $unifiedResults = @()
    
    foreach ($issue in $Results.issues) {
        # Mapper la sÃ©vÃ©ritÃ© de SonarQube vers notre format unifiÃ©
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

# Fonction pour fusionner les rÃ©sultats d'analyse de diffÃ©rentes sources
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
        # Supprimer les doublons si demandÃ©
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

# Fonction pour filtrer les rÃ©sultats d'analyse par sÃ©vÃ©ritÃ©
function Select-AnalysisResultsBySeverity {
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

# Fonction pour filtrer les rÃ©sultats d'analyse par outil
function Select-AnalysisResultsByTool {
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

# Fonction pour filtrer les rÃ©sultats d'analyse par catÃ©gorie
function Select-AnalysisResultsByCategory {
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
Export-ModuleMember -function Select-AnalysisResultsBySeverity
Export-ModuleMember -function Select-AnalysisResultsByTool
Export-ModuleMember -function Select-AnalysisResultsByCategory

