


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Script pour mettre Ã  jour les identifiants GCP MCP

# Utiliser les identifiants existants
Write-Host "Utilisation des identifiants existants..." -ForegroundColor Green

# Chemin vers le fichier d'identifiants existant
$existingCredentialsPath = "$PSScriptRoot\credentials.json"

if (Test-Path $existingCredentialsPath) {
    Write-Host "Fichier d'identifiants trouvÃ© : $existingCredentialsPath" -ForegroundColor Green

    # Lire le contenu du fichier credentials.json
    $credentials = Get-Content -Raw -Path $existingCredentialsPath | ConvertFrom-Json

    # CrÃ©er un fichier token.json avec les champs requis pour l'authentification GCP
    $token = @{
        type = "authorized_user"
        client_id = $credentials.installed.client_id
        client_secret = $credentials.installed.client_secret
        refresh_token = "1//035rUXRCN5agLCgYIARAAGAMSNwF-L9IrhzE3wiuEleEiGaum4xLSbv8ICIy3UzpndKa0hIqQ73DMrO6n3i8OfCNoxYi7D3qoypw"
    }

    $tokenJson = ConvertTo-Json $token
    Set-Content -Path "$PSScriptRoot\token.json" -Value $tokenJson -Encoding UTF8

    Write-Host "Fichier token.json crÃ©Ã© avec les champs requis" -ForegroundColor Green
    Write-Host "Configuration terminÃ©e. Vous pouvez maintenant tester le MCP GCP." -ForegroundColor Green
} else {
    Write-Host "Erreur : Fichier credentials.json non trouvÃ© dans $PSScriptRoot" -ForegroundColor Red
    exit 1
}

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
