


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
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal
# Script pour organiser les fichiers n8n
# Ce script organise les fichiers finaux indispensables au projet Email Sender

# CrÃƒÂ©ation des rÃƒÂ©pertoires s'ils n'existent pas
$directories = @("workflows", "credentials", "config", "mcp")
foreach ($dir in $directories) {
    if (-not (Test-Path -Path $dir)) {
        Write-Host "CrÃƒÂ©ation du rÃƒÂ©pertoire $dir..."
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Copie des fichiers de workflow
Write-Host "Copie des fichiers de workflow..."
Copy-Item -Path ".\src\workflows\EMAIL_SENDER_*.json" -Destination ".\workflows\" -Force

# Copie des fichiers de configuration MCP
Write-Host "Copie des fichiers de configuration MCP..."
Copy-Item -Path "..\manager\config\categories.json" -Destination ".\mcp\" -Force

# Copie des fichiers de credentials
Write-Host "Copie des fichiers de credentials..."
Copy-Item -Path "..\manager\config\categories.json" -Destination ".\credentials\" -Force

# Copie du fichier de configuration n8n
Write-Host "Copie du fichier de configuration n8n..."
Copy-Item -Path ".\.n8n\config" -Destination ".\projet\config\n8n-config.txt" -Force

Write-Host "Organisation des fichiers terminÃƒÂ©e avec succÃƒÂ¨s!"
Write-Host ""
Write-Host "Structure des rÃƒÂ©pertoires :"
Write-Host "- workflows/ : Contient les fichiers de workflow n8n"
Write-Host "- credentials/ : Contient les informations d'identification"
Write-Host "- projet/config/ : Contient les fichiers de configuration"
Write-Host "- mcp/ : Contient les configurations MCP"


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
