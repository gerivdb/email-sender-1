# Script de test 2 avec plusieurs problèmes
$configPath = "C:\Program Files\App\config.xml"
Write-Host "Config Path: $configPath"

# Absence de gestion d'erreurs
$content = Get-Content -Path $configPath
