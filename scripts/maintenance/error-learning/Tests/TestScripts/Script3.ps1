# Script de test 3 avec plusieurs problèmes
$dataPath = "D:\Data\output.csv"
Write-Host "Data Path: $dataPath"

# Absence de gestion d'erreurs
$content = Get-Content -Path $dataPath
