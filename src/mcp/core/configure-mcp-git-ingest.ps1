


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
    } catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
    # Script pour configurer le MCP Git Ingest dans n8n

    Write-Host "=== Configuration du MCP Git Ingest dans n8n ===" -ForegroundColor Cyan

    # Verifier si n8n est installe
    $n8nVersion = npx n8n --version 2>$null
    if (-not $n8nVersion) {
        Write-Host "âŒ n8n n'est pas installe ou n'est pas accessible via npx" -ForegroundColor Red
        Write-Host "Veuillez installer n8n ou verifier votre installation"
        exit 1
    }

    Write-Host "âœ… n8n version $n8nVersion detectee" -ForegroundColor Green

    # Verifier si le fichier batch existe
    $mcpGitIngestPath = "..\utils\commands\mcp-git-ingest.cmd"

    if (-not (Test-Path $mcpGitIngestPath)) {
        Write-Host "âŒ Le fichier $mcpGitIngestPath n'existe pas" -ForegroundColor Red
        exit 1
    }

    Write-Host "âœ… Fichier batch MCP Git Ingest trouve" -ForegroundColor Green

    # Definir les variables d'environnement
    [Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'User')
    [Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')

    Write-Host "âœ… Variables d'environnement definies" -ForegroundColor Green

    # Creer le repertoire .n8n s'il n'existe pas
    $n8nDir = ".\.n8n"
    if (-not (Test-Path $n8nDir)) {
        New-Item -ItemType Directory -Path $n8nDir | Out-Null
        Write-Host "âœ… Repertoire .n8n cree" -ForegroundColor Green
    } else {
        Write-Host "âœ… Repertoire .n8n existe deja" -ForegroundColor Green
    }

    # Creer le repertoire .n8n/credentials s'il n'existe pas
    $credentialsDir = "$n8nDir\credentials"
    if (-not (Test-Path $credentialsDir)) {
        New-Item -ItemType Directory -Path $credentialsDir | Out-Null
        Write-Host "âœ… Repertoire .n8n/credentials cree" -ForegroundColor Green
    } else {
        Write-Host "âœ… Repertoire .n8n/credentials existe deja" -ForegroundColor Green
    }

    # Generer un identifiant unique
    $mcpGitIngestId = [guid]::NewGuid().ToString("N")

    # Creer le fichier d'identifiants
    $mcpGitIngestCredPath = "$credentialsDir\$mcpGitIngestId.json"
    $mcpGitIngestCredContent = @"
{
  "name": "MCP Git Ingest",
  "type": "mcpClientApi",
  "data": {
    "command": "$(Resolve-Path $mcpGitIngestPath)",
    "args": "",
    "environments": "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
  }
}
"@

    Set-Content -Path $mcpGitIngestCredPath -Value $mcpGitIngestCredContent
    Write-Host "âœ… Fichier d'identifiants MCP Git Ingest cree" -ForegroundColor Green

    # Mettre a jour le fichier credentials.db
    $credentialsDbPath = "$n8nDir\credentials.db"
    if (Test-Path $credentialsDbPath) {
        $credentialsDb = Get-Content -Path $credentialsDbPath -Raw | ConvertFrom-Json -AsHashtable
        $credentialsDb[$mcpGitIngestId] = @{
            "name"        = "MCP Git Ingest"
            "type"        = "mcpClientApi"
            "nodesAccess" = @(
                @{
                    "nodeType" = "n8n-nodes-base.mcpClient"
                }
            )
        }
        $credentialsDbContent = $credentialsDb | ConvertTo-Json -Compress
        Set-Content -Path $credentialsDbPath -Value $credentialsDbContent
        Write-Host "âœ… Fichier credentials.db mis a jour" -ForegroundColor Green
    } else {
        $credentialsDbContent = @"
{"$mcpGitIngestId":{"name":"MCP Git Ingest","type":"mcpClientApi","nodesAccess":[{"nodeType":"n8n-nodes-base.mcpClient"}]}}
"@
        Set-Content -Path $credentialsDbPath -Value $credentialsDbContent
        Write-Host "âœ… Fichier credentials.db cree" -ForegroundColor Green
    }

    Write-Host "`n=== Configuration terminee ===" -ForegroundColor Cyan
    Write-Host "Le MCP Git Ingest a ete configure dans n8n."
    Write-Host "Redemarrez n8n pour appliquer les changements."
    Write-Host "Vous pouvez demarrer n8n en utilisant le script start-n8n.cmd ou en executant la commande npx n8n start."



} catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
} finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
