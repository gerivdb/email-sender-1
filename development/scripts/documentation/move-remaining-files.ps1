


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
# Script pour deplacer les fichiers restants

Write-Host "=== Deplacement des fichiers restants ===" -ForegroundColor Cyan

# Deplacer les fichiers de documentation
$docFiles = @(
    "CONFIGURATION_MCP_GATEWAY_N8N.md",
    "CONFIGURATION_MCP_MISE_A_JOUR.md",
    "GUIDE_INSTALLATION_COMPLET.md"
)

foreach ($file in $docFiles) {
    if (Test-Path ".\$file") {
        # Verifier si le dossier docs/guides existe
        if (-not (Test-Path ".\docs\guides")) {
            New-Item -ItemType Directory -Path ".\docs\guides" -Force | Out-Null
            Write-Host "Dossier docs/guides cree" -ForegroundColor Green
        }
        
        # Deplacer le fichier
        Move-Item -Path ".\$file" -Destination ".\docs\guides\$file" -Force
        Write-Host "Fichier $file deplace vers docs/guides" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve a la racine" -ForegroundColor Yellow
    }
}

# Deplacer les scripts de demarrage
$startScripts = @(
    "start-n8n.cmd",
    "start-n8n-complete.cmd",
    "start-n8n-mcp.cmd"
)

foreach ($file in $startScripts) {
    if (Test-Path ".\$file") {
        # Verifier si le dossier tools existe
        if (-not (Test-Path ".\development\tools")) {
            New-Item -ItemType Directory -Path ".\development\tools" -Force | Out-Null
            Write-Host "Dossier tools cree" -ForegroundColor Green
        }
        
        # Deplacer le fichier
        Move-Item -Path ".\$file" -Destination ".\development\tools\$file" -Force
        Write-Host "Fichier $file deplace vers tools" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve a la racine" -ForegroundColor Yellow
    }
}

# Deplacer les fichiers de configuration
$configFiles = @(
    "gateway.yaml"
)

foreach ($file in $configFiles) {
    if (Test-Path ".\$file") {
        # Verifier si le dossier src/mcp/config existe
        if (-not (Test-Path ".\src\mcp\config")) {
            New-Item -ItemType Directory -Path ".\src\mcp\config" -Force | Out-Null
            Write-Host "Dossier src/mcp/config cree" -ForegroundColor Green
        }
        
        # Deplacer le fichier
        Move-Item -Path ".\$file" -Destination ".\src\mcp\config\$file" -Force
        Write-Host "Fichier $file deplace vers src/mcp/config" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve a la racine" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Deplacement termine ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
