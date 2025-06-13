# Script de Push GitHub avec Token
# Date: 8 juin 2025

# Configuration 
$projectPath = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$remoteUrl = "https://github.com/gerivdb/email-sender-1.git"
$branch = "manager/powershell-optimization"
$username = Read-Host -Prompt "Entrez votre nom d'utilisateur GitHub"
$token = Read-Host -Prompt "Entrez votre token GitHub (masqué)" -AsSecureString

# Conversion du token sécurisé en texte clair pour l'URL Git
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
$tokenPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host "`n=== PUSH GITHUB SÉCURISÉ ===" -ForegroundColor Cyan
Set-Location $projectPath

Write-Host "`n1. Vérification de la branche" -ForegroundColor Green
$currentBranch = git branch --show-current
Write-Host "Branche actuelle: $currentBranch"

Write-Host "`n2. Configuration du dépôt distant" -ForegroundColor Green
git remote set-url origin $remoteUrl
Write-Host "Remote configuré: $remoteUrl"

Write-Host "`n3. Push avec authentification sécurisée" -ForegroundColor Green
$authUrl = "https://${username}:${tokenPlain}@github.com/gerivdb/email-sender-1.git"
git push $authUrl $branch

if ($LASTEXITCODE -eq 0) {
   Write-Host "`n✅ SUCCÈS: Les changements ont été poussés vers GitHub!" -ForegroundColor Green
   "PUSH SUCCESS - $(Get-Date)" | Out-File -FilePath "GITHUB_FINAL_PUSH_SUCCESS.txt" -Encoding utf8
}
else {
   Write-Host "`n❌ ÉCHEC: Le push a échoué avec le code $LASTEXITCODE" -ForegroundColor Red
   Write-Host "`nTentative avec push forcé..." -ForegroundColor Yellow
   git push -f $authUrl $branch
    
   if ($LASTEXITCODE -eq 0) {
      Write-Host "`n✅ SUCCÈS avec push forcé!" -ForegroundColor Green
      "PUSH SUCCESS (FORCE) - $(Get-Date)" | Out-File -FilePath "GITHUB_FINAL_PUSH_SUCCESS_FORCE.txt" -Encoding utf8
   }
   else {
      Write-Host "`n❌ ÉCHEC FINAL: Le push forcé a également échoué." -ForegroundColor Red
      "PUSH FAILED FINAL - $(Get-Date)" | Out-File -FilePath "GITHUB_FINAL_PUSH_FAILED.txt" -Encoding utf8
   }
}

# Nettoyage de la variable token en mémoire
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
Remove-Variable -Name tokenPlain -ErrorAction SilentlyContinue

Write-Host "`n=== OPÉRATION TERMINÉE ===" -ForegroundColor Cyan
Write-Host "Vérifiez: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization" -ForegroundColor Yellow
Pause
