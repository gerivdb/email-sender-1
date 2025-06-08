# Script de vérification Git
Write-Host "=== VÉRIFICATION DU STATUT GIT ===" -ForegroundColor Cyan
Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

Write-Host "`nCurrent branch:" -ForegroundColor Yellow
git branch --show-current

Write-Host "`nStatus:" -ForegroundColor Yellow
git status

Write-Host "`nRemote repositories:" -ForegroundColor Yellow
git remote -v

Write-Host "`nLast commit:" -ForegroundColor Yellow
git log -1 --oneline

Write-Host "`n=== FIN DE LA VÉRIFICATION ===" -ForegroundColor Cyan
Pause
