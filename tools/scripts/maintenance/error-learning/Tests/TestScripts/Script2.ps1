# Script de test 2 avec plusieurs problÃ¨mes
$configPath = "C:\Program Files\App\config.xml"
Write-Host "Config Path: $configPath"

# Absence de gestion d'erreurs
$content = Get-Content -Path $configPath
