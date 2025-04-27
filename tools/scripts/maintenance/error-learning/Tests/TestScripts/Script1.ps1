# Script de test 1 avec plusieurs problÃ¨mes
$logPath = "D:\Logs\app1.log"
Write-Host "Log Path: $logPath"

# Absence de gestion d'erreurs
$content = Get-Content -Path "C:\config1.txt"
