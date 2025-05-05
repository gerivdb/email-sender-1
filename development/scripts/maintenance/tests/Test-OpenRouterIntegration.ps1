<#
.SYNOPSIS
    Teste l'intÃ©gration avec OpenRouter pour le mode GRAN.

.DESCRIPTION
    Ce script teste l'intÃ©gration avec OpenRouter pour le mode GRAN.
    Il utilise la clÃ© API OpenRouter enregistrÃ©e pour gÃ©nÃ©rer des sous-tÃ¢ches.

.NOTES
    Auteur: Security Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
#>

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Initialiser la clÃ© API OpenRouter
$apiKey = "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"
$model = "qwen/qwen3-32b:free"

# DÃ©finir la variable d'environnement
[Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $apiKey, "Process")
Write-Host "ClÃ© API OpenRouter dÃ©finie pour cette session." -ForegroundColor Green

# Charger la fonction Get-AIGeneratedSubTasks depuis le script gran-mode.ps1
$granModePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "modes\gran-mode.ps1"

# Extraire la fonction Get-AIGeneratedSubTasks du script
$content = Get-Content -Path $granModePath -Raw
$functionMatch = [regex]::Match($content, '(?s)function Get-AIGeneratedSubTasks\s*\{.*?\n\}')

if (-not $functionMatch.Success) {
    Write-Error "La fonction Get-AIGeneratedSubTasks n'a pas Ã©tÃ© trouvÃ©e dans le fichier gran-mode.ps1"
    exit 1
}

# Ã‰valuer la fonction pour la rendre disponible dans ce script
$functionCode = $functionMatch.Value
Invoke-Expression $functionCode

# DÃ©finir la variable de script pour le modÃ¨le
$Script:AIModel = $model

# Tester la fonction avec OpenRouter
Write-Host "Test de la gÃ©nÃ©ration de sous-tÃ¢ches avec OpenRouter..." -ForegroundColor Yellow
Write-Host "ModÃ¨le : $model" -ForegroundColor Yellow

$result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -Domains @("Backend", "Security") -MaxSubTasks 5 -ProjectRoot $projectRoot

# Afficher le rÃ©sultat
if ($result) {
    Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es avec succÃ¨s !" -ForegroundColor Green
    Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es :"
    Write-Host "--------------------"
    Write-Host $result.Content
    Write-Host "--------------------"
    Write-Host "Domaine principal : $($result.Domain)"
    Write-Host "Domaines : $($result.Domains -join ", ")"
    Write-Host "Description : $($result.Description)"
} else {
    Write-Host "Impossible de gÃ©nÃ©rer des sous-tÃ¢ches avec OpenRouter." -ForegroundColor Red
    Write-Host "Essayons avec la simulation..." -ForegroundColor Yellow
    
    $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -Domains @("Backend", "Security") -MaxSubTasks 5 -ProjectRoot $projectRoot -Simulate
    
    if ($result) {
        Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es avec succÃ¨s (simulation) !" -ForegroundColor Green
        Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es :"
        Write-Host "--------------------"
        Write-Host $result.Content
        Write-Host "--------------------"
        Write-Host "Domaine principal : $($result.Domain)"
        Write-Host "Domaines : $($result.Domains -join ", ")"
        Write-Host "Description : $($result.Description)"
    } else {
        Write-Host "Impossible de gÃ©nÃ©rer des sous-tÃ¢ches, mÃªme avec la simulation." -ForegroundColor Red
    }
}
