# Script pour mettre à jour les identifiants GCP MCP

# Utiliser les identifiants existants
Write-Host "Utilisation des identifiants existants..." -ForegroundColor Green

# Chemin vers le fichier d'identifiants existant
$existingCredentialsPath = "$PSScriptRoot\credentials.json"

if (Test-Path $existingCredentialsPath) {
    Write-Host "Fichier d'identifiants trouvé : $existingCredentialsPath" -ForegroundColor Green

    # Lire le contenu du fichier credentials.json
    $credentials = Get-Content -Raw -Path $existingCredentialsPath | ConvertFrom-Json

    # Créer un fichier token.json avec les champs requis pour l'authentification GCP
    $token = @{
        type = "authorized_user"
        client_id = $credentials.installed.client_id
        client_secret = $credentials.installed.client_secret
        refresh_token = "1//035rUXRCN5agLCgYIARAAGAMSNwF-L9IrhzE3wiuEleEiGaum4xLSbv8ICIy3UzpndKa0hIqQ73DMrO6n3i8OfCNoxYi7D3qoypw"
    }

    $tokenJson = ConvertTo-Json $token
    Set-Content -Path "$PSScriptRoot\token.json" -Value $tokenJson -Encoding UTF8

    Write-Host "Fichier token.json créé avec les champs requis" -ForegroundColor Green
    Write-Host "Configuration terminée. Vous pouvez maintenant tester le MCP GCP." -ForegroundColor Green
} else {
    Write-Host "Erreur : Fichier credentials.json non trouvé dans $PSScriptRoot" -ForegroundColor Red
    exit 1
}
