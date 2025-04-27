# Script pour tester manuellement l'extension Error Pattern Analyzer

# Importer le module d'analyse des patterns d'erreurs
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "extensions\error-pattern-analyzer\scripts\ErrorPatternAnalyzer.psm1"
Import-Module $modulePath -Force

# Analyser le fichier de test
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "test_extension.ps1"
$results = Analyze-ErrorPatterns -FilePath $filePath

# Afficher les rÃ©sultats
Write-Host "Patterns d'erreurs dÃ©tectÃ©s : $($results.Count)"
foreach ($result in $results) {
    Write-Host "-----------------------------------"
    Write-Host "ID: $($result.id)"
    Write-Host "Ligne: $($result.lineNumber + 1)"
    Write-Host "Message: $($result.message)"
    Write-Host "SÃ©vÃ©ritÃ©: $($result.severity)"
    Write-Host "Description: $($result.description)"
    Write-Host "Suggestion: $($result.suggestion)"
    Write-Host "Exemple de code: $($result.codeExample)"
}

# Exporter les rÃ©sultats au format JSON pour rÃ©fÃ©rence
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "test_results.json"
$results | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8

Write-Host "-----------------------------------"
Write-Host "RÃ©sultats exportÃ©s vers : $jsonPath"
