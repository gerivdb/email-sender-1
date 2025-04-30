<#
.SYNOPSIS
    Teste l'intégration avec OpenRouter pour le mode GRAN.

.DESCRIPTION
    Ce script teste l'intégration avec OpenRouter pour le mode GRAN.
    Il utilise la clé API OpenRouter enregistrée pour générer des sous-tâches.

.NOTES
    Auteur: Security Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Initialiser la clé API OpenRouter
$apiKey = "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"
$model = "qwen/qwen3-32b:free"

# Définir la variable d'environnement
[Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $apiKey, "Process")
Write-Host "Clé API OpenRouter définie pour cette session." -ForegroundColor Green

# Charger la fonction Get-AIGeneratedSubTasks depuis le script gran-mode.ps1
$granModePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "modes\gran-mode.ps1"

# Extraire la fonction Get-AIGeneratedSubTasks du script
$content = Get-Content -Path $granModePath -Raw
$functionMatch = [regex]::Match($content, '(?s)function Get-AIGeneratedSubTasks\s*\{.*?\n\}')

if (-not $functionMatch.Success) {
    Write-Error "La fonction Get-AIGeneratedSubTasks n'a pas été trouvée dans le fichier gran-mode.ps1"
    exit 1
}

# Évaluer la fonction pour la rendre disponible dans ce script
$functionCode = $functionMatch.Value
Invoke-Expression $functionCode

# Définir la variable de script pour le modèle
$Script:AIModel = $model

# Tester la fonction avec OpenRouter
Write-Host "Test de la génération de sous-tâches avec OpenRouter..." -ForegroundColor Yellow
Write-Host "Modèle : $model" -ForegroundColor Yellow

$result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -Domains @("Backend", "Security") -MaxSubTasks 5 -ProjectRoot $projectRoot

# Afficher le résultat
if ($result) {
    Write-Host "Sous-tâches générées avec succès !" -ForegroundColor Green
    Write-Host "Sous-tâches générées :"
    Write-Host "--------------------"
    Write-Host $result.Content
    Write-Host "--------------------"
    Write-Host "Domaine principal : $($result.Domain)"
    Write-Host "Domaines : $($result.Domains -join ", ")"
    Write-Host "Description : $($result.Description)"
} else {
    Write-Host "Impossible de générer des sous-tâches avec OpenRouter." -ForegroundColor Red
    Write-Host "Essayons avec la simulation..." -ForegroundColor Yellow
    
    $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -Domains @("Backend", "Security") -MaxSubTasks 5 -ProjectRoot $projectRoot -Simulate
    
    if ($result) {
        Write-Host "Sous-tâches générées avec succès (simulation) !" -ForegroundColor Green
        Write-Host "Sous-tâches générées :"
        Write-Host "--------------------"
        Write-Host $result.Content
        Write-Host "--------------------"
        Write-Host "Domaine principal : $($result.Domain)"
        Write-Host "Domaines : $($result.Domains -join ", ")"
        Write-Host "Description : $($result.Description)"
    } else {
        Write-Host "Impossible de générer des sous-tâches, même avec la simulation." -ForegroundColor Red
    }
}
