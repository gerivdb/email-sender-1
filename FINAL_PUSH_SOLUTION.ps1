# Solution de push pour GitHub
# Date: 8 juin 2025

$ErrorActionPreference = "Stop"

Write-Host "=== PUSH VERS GITHUB - CORRECTION FINALE ===" -ForegroundColor Cyan
Write-Host "Cible: branche manager/powershell-optimization" -ForegroundColor Yellow

# Changement de répertoire
Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Assurer que nous sommes sur la bonne branche
$currentBranch = git branch --show-current
if ($currentBranch -ne "manager/powershell-optimization") {
   Write-Host "❌ Erreur: Vous n'êtes pas sur la branche manager/powershell-optimization!" -ForegroundColor Red
   Write-Host "   Branche actuelle: $currentBranch" -ForegroundColor Red
   Exit 1
}

# Configuration du remote
$repoUrl = "https://github.com/gerivdb/email-sender-1.git"
Write-Host "`n1. Configuration du remote pour GitHub..." -ForegroundColor Green
git remote set-url origin $repoUrl 2>$null
if (-not $?) {
   Write-Host "   Ajout du remote origin..." -ForegroundColor Yellow
   git remote add origin $repoUrl
}

Write-Host "`n2. Vérification du remote..." -ForegroundColor Green
git remote -v
Write-Host "OK" -ForegroundColor Green

# Push vers GitHub
Write-Host "`n3. Push vers la branche manager/powershell-optimization..." -ForegroundColor Green
try {
   # Utilisation du push standard
   git push origin manager/powershell-optimization
    
   if ($LASTEXITCODE -eq 0) {
      Write-Host "`n✅ SUCCÈS: Push réussi vers manager/powershell-optimization!" -ForegroundColor Green
      "PUSH SUCCESS - $(Get-Date)" | Out-File -FilePath "GITHUB_PUSH_SUCCESS.txt" -Encoding utf8
      Write-Host "Vérifiez: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization" -ForegroundColor Cyan
   }
   else {
      Write-Host "`n❌ ÉCHEC: Code de sortie $LASTEXITCODE" -ForegroundColor Red
      Write-Host "`nEssai avec le push forcé..." -ForegroundColor Yellow
        
      # Essai avec force push
      git push -f origin manager/powershell-optimization
        
      if ($LASTEXITCODE -eq 0) {
         Write-Host "`n✅ SUCCÈS AVEC FORCE PUSH!" -ForegroundColor Green
         "PUSH SUCCESS (FORCE) - $(Get-Date)" | Out-File -FilePath "GITHUB_PUSH_SUCCESS_FORCE.txt" -Encoding utf8
      }
      else {
         Write-Host "`n❌ ÉCHEC MÊME AVEC FORCE PUSH: Code $LASTEXITCODE" -ForegroundColor Red
         "PUSH FAILED - $(Get-Date)" | Out-File -FilePath "GITHUB_PUSH_ERROR.txt" -Encoding utf8
      }
   }
}
catch {
   Write-Host "`n❌ ERREUR: $_" -ForegroundColor Red
   "PUSH ERROR - $(Get-Date) - $_" | Out-File -FilePath "GITHUB_PUSH_EXCEPTION.txt" -Encoding utf8
}

Write-Host "`n=== OPÉRATION TERMINÉE ===" -ForegroundColor Cyan
