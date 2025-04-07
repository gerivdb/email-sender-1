# Script pour corriger automatiquement les problèmes dans les scripts de la roadmap
# Ce script utilise Fix-PSScriptAnalyzerIssues.ps1 pour corriger les problèmes courants

# Configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixerScriptPath = Join-Path -Path $scriptPath -ChildPath "Fix-PSScriptAnalyzerIssues.ps1"

# Vérifier si le script de correction existe
if (-not (Test-Path -Path $fixerScriptPath)) {
    Write-Host "Le script Fix-PSScriptAnalyzerIssues.ps1 n'existe pas: $fixerScriptPath" -ForegroundColor Red
    exit 1
}

# Exécuter le script de correction sur tous les scripts de la roadmap
Write-Host "Correction des problèmes dans les scripts de la roadmap..." -ForegroundColor Cyan
& $fixerScriptPath -Path $scriptPath -Include "*.ps1" -Recurse

Write-Host "Correction terminée." -ForegroundColor Green
Write-Host "Tous les scripts de la roadmap ont été analysés et corrigés." -ForegroundColor Green
