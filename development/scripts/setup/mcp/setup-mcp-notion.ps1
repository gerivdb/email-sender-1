


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
# Script de configuration pour MCP Notion Server

# Definir les variables d'environnement necessaires
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

# Vous devrez entrer votre token d'integration Notion ici
$env:NOTION_API_TOKEN = "secret_..." # Remplacez par votre token d'integration Notion

# Verifier si @suekou/mcp-notion-server est installe
$mcpNotionInstalled = npm list @suekou/mcp-notion-server
if ($mcpNotionInstalled -match "@suekou/mcp-notion-server@") {
    Write-Host "@suekou/mcp-notion-server est deja installe."
} else {
    Write-Host "Installation de @suekou/mcp-notion-server..."
    npm install @suekou/mcp-notion-server
}

# Definir la variable d'environnement pour n8n de facon permanente
Write-Host "Configuration des variables d'environnement pour n8n..."
[System.Environment]::SetEnvironmentVariable("N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE", "true", "User")

# Mettre a jour le fichier .env pour n8n
$envPath = ".env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath
    if (-not ($envContent -match "NOTION_API_TOKEN")) {
        Add-Content -Path $envPath -Value "`nNOTION_API_TOKEN=$env:NOTION_API_TOKEN"
        Write-Host "Variable NOTION_API_TOKEN ajoutee au fichier .env"
    } else {
        Write-Host "Variable NOTION_API_TOKEN deja presente dans le fichier .env"
    }
} else {
    $envContent = @"
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
NOTION_API_TOKEN=$env:NOTION_API_TOKEN
"@
    Set-Content -Path $envPath -Value $envContent
    Write-Host "Fichier .env cree avec les variables necessaires"
}

Write-Host "Configuration MCP Notion Server terminee. Vous pouvez maintenant utiliser le MCP Notion Server dans n8n."
Write-Host "N'oubliez pas de configurer les identifiants MCP dans n8n avec les informations suivantes :"
Write-Host "- Type de connexion : Command Line (STDIO)"
Write-Host "- Commande : npx"
Write-Host "- Arguments : -y @suekou/mcp-notion-server"
Write-Host "- Variables d'environnement : NOTION_API_TOKEN=$env:NOTION_API_TOKEN,N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
Write-Host ""
Write-Host "Redemarrez n8n pour appliquer les changements."


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
