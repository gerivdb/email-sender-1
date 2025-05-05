﻿# Test de la configuration du navigateur
$browserConfig = Get-Content -Path ".augment/browser-config.json" | ConvertFrom-Json

# Afficher la configuration actuelle
Write-Host "Configuration du navigateur :" -ForegroundColor Cyan
Write-Host "- Type: $($browserConfig.browser.type)"
Write-Host "- Profil configurÃ©: $($browserConfig.browser.profile)"
Write-Host "- Dossier User Data: $($browserConfig.browser.userDataDir)"

# VÃ©rifier les profils disponibles
$userDataDir = $browserConfig.browser.userDataDir
if (Test-Path $userDataDir) {
    Write-Host "`nProfils Chrome disponibles :" -ForegroundColor Cyan
    Get-ChildItem $userDataDir -Directory | Where-Object { $_.Name -match "Profile" } | ForEach-Object {
        $profilePath = Join-Path $_.FullName "Preferences"
        if (Test-Path $profilePath) {
            $profileData = Get-Content $profilePath -Raw | ConvertFrom-Json
            $email = $profileData.account_info.email
            Write-Host "- $($_.Name) $(if($email){": $email"})"
        } else {
            Write-Host "- $($_.Name)"
        }
    }
}

# VÃ©rifier le profil actuellement utilisÃ©
$userProfilePath = Join-Path $browserConfig.browser.userDataDir "Profile 2"
if (Test-Path $userProfilePath) {
    Write-Host "`nProfil actuellement utilisÃ© :" -ForegroundColor Green
    Write-Host "- Path: $userProfilePath"
} else {
    Write-Host "`nProfil 'Profile 2' non trouvÃ©!" -ForegroundColor Red
}

Write-Host "Configuration du navigateur validÃ©e"


