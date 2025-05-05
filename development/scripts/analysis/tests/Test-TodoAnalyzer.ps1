#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le plugin TodoAnalyzer.

.DESCRIPTION
    Ce script teste le plugin TodoAnalyzer en l'utilisant directement pour analyser un fichier de test.

.PARAMETER FilePath
    Chemin du fichier ÃƒÂ  analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃƒÂ©sultats.

.EXAMPLE
    .\Test-TodoAnalyzer.ps1 -FilePath ".\development\scripts\analysis\tests\test_script.ps1" -OutputPath ".\development\scripts\analysis\tests\results\todo-results.json"

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = ".\development\scripts\analysis\tests\test_script.ps1",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\development\scripts\analysis\tests\results\todo-results.json"
)

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

Import-Module -Name $unifiedResultsFormatPath -Force

# Fonction d'analyse pour les commentaires TODO
function Find-TodoComments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG"),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Information")]
        [string]$Severity = "Information"
    )
    
    # VÃƒÂ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath
    $results = @()
    
    # Analyser chaque ligne
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        $lineNumber = $i + 1
        
        # VÃƒÂ©rifier si la ligne contient un commentaire TODO
        foreach ($keyword in $Keywords) {
            if ($line -match "(?i)(?:#|\/\/|\/\*|\*|--|<!--)\s*($keyword)(?:\s*:)?\s*(.*)") {
                $todoKeyword = $matches[1]
                $todoComment = $matches[2]
                
                $result = New-UnifiedAnalysisResult -ToolName "TodoAnalyzer" `
                                                   -FilePath $FilePath `
                                                   -Line $lineNumber `
                                                   -Column $line.IndexOf($todoKeyword) + 1 `
                                                   -RuleId "Todo.${todoKeyword}" `
                                                   -Severity $Severity `
                                                   -Message "${todoKeyword}: $todoComment" `
                                                   -Category "Documentation" `
                                                   -Suggestion "RÃƒÂ©solvez ce $todoKeyword ou convertissez-le en tÃƒÂ¢che dans le systÃƒÂ¨me de suivi des problÃƒÂ¨mes."
                
                $results += $result
            }
        }
    }
    
    return $results
}

# CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
$outputDirectory = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
    try {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃƒÂ©pertoire de sortie '$outputDirectory' crÃƒÂ©ÃƒÂ©."
    }
    catch {
        Write-Error "Impossible de crÃƒÂ©er le rÃƒÂ©pertoire de sortie '$outputDirectory': $_"
        return
    }
}

# Analyser le fichier
$results = Find-TodoComments -FilePath $FilePath -Severity "Information"

# Afficher les rÃƒÂ©sultats
if ($null -ne $results) {
    $totalIssues = $results.Count
    
    Write-Host "Analyse terminÃƒÂ©e avec $totalIssues commentaires TODO dÃƒÂ©tectÃƒÂ©s:" -ForegroundColor Cyan
    
    # Afficher les rÃƒÂ©sultats dÃƒÂ©taillÃƒÂ©s
    if ($totalIssues -gt 0) {
        $results | ForEach-Object {
            Write-Host ""
            Write-Host "$($_.FileName) - Ligne $($_.Line), Colonne $($_.Column)" -ForegroundColor Cyan
            Write-Host "$($_.Message)" -ForegroundColor "Blue"
            Write-Host "Suggestion: $($_.Suggestion)" -ForegroundColor "Green"
        }
        
        # Enregistrer les rÃƒÂ©sultats dans un fichier
        try {
            $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
            Write-Host "RÃƒÂ©sultats enregistrÃƒÂ©s dans '$OutputPath'." -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors de l'enregistrement des rÃƒÂ©sultats: $_"
        }
    }
    else {
        Write-Host "Aucun commentaire TODO dÃƒÂ©tectÃƒÂ©." -ForegroundColor Yellow
    }
}
else {
    Write-Error "Erreur lors de l'analyse du fichier."
}
