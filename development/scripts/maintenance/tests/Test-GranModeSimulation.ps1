# Charger la fonction Get-AIGeneratedSubTasks depuis le script gran-mode.ps1
$granModePath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\modes\gran-mode.ps1"

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

# Tester la fonction avec la simulation activée
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -Domains @("Backend", "Security") -MaxSubTasks 5 -ProjectRoot $projectRoot -Simulate

# Afficher le résultat
if ($result) {
    Write-Host "Sous-tâches générées :"
    Write-Host "--------------------"
    Write-Host $result.Content
    Write-Host "--------------------"
    Write-Host "Domaine principal : $($result.Domain)"
    Write-Host "Domaines : $($result.Domains -join ", ")"
    Write-Host "Description : $($result.Description)"
} else {
    Write-Host "Impossible de générer des sous-tâches avec l'IA."
}
