#!/usr/bin/env pwsh

# Script de push avec le nouveau token GitHub - Version FINALE
# Date: 8 juin 2025

Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

Write-Host "=== PUSH GITHUB AVEC NOUVEAU TOKEN ===" -ForegroundColor Cyan
Write-Host "Cible: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization" -ForegroundColor Yellow

# Utilisation du nouveau token
$token = "email-sender-1-token"
$remote_url = "https://gerivdb:${token}@github.com/gerivdb/email-sender-1.git"

Write-Host "`n1. Vérification des branches..." -ForegroundColor Green
git branch
Write-Host "OK" -ForegroundColor Green

Write-Host "`n2. Suppression du remote existant..." -ForegroundColor Green
git remote remove origin 2>$null
Write-Host "OK" -ForegroundColor Green

Write-Host "`n3. Configuration du remote avec le nouveau token..." -ForegroundColor Green
git remote add origin $remote_url
git remote -v | ForEach-Object { $_ -replace $token, "***TOKEN***" }
Write-Host "OK" -ForegroundColor Green

Write-Host "`n4. Force push vers la branche manager/powershell-optimization..." -ForegroundColor Green
$output = $null
try {
   # Configuration pour éviter les prompts
   $env:GIT_TERMINAL_PROMPT = 0
   $output = git push -f origin HEAD:manager/powershell-optimization 2>&1
    
   if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ PUSH RÉUSSI!" -ForegroundColor Green
      "PUSH SUCCESS - $(Get-Date)" | Out-File -FilePath "FINAL_PUSH_SUCCESS.txt" -Encoding utf8
      Write-Host "La branche manager/powershell-optimization a été mise à jour avec succès." -ForegroundColor Green
      Write-Host "Vérifiez https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization" -ForegroundColor Cyan
   }
   else {
      Write-Host "❌ ÉCHEC DU PUSH: Code $LASTEXITCODE" -ForegroundColor Red
      "PUSH FAILED - $(Get-Date) - Exit Code: $LASTEXITCODE`nOutput: $output" | Out-File -FilePath "FINAL_PUSH_ERROR.txt" -Encoding utf8
      Write-Host "Erreur: $output" -ForegroundColor Red
   }
}
catch {
   Write-Host "❌ EXCEPTION: $_" -ForegroundColor Red
   "PUSH EXCEPTION - $(Get-Date)`nError: $_" | Out-File -FilePath "FINAL_PUSH_EXCEPTION.txt" -Encoding utf8
}

# Vérification finale
Write-Host "`n5. Statut final:" -ForegroundColor Green
git status
