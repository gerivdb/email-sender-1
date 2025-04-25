<#
.SYNOPSIS
    Teste l'analyse des pull requests localement.
.DESCRIPTION
    Ce script teste l'analyse des pull requests localement en simulant une pull request
    avec des fichiers PowerShell contenant des erreurs potentielles.
.PARAMETER OutputPath
    Chemin de sortie pour le rapport d'analyse.
.EXAMPLE
    .\Test-PullRequestAnalysis.ps1
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$OutputPath = (Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "git-hooks\reports\test-pr-analysis.md")
)

# Créer un répertoire temporaire
$tempDir = Join-Path -Path $env:TEMP -ChildPath "pr-analysis-test"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer un fichier PowerShell avec des erreurs potentielles
$testFile = Join-Path -Path $tempDir -ChildPath "test-script-with-errors.ps1"
$testContent = @"
# Script de test avec des erreurs potentielles pour tester l'analyse des pull requests

# 1. Référence nulle
`$user = `$null
`$name = `$user.Name  # Erreur potentielle : référence nulle

# 2. Index hors limites
`$array = @(1, 2, 3)
`$value = `$array[5]  # Erreur potentielle : index hors limites

# 3. Conversion de type
`$input = "abc"
`$number = [int]`$input  # Erreur potentielle : conversion de type

# 4. Variable non initialisée
`$result = `$total + 10  # Erreur potentielle : `$total n'est pas initialisé

# 5. Division par zéro
`$divisor = 0
`$quotient = 10 / `$divisor  # Erreur potentielle : division par zéro

# 6. Accès à un membre inexistant
`$obj = New-Object PSObject
`$value = `$obj.MissingProperty  # Erreur potentielle : propriété inexistante

# 7. Appel de fonction avec des paramètres incorrects
function Test-Function {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Name
    )
    Write-Host "Hello, `$Name!"
}

Test-Function  # Erreur potentielle : paramètre obligatoire manquant
"@
$testContent | Out-File -FilePath $testFile -Encoding utf8

# Créer un fichier PowerShell sans erreurs
$testFileOk = Join-Path -Path $tempDir -ChildPath "test-script-without-errors.ps1"
$testContentOk = @"
# Script de test sans erreurs potentielles

# 1. Référence nulle (corrigée)
`$user = `$null
if (`$user -ne `$null) {
    `$name = `$user.Name
} else {
    `$name = "Inconnu"
}

# 2. Index hors limites (corrigé)
`$array = @(1, 2, 3)
if (`$array.Length -gt 5) {
    `$value = `$array[5]
} else {
    `$value = `$array[`$array.Length - 1]
}

# 3. Conversion de type (corrigée)
`$userInput = "123"
if (`$userInput -as [int]) {
    `$number = [int]`$userInput
} else {
    `$number = 0
}

# 4. Variable non initialisée (corrigée)
`$total = 0
`$result = `$total + 10

# 5. Division par zéro (corrigée)
`$divisor = 0
if (`$divisor -ne 0) {
    `$quotient = 10 / `$divisor
} else {
    `$quotient = 0
}

# 6. Accès à un membre inexistant (corrigé)
`$obj = New-Object PSObject -Property @{
    Name = "Test"
}
`$value = `$obj.Name

# 7. Appel de fonction avec des paramètres incorrects (corrigé)
function Test-Function {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Name
    )
    Write-Host "Hello, `$Name!"
}

Test-Function -Name "John"
"@
$testContentOk | Out-File -FilePath $testFileOk -Encoding utf8

# Vérifier si le module ErrorPatternAnalyzer existe
$modulePath = Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
if (Test-Path -Path $modulePath) {
    Write-Host "Module ErrorPatternAnalyzer trouvé: $modulePath" -ForegroundColor Green
    Import-Module $modulePath -Force
} else {
    Write-Warning "Module ErrorPatternAnalyzer non trouvé: $modulePath"
    Write-Warning "L'analyse sera limitée à PSScriptAnalyzer."
}

# Analyser les fichiers avec PSScriptAnalyzer
Write-Host "Analyse des fichiers avec PSScriptAnalyzer..." -ForegroundColor Cyan
$pssaResults = @()

# Analyser le fichier avec erreurs
Write-Host "Analyse de $testFile..." -ForegroundColor Yellow
$fileResults = Invoke-ScriptAnalyzer -Path $testFile -ExcludeRule PSAvoidUsingWriteHost
$pssaResults += $fileResults

# Analyser le fichier sans erreurs
Write-Host "Analyse de $testFileOk..." -ForegroundColor Yellow
$fileResults = Invoke-ScriptAnalyzer -Path $testFileOk -ExcludeRule PSAvoidUsingWriteHost
$pssaResults += $fileResults

