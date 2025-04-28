# Script pour corriger automatiquement les problÃ¨mes dans les scripts de la roadmap
# Ce script utilise Fix-PSScriptAnalyzerIssues.ps1 pour corriger les problÃ¨mes courants

# Configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixerScriptPath = Join-Path -Path $scriptPath -ChildPath "Fix-PSScriptAnalyzerIssues.ps1"

# VÃ©rifier si le script de correction existe
if (-not (Test-Path -Path $fixerScriptPath)) {
    Write-Host "Le script Fix-PSScriptAnalyzerIssues.ps1 n'existe pas: $fixerScriptPath" -ForegroundColor Red
    exit 1
}

# ExÃ©cuter le script de correction sur tous les scripts de la roadmap
Write-Host "Correction des problÃ¨mes dans les scripts de la roadmap..." -ForegroundColor Cyan
& $fixerScriptPath -Path $scriptPath -Include "*.ps1" -Recurse

Write-Host "Correction terminÃ©e." -ForegroundColor Green
Write-Host "Tous les scripts de la roadmap ont Ã©tÃ© analysÃ©s et corrigÃ©s." -ForegroundColor Green
