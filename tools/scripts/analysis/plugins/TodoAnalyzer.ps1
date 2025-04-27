#Requires -Version 5.1
<#
.SYNOPSIS
    Plugin d'analyse pour dÃ©tecter les commentaires TODO, FIXME, etc. dans le code.

.DESCRIPTION
    Ce plugin analyse les fichiers Ã  la recherche de commentaires TODO, FIXME, HACK, etc.
    et les signale comme des problÃ¨mes Ã  rÃ©soudre.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

Import-Module -Name $pluginManagerPath -Force
Import-Module -Name $unifiedResultsFormatPath -Force

# Fonction d'analyse
$analyzeFunction = {
    param (
        [string]$FilePath,
        [string[]]$Keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG"),
        [ValidateSet("Error", "Warning", "Information")]
        [string]$Severity = "Information"
    )

    # VÃ©rifier si le fichier existe
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

        # VÃ©rifier si la ligne contient un commentaire TODO
        foreach ($keyword in $Keywords) {
            if ($line -match "(?i)(?:#|\/\/|\/\*|\*|--|<!--)\s*($keyword)(?:\s*:)?\s*(.*)") {
                $todoKeyword = $matches[1]
                $todoComment = $matches[2]

                $result = New-UnifiedAnalysisResult -ToolName "TodoAnalyzer" `
                    -FilePath $FilePath `
                    -Line $lineNumber `
                    -Column $line.IndexOf($todoKeyword) + 1 `
                    -RuleId "Todo.$todoKeyword" `
                    -Severity $Severity `
                    -Message "${todoKeyword}: $todoComment" `
                    -Category "Documentation" `
                    -Suggestion "RÃ©solvez ce $todoKeyword ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes."

                $results += $result
            }
        }
    }

    return $results
}

# Enregistrer le plugin
Register-AnalysisPlugin -Name "TodoAnalyzer" `
    -Description "Analyse les commentaires TODO, FIXME, etc. dans le code" `
    -Version "1.0" `
    -Author "EMAIL_SENDER_1" `
    -Language "Generic" `
    -AnalyzeFunction $analyzeFunction `
    -Configuration @{
    Keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG")
    Severity = "Information"
} `
    -Force