# Analyser les fichiers avec ErrorPatternAnalyzer
$epResults = @()
if (Get-Command -Name Get-ErrorPatterns -ErrorAction SilentlyContinue) {
    Write-Host "Analyse des fichiers avec ErrorPatternAnalyzer..." -ForegroundColor Cyan
    
    # Analyser le fichier avec erreurs
    Write-Host "Analyse de $testFile..." -ForegroundColor Yellow
    $patterns = Get-ErrorPatterns -FilePath $testFile
    
    if ($patterns) {
        foreach ($pattern in $patterns) {
            $epResults += [PSCustomObject]@{
                File = $testFile
                Line = $pattern.LineNumber
                Column = $pattern.StartColumn
                Severity = $pattern.Severity
                Message = $pattern.Message
                RuleName = $pattern.Id
                Description = $pattern.Description
                Suggestion = $pattern.Suggestion
                CodeExample = $pattern.CodeExample
                Source = "ErrorPatternAnalyzer"
            }
        }
    }
    
    # Analyser le fichier sans erreurs
    Write-Host "Analyse de $testFileOk..." -ForegroundColor Yellow
    $patterns = Get-ErrorPatterns -FilePath $testFileOk
    
    if ($patterns) {
        foreach ($pattern in $patterns) {
            $epResults += [PSCustomObject]@{
                File = $testFileOk
                Line = $pattern.LineNumber
                Column = $pattern.StartColumn
                Severity = $pattern.Severity
                Message = $pattern.Message
                RuleName = $pattern.Id
                Description = $pattern.Description
                Suggestion = $pattern.Suggestion
                CodeExample = $pattern.CodeExample
                Source = "ErrorPatternAnalyzer"
            }
        }
    }
}

# Combiner les résultats
$allResults = @()

# Ajouter les résultats de PSScriptAnalyzer
foreach ($result in $pssaResults) {
    $allResults += [PSCustomObject]@{
        File = $result.ScriptPath
        Line = $result.Line
        Column = $result.Column
        Severity = $result.Severity
        Message = $result.Message
        RuleName = $result.RuleName
        Source = "PSScriptAnalyzer"
    }
}

# Ajouter les résultats de ErrorPatternAnalyzer
$allResults += $epResults

# Compter les erreurs et avertissements
$errorCount = ($allResults | Where-Object { $_.Severity -eq "Error" }).Count
$warningCount = ($allResults | Where-Object { $_.Severity -eq "Warning" }).Count
$infoCount = ($allResults | Where-Object { $_.Severity -eq "Information" }).Count

# Générer un rapport d'analyse
$report = @"
# Rapport d'analyse de pull request (test)

## Résumé de l'analyse

- **Erreurs**: $errorCount
- **Avertissements**: $warningCount
- **Informations**: $infoCount
- **Total**: $($allResults.Count)

## Détails des problèmes détectés

| Fichier | Ligne | Colonne | Sévérité | Message | Règle | Source |
|---------|-------|---------|----------|---------|-------|--------|
"@

# Ajouter les résultats
foreach ($result in $allResults | Sort-Object -Property File, Line, Column) {
    $severity = switch ($result.Severity) {
        "Error" { ":x: Error" }
        "Warning" { ":warning: Warning" }
        "Information" { ":information_source: Information" }
        default { $result.Severity }
    }
    
    $report += "`n| $($result.File) | $($result.Line) | $($result.Column) | $severity | $($result.Message) | $($result.RuleName) | $($result.Source) |"
}

# Ajouter les suggestions d'amélioration
$suggestions = $epResults | Group-Object -Property RuleName | ForEach-Object { $_.Group[0] }
if ($suggestions) {
    $report += "`n`n## Suggestions d'amélioration`n"
    
    foreach ($suggestion in $suggestions) {
        $report += "`n### $($suggestion.RuleName)`n`n"
        
        if ($suggestion.Description) {
            $report += "**Description**: $($suggestion.Description)`n`n"
        }
        
        if ($suggestion.Suggestion) {
            $report += "**Suggestion**: $($suggestion.Suggestion)`n`n"
        }
        
        if ($suggestion.CodeExample) {
            $report += "**Exemple de code**:`n```powershell`n$($suggestion.CodeExample)`n````n`n"
        }
    }
}

# Écrire le rapport
$reportDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "`nRapport généré: $OutputPath" -ForegroundColor Cyan

# Afficher un résumé
Write-Host "`nRésumé de l'analyse:" -ForegroundColor Cyan
Write-Host "  Erreurs: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Avertissements: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Informations: $infoCount" -ForegroundColor "Cyan"
Write-Host "  Total: $($allResults.Count)" -ForegroundColor "White"

# Nettoyer
Remove-Item -Path $tempDir -Recurse -Force
