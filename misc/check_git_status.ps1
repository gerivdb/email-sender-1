# Script pour vérifier le statut Git
Set-Location D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1
$status = git status
$status | Out-File -FilePath git_status.txt -Encoding utf8
Write-Host "Statut Git enregistré dans git_status.txt"
