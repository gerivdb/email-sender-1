# Script pour configurer EMAIL_PASSWORD dans le fichier .env

# Vérifier si le fichier service-account-key.json existe
$keyFilePath = "$PSScriptRoot\service-account-key.json"
if (-not (Test-Path $keyFilePath)) {
    Write-Host "Erreur : Fichier service-account-key.json non trouvé dans $PSScriptRoot" -ForegroundColor Red
    Write-Host "Exécutez d'abord create-service-account.cmd pour créer le compte de service et la clé" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier service-account-key.json
$keyContent = Get-Content -Raw -Path $keyFilePath

# Chemin vers le fichier .env à la racine du projet
$envFilePath = "$PSScriptRoot\..\..\\.env"

# Vérifier si le fichier .env existe, sinon le créer
if (-not (Test-Path $envFilePath)) {
    Write-Host "Création du fichier .env..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $envFilePath | Out-Null
}

# Lire le contenu actuel du fichier .env
$envContent = Get-Content -Path $envFilePath -ErrorAction SilentlyContinue

# Vérifier si EMAIL_PASSWORD existe déjà dans le fichier .env
$emailPasswordExists = $envContent | Where-Object { $_ -match "^EMAIL_PASSWORD=" }

if ($emailPasswordExists) {
    # Remplacer la ligne existante
    Write-Host "Mise à jour de EMAIL_PASSWORD dans le fichier .env..." -ForegroundColor Yellow
    $newEnvContent = $envContent -replace "^EMAIL_PASSWORD=.*", "EMAIL_PASSWORD=$keyContent"
    Set-Content -Path $envFilePath -Value $newEnvContent
} else {
    # Ajouter la nouvelle ligne
    Write-Host "Ajout de EMAIL_PASSWORD dans le fichier .env..." -ForegroundColor Yellow
    Add-Content -Path $envFilePath -Value "`nEMAIL_PASSWORD=$keyContent"
}

Write-Host "Configuration terminée. EMAIL_PASSWORD a été configuré dans le fichier .env" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser cette variable dans vos workflows GitHub Actions" -ForegroundColor Green
