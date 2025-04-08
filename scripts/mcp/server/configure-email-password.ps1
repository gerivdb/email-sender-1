# Script pour configurer EMAIL_PASSWORD dans le fichier .env

# VÃ©rifier si le fichier service-account-key.json existe
$keyFilePath = "$PSScriptRoot\service-account-key.json"
if (-not (Test-Path $keyFilePath)) {
    Write-Host "Erreur : Fichier service-account-key.json non trouvÃ© dans $PSScriptRoot" -ForegroundColor Red
    Write-Host "ExÃ©cutez d'abord create-service-account.cmd pour crÃ©er le compte de service et la clÃ©" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier service-account-key.json
$keyContent = Get-Content -Raw -Path $keyFilePath

# Chemin vers le fichier .env Ã  la racine du projet
$envFilePath = "$PSScriptRoot\..\..\\.env"

# VÃ©rifier si le fichier .env existe, sinon le crÃ©er
if (-not (Test-Path $envFilePath)) {
    Write-Host "CrÃ©ation du fichier .env..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $envFilePath | Out-Null
}

# Lire le contenu actuel du fichier .env
$envContent = Get-Content -Path $envFilePath -ErrorAction SilentlyContinue

# VÃ©rifier si EMAIL_PASSWORD existe dÃ©jÃ  dans le fichier .env
$emailPasswordExists = $envContent | Where-Object { $_ -match "^EMAIL_PASSWORD=" }

if ($emailPasswordExists) {
    # Remplacer la ligne existante
    Write-Host "Mise Ã  jour de EMAIL_PASSWORD dans le fichier .env..." -ForegroundColor Yellow
    $newEnvContent = $envContent -replace "^EMAIL_PASSWORD=.*", "EMAIL_PASSWORD=$keyContent"
    Set-Content -Path $envFilePath -Value $newEnvContent
} else {
    # Ajouter la nouvelle ligne
    Write-Host "Ajout de EMAIL_PASSWORD dans le fichier .env..." -ForegroundColor Yellow
    Add-Content -Path $envFilePath -Value "`nEMAIL_PASSWORD=$keyContent"
}

Write-Host "Configuration terminÃ©e. EMAIL_PASSWORD a Ã©tÃ© configurÃ© dans le fichier .env" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser cette variable dans vos workflows GitHub Actions" -ForegroundColor Green
