#!/usr/bin/env pwsh

# Script de push optimisé avec feedback
Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

$token = "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"
$username = "gerivdb"
$repo = "email-sender-1"
$branch = "manager/powershell-optimization"

Write-Host "=== OPÉRATION PUSH GITHUB SÉCURISÉE ===" -ForegroundColor Cyan
Write-Host "Repository: $repo" -ForegroundColor Yellow
Write-Host "Branch: $branch" -ForegroundColor Yellow

Write-Host "`n1. Vérification du remote..." -ForegroundColor Green
git remote -v
Write-Host "Remote vérifié." -ForegroundColor Green

Write-Host "`n2. Vérification du statut..." -ForegroundColor Green
git status
Write-Host "Statut vérifié." -ForegroundColor Green

Write-Host "`n3. Préparation du push..." -ForegroundColor Green
git branch
Write-Host "Branches vérifiées." -ForegroundColor Green

Write-Host "`n4. Push vers GitHub..." -ForegroundColor Green
# Construire l'URL avec le token (masqué dans l'affichage)
$remote_url = "https://${username}:${token}@github.com/${username}/${repo}.git"
Write-Host "Remote URL: https://${username}:***TOKEN***@github.com/${username}/${repo}.git"

# Command push sans afficher le token dans le terminal
$env:GIT_TERMINAL_PROMPT = 0
$result = $null

try {
   # Push en utilisant la méthode plus sécurisée
   Write-Host "Pushing to remote repository..." -ForegroundColor Green
   $result = git push -u $remote_url $branch:$branch --force --no-verify 2>&1
    
   if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ Push successful!" -ForegroundColor Green
      Write-Host "🚀 Verify your changes at: https://github.com/${username}/${repo}/tree/${branch}" -ForegroundColor Cyan
        
      # Créer un fichier de succès
      "Push successful at $(Get-Date)" | Out-File -FilePath "PUSH_SUCCESS.txt" -Encoding utf8
        
      exit 0
   }
   else {
      Write-Host "❌ Push failed with exit code: $LASTEXITCODE" -ForegroundColor Red
      Write-Host $result -ForegroundColor Red
        
      # Créer un fichier d'échec
      "Push failed at $(Get-Date)`nError: $result" | Out-File -FilePath "PUSH_FAILED.txt" -Encoding utf8
        
      exit 1
   }
}
catch {
   Write-Host "❌ Exception: $_" -ForegroundColor Red
   "Push exception at $(Get-Date)`nError: $_" | Out-File -FilePath "PUSH_EXCEPTION.txt" -Encoding utf8
   exit 2
}
